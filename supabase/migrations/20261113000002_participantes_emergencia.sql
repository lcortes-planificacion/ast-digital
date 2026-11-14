-- =====================================================================
--  AST DIGITAL 3.2 · MIGRACIÓN 002
--  Participantes después de la firma · «Otros» · acceso de emergencia
--  Requiere haber corrido antes la migración 001 (seguridad y RLS).
--  Se puede ejecutar más de una vez sin duplicar nada.
-- =====================================================================
begin;

do $$ begin
  if to_regclass('public.ast_perfiles') is null then
    raise exception 'Falta la migración 001: córrela primero.';
  end if;
end $$;

-- Respaldo de participantes antes de agregar columnas
do $$
declare s text := to_char(now() at time zone 'America/Santiago','YYYYMMDD_HH24MISS');
begin
  execute format('create table if not exists respaldo.%I as table public.ast_participantes','ast_participantes_'||s||'_m002');
end $$;

-- ---------------------------------------------------------------------
-- 1. PARTICIPANTES: también después de la firma, con trazabilidad
-- ---------------------------------------------------------------------
alter table public.ast_participantes
  add column if not exists declaracion_aceptada boolean,
  add column if not exists post_firma boolean not null default false,
  add column if not exists registrado_por text,
  add column if not exists dispositivo text,
  add column if not exists registrado_en timestamptz default now();

create or replace function public.ast_participantes_alta() returns trigger language plpgsql security definer set search_path=public
as $$
declare r public.ast_registros; rutn text;
begin
  select * into r from public.ast_registros where id::text = new.ast_id::text;
  if not found then raise exception 'La AST no existe.' using errcode = '42501'; end if;
  if r.estado not in ('borrador','pendiente','firmada') then
    raise exception 'La AST ya terminó su vigencia: no se pueden agregar participantes.' using errcode = '42501';
  end if;
  if coalesce(trim(new.nombre),'') = '' then raise exception 'Falta el nombre del participante.'; end if;
  if coalesce(new.firma,'') = '' then raise exception 'Falta la firma del participante.'; end if;
  -- todas las versiones de la app exigen marcar la declaración antes de enviar
  new.declaracion_aceptada := coalesce(new.declaracion_aceptada, true);
  if not new.declaracion_aceptada then raise exception 'El participante debe aceptar la declaración.'; end if;
  rutn := upper(regexp_replace(coalesce(new.rut,''),'[^0-9kK]','','g'));
  if rutn <> '' and exists (select 1 from public.ast_participantes p where p.ast_id::text = new.ast_id::text
       and upper(regexp_replace(coalesce(p.rut,''),'[^0-9kK]','','g')) = rutn) then
    raise exception 'Esa persona ya está registrada en esta AST.';
  end if;
  new.post_firma := r.sup_firma is not null;
  new.registrado_en := now();
  new.dispositivo := public.ast_dispositivo();
  new.registrado_por := public.ast_quien()->>'nombre';
  return new;
end $$;
drop trigger if exists ast_participantes_alta on public.ast_participantes;
create trigger ast_participantes_alta before insert on public.ast_participantes
  for each row execute function public.ast_participantes_alta();

create or replace function public.ast_participantes_auditar() returns trigger language plpgsql security definer set search_path=public
as $$
declare n text;
begin
  select coalesce('N° '||c.numero||case when c.rev>0 then ' Rev.'||c.rev else '' end, new.ast_id::text) into n
  from (select 1) x left join public.ast_correlativos c on c.ast_id = new.ast_id::text;
  perform public.ast_anotar(case when new.post_firma then 'Agregó un participante después de la firma' else 'Registró un participante' end,
    new.nombre||coalesce(' · '||nullif(new.rut,''),'')||' · AST '||coalesce(n,''));
  return null;
end $$;
drop trigger if exists ast_participantes_auditar on public.ast_participantes;
create trigger ast_participantes_auditar after insert on public.ast_participantes
  for each row execute function public.ast_participantes_auditar();

-- ---------------------------------------------------------------------
-- 2. «OTROS»: una AST dirigida a un nombre escrito (sin cuenta)
--    No se asocia a ninguna cuenta. La puede firmar cualquier responsable
--    con permiso de firma; queda registrada la cuenta real que firmó.
--    (La regla ya existe en la migración 001: supId vacío = sin asignar.)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 3. ACCESO DE EMERGENCIA DEL ADMINISTRADOR
--    La clave se guarda cifrada (bcrypt) en una tabla sin acceso desde la API.
--    No viaja en la app. Cada intento queda registrado y hay bloqueo por intentos.
-- ---------------------------------------------------------------------
create table if not exists public.ast_emergencia(
  id int primary key default 1 check (id = 1),
  hash text not null,
  actualizado timestamptz not null default now()
);
create table if not exists public.ast_emergencia_intentos(
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  dispositivo text, usuario text, ok boolean not null
);
alter table public.ast_emergencia enable row level security;
alter table public.ast_emergencia_intentos enable row level security;
revoke all on public.ast_emergencia, public.ast_emergencia_intentos from anon, authenticated;

insert into public.ast_emergencia(id, hash)
values (1, extensions.crypt('__CLAVE_EMERGENCIA__', extensions.gen_salt('bf', 10)))
on conflict (id) do nothing;

-- Devuelve {ok, error, creado}. No usa «raise» en los rechazos para que el intento quede guardado.
create or replace function public.ast_emergencia(p_clave text, p_usuario text, p_nombre text, p_apellido text, p_nueva text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare h text; disp text := public.ast_dispositivo(); fall_tot int; fall_disp int; u public.ast_perfiles; uid uuid; creado boolean := false;
begin
  p_usuario := lower(trim(coalesce(p_usuario,'')));
  select count(*) into fall_tot from public.ast_emergencia_intentos where not ok and ts > now() - interval '15 minutes';
  select count(*) into fall_disp from public.ast_emergencia_intentos where not ok and ts > now() - interval '15 minutes' and dispositivo is not distinct from disp;
  if fall_tot >= 6 or fall_disp >= 3 then
    insert into public.ast_emergencia_intentos(dispositivo, usuario, ok) values (disp, p_usuario, false);
    perform public.ast_anotar('Acceso de emergencia bloqueado por demasiados intentos', p_usuario);
    return jsonb_build_object('ok', false, 'error', 'Demasiados intentos fallidos. Espera 15 minutos.');
  end if;
  select hash into h from public.ast_emergencia where id = 1;
  if h is null or extensions.crypt(coalesce(p_clave,''), h) <> h then
    perform pg_sleep(1.2);
    insert into public.ast_emergencia_intentos(dispositivo, usuario, ok) values (disp, p_usuario, false);
    perform public.ast_anotar('Intento fallido de acceso de emergencia', p_usuario);
    return jsonb_build_object('ok', false, 'error', 'Clave de emergencia incorrecta.');
  end if;
  if p_usuario !~ '^[a-z0-9._-]{3,30}$' then return jsonb_build_object('ok', false, 'error', 'Usuario no válido.'); end if;
  if length(coalesce(p_nueva,'')) < 8 or p_nueva !~ '[A-Za-z]' or p_nueva !~ '[0-9]' then
    return jsonb_build_object('ok', false, 'error', 'La contraseña debe tener al menos 8 caracteres, con letras y números.');
  end if;
  select * into u from public.ast_perfiles where usuario = p_usuario;
  if found then
    if u.rol <> 'admin' then
      insert into public.ast_emergencia_intentos(dispositivo, usuario, ok) values (disp, p_usuario, false);
      perform public.ast_anotar('Acceso de emergencia rechazado: la cuenta no es de administrador', p_usuario);
      return jsonb_build_object('ok', false, 'error', 'Esa cuenta no es de administrador. Usa tu usuario de administrador o uno nuevo.');
    end if;
    update auth.users set encrypted_password = extensions.crypt(p_nueva, extensions.gen_salt('bf', 10)), banned_until = null, updated_at = now() where id = u.id;
    update public.ast_perfiles set activo = true, cambiar_clave = false, modificado = now() where id = u.id;
    uid := u.id;
  else
    if coalesce(trim(p_nombre),'') = '' then return jsonb_build_object('ok', false, 'error', 'Esa cuenta no existe: escribe nombre y apellido para crearla.'); end if;
    uid := public.ast_crear_cuenta(p_usuario, p_nombre, coalesce(p_apellido,''), '', 'Administrador', 'admin', p_nueva, 100, 'acceso de emergencia');
    update public.ast_perfiles set cambiar_clave = false where id = uid;
    creado := true;
  end if;
  insert into public.ast_emergencia_intentos(dispositivo, usuario, ok) values (disp, p_usuario, true);
  insert into public.ast_accesos(usuario_id, usuario, nombre, rol, dispositivo, accion, detalle)
  values (uid, p_usuario, (select trim(nombre||' '||apellido) from public.ast_perfiles where id = uid), 'admin', disp,
          'Acceso de emergencia del administrador', case when creado then 'creó la cuenta' else 'restableció la contraseña' end);
  return jsonb_build_object('ok', true, 'creado', creado);
end $$;
grant execute on function public.ast_emergencia(text,text,text,text,text) to anon, authenticated;

-- Cambiar la clave de emergencia (solo administración)
create or replace function public.ast_cambiar_clave_emergencia(p_actual text, p_nueva text) returns jsonb
language plpgsql security definer set search_path=public
as $$
declare h text;
begin
  perform public.ast_exigir('usuarios', 5);
  select hash into h from public.ast_emergencia where id = 1;
  if extensions.crypt(coalesce(p_actual,''), h) <> h then
    perform public.ast_anotar('Intento fallido de cambiar la clave de emergencia','');
    return jsonb_build_object('ok', false, 'error', 'La clave de emergencia actual no es correcta.');
  end if;
  if length(coalesce(p_nueva,'')) < 10 then return jsonb_build_object('ok', false, 'error', 'La nueva clave debe tener al menos 10 caracteres.'); end if;
  update public.ast_emergencia set hash = extensions.crypt(p_nueva, extensions.gen_salt('bf', 10)), actualizado = now() where id = 1;
  perform public.ast_anotar('Cambió la clave de emergencia','');
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ast_cambiar_clave_emergencia(text,text) to authenticated;

-- La clave antigua guardada en la configuración general (visible para todos) se elimina
update public.ast_config set datos = datos #- '{gen,CLAVE_ADMIN}' #- '{gen,PIN_MAESTRO}'
where id = 'main' and (datos->'gen' ? 'CLAVE_ADMIN' or datos->'gen' ? 'PIN_MAESTRO');

commit;

select 'Migración 002 lista' as resultado,
  (select count(*) from information_schema.columns where table_name='ast_participantes' and column_name in ('post_firma','registrado_por','registrado_en','declaracion_aceptada','dispositivo')) as columnas_nuevas,
  (select count(*) from public.ast_emergencia) as clave_emergencia_configurada;
