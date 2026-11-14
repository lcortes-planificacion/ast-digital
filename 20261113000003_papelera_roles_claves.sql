-- =====================================================================
--  AST DIGITAL 3.3 · MIGRACIÓN 003
--  Papelera de AST · perfiles Planificador y Visitante · motivo de
--  incorporación · claves temporales con fecha de vencimiento ·
--  lecturas más rápidas
--  Requiere haber corrido antes las migraciones 001 y 002.
--  Se puede ejecutar más de una vez sin duplicar nada. No borra datos.
-- =====================================================================
begin;

do $$ begin
  if to_regclass('public.ast_emergencia') is null then
    raise exception 'Falta la migración 002: córrela primero.';
  end if;
end $$;

-- Respaldo de las tablas que se modifican
do $$
declare s text := to_char(now() at time zone 'America/Santiago','YYYYMMDD_HH24MISS');
begin
  execute format('create table if not exists respaldo.%I as table public.ast_perfiles','ast_perfiles_'||s||'_m003');
  execute format('create table if not exists respaldo.%I as table public.ast_participantes','ast_participantes_'||s||'_m003');
end $$;

-- ---------------------------------------------------------------------
-- 1. PERFILES: se agregan Planificador y Visitante
--    (Usuario estándar = personal de taller)
-- ---------------------------------------------------------------------
alter table public.ast_perfiles drop constraint if exists ast_perfiles_rol_check;
alter table public.ast_perfiles add constraint ast_perfiles_rol_check
  check (rol in ('admin','gerencia','supervisor','planificador','calidad','prevencion','admin_taller','taller','visitante'));

-- Niveles: 0 sin acceso · 1 solo lectura · 2 crear · 3 editar · 4 firmar · 5 administrar
create or replace function public.ast_nivel_base(p_rol text, p_mod text) returns int language sql immutable
as $$
  select coalesce((case p_rol
    when 'admin'        then '{"ast_dia":5,"firmas":5,"historico":5,"dashboard":5,"revision":5,"auditoria":5,"dispositivos":5,"usuarios":5,"configuracion":5,"papelera":5}'
    when 'gerencia'     then '{"ast_dia":1,"firmas":4,"historico":3,"dashboard":1,"revision":1,"auditoria":1}'
    when 'supervisor'   then '{"ast_dia":3,"firmas":4,"historico":3,"dashboard":1,"revision":1}'
    when 'planificador' then '{"ast_dia":1,"firmas":1,"historico":1,"dashboard":1,"revision":1}'
    when 'calidad'      then '{"ast_dia":1,"firmas":4,"historico":1,"dashboard":1,"revision":1}'
    when 'prevencion'   then '{"ast_dia":1,"firmas":4,"historico":3,"dashboard":1,"revision":1,"auditoria":1}'
    when 'admin_taller' then '{"ast_dia":3,"firmas":1,"historico":1,"dashboard":1,"revision":1,"auditoria":1,"dispositivos":3}'
    when 'taller'       then '{"ast_dia":2,"firmas":1}'
    when 'visitante'    then '{"ast_dia":1,"historico":1,"dashboard":1}'
    else '{}' end)::jsonb->>p_mod, '0')::int
$$;

create or replace function public.ast_rol_nombre(r text) returns text language sql immutable
as $$ select case r when 'admin' then 'Administrador' when 'gerencia' then 'Gerencia' when 'supervisor' then 'Supervisor'
  when 'planificador' then 'Planificador' when 'calidad' then 'Calidad' when 'prevencion' then 'Prevención de Riesgos'
  when 'admin_taller' then 'Administrador de taller' when 'taller' then 'Usuario estándar (taller)' when 'visitante' then 'Visitante'
  else r end $$;

-- ---------------------------------------------------------------------
-- 2. CLAVES TEMPORALES: fecha de creación y vencimiento (7 días)
-- ---------------------------------------------------------------------
alter table public.ast_perfiles
  add column if not exists clave_temporal_en timestamptz,
  add column if not exists clave_temporal_vence timestamptz;

create or replace function public.ast_dias_clave_temporal() returns int language sql immutable as $$ select 7 $$;

-- Las claves temporales que ya existen parten hoy, para que nadie quede fuera de golpe
update public.ast_perfiles set clave_temporal_en = now(), clave_temporal_vence = now() + make_interval(days => public.ast_dias_clave_temporal())
where cambiar_clave and clave_temporal_en is null;

create or replace function public.ast_perfiles_clave() returns trigger language plpgsql set search_path=public
as $$
begin
  if new.cambiar_clave and (tg_op = 'INSERT' or not coalesce(old.cambiar_clave,false)) then
    new.clave_temporal_en := coalesce(new.clave_temporal_en, now());
    new.clave_temporal_vence := coalesce(new.clave_temporal_vence, now() + make_interval(days => public.ast_dias_clave_temporal()));
  end if;
  if not new.cambiar_clave then new.clave_temporal_en := null; new.clave_temporal_vence := null; end if;
  return new;
end $$;
drop trigger if exists ast_perfiles_clave on public.ast_perfiles;
create trigger ast_perfiles_clave before insert or update of cambiar_clave on public.ast_perfiles
  for each row execute function public.ast_perfiles_clave();

-- Una clave temporal vencida no da acceso a nada hasta que el administrador genere otra
create or replace function public.ast_nivel(p_mod text) returns int language plpgsql stable security definer set search_path=public
as $$
declare p public.ast_perfiles;
begin
  if auth.uid() is null then return public.ast_nivel_base('taller', p_mod); end if;   -- taller sin cuenta
  select * into p from public.ast_perfiles where id = auth.uid() and activo;
  if not found then return 0; end if;                                                 -- cuenta deshabilitada o sin perfil
  if p.cambiar_clave and p.clave_temporal_vence is not null and p.clave_temporal_vence < now() then return 0; end if;
  if p.rol = 'admin' and p_mod in ('usuarios','configuracion','papelera') then return 5; end if;
  if p.permisos ? p_mod then return greatest(0, least(5, (p.permisos->>p_mod)::int)); end if;
  return public.ast_nivel_base(p.rol, p_mod);
end $$;

create or replace function public.ast_niveles() returns jsonb language sql stable security definer set search_path=public
as $$
  select jsonb_object_agg(m, public.ast_nivel(m))
  from unnest(array['ast_dia','firmas','historico','dashboard','revision','auditoria','dispositivos','usuarios','configuracion','papelera']) m
$$;

create or replace function public.ast_mi_perfil(p_ingreso boolean default false) returns jsonb language plpgsql security definer set search_path=public
as $$
declare p public.ast_perfiles; venc boolean;
begin
  select * into p from public.ast_perfiles where id = auth.uid();
  if not found then return null; end if;
  venc := p.cambiar_clave and p.clave_temporal_vence is not null and p.clave_temporal_vence < now();
  if p_ingreso and p.activo then
    update public.ast_perfiles set ultimo_ingreso = now(), primer_ingreso = coalesce(primer_ingreso, now()),
      ultimo_dispositivo = public.ast_dispositivo() where id = p.id;
    perform public.ast_anotar(case when venc then 'Intentó ingresar con una clave temporal vencida' else 'Inició sesión' end, public.ast_rol_nombre(p.rol));
  end if;
  return jsonb_build_object('id',p.id,'usuario',p.usuario,'nombre',trim(p.nombre||' '||p.apellido),'nom',p.nombre,'ape',p.apellido,
    'rut',p.rut,'cargo',p.cargo,'rol',p.rol,'rolNombre',public.ast_rol_nombre(p.rol),'activo',p.activo,
    'cambiar',p.cambiar_clave,'claveTemporalEn',p.clave_temporal_en,'claveTemporalVence',p.clave_temporal_vence,
    'claveVencida',coalesce(venc,false),'niveles',public.ast_niveles());
end $$;

create or replace function public.ast_cambie_mi_clave() returns void language plpgsql security definer set search_path=public
as $$
declare p public.ast_perfiles;
begin
  select * into p from public.ast_perfiles where id = auth.uid();
  if not found then raise exception 'La cuenta no existe.'; end if;
  if p.cambiar_clave and p.clave_temporal_vence is not null and p.clave_temporal_vence < now() then
    raise exception 'Tu clave temporal venció. Pide al administrador una nueva.' using errcode = '42501';
  end if;
  update public.ast_perfiles set cambiar_clave = false where id = auth.uid();
  perform public.ast_anotar('Cambió su contraseña','');
end $$;

create or replace function public.ast_admin_clave(p_id uuid, p_clave text) returns void language plpgsql security definer set search_path=public
as $$
declare u public.ast_perfiles;
begin
  perform public.ast_exigir('usuarios', 5);
  if length(coalesce(p_clave,'')) < 8 or p_clave !~ '[A-Za-z]' or p_clave !~ '[0-9]' then
    raise exception 'La contraseña debe tener al menos 8 caracteres, con letras y números.';
  end if;
  select * into u from public.ast_perfiles where id = p_id;
  if not found then raise exception 'La cuenta no existe.'; end if;
  update auth.users set encrypted_password = extensions.crypt(p_clave, extensions.gen_salt('bf', 10)), updated_at = now() where id = p_id;
  update public.ast_perfiles set cambiar_clave = true, clave_temporal_en = now(),
    clave_temporal_vence = now() + make_interval(days => public.ast_dias_clave_temporal()) where id = p_id;
  perform public.ast_anotar('Generó una clave temporal', u.usuario);
end $$;

create or replace function public.ast_crear_cuenta(p_usuario text, p_nombre text, p_apellido text, p_rut text, p_cargo text,
  p_rol text, p_clave text, p_orden int, p_por text) returns uuid language plpgsql security definer set search_path=public
as $$
declare uid uuid := gen_random_uuid(); correo text;
begin
  p_usuario := lower(trim(p_usuario));
  if p_usuario !~ '^[a-z0-9._-]{3,30}$' then raise exception 'Usuario no válido: 3 a 30 letras sin tildes, números, punto o guion.'; end if;
  if p_rol not in ('admin','gerencia','supervisor','planificador','calidad','prevencion','admin_taller','taller','visitante') then raise exception 'Perfil no válido.'; end if;
  if length(coalesce(p_clave,'')) < 8 or p_clave !~ '[A-Za-z]' or p_clave !~ '[0-9]' then raise exception 'La contraseña debe tener al menos 8 caracteres, con letras y números.'; end if;
  if exists(select 1 from public.ast_perfiles where usuario = p_usuario) then raise exception 'Ese usuario ya existe.'; end if;
  correo := p_usuario || '@ast-sman.local';
  if exists(select 1 from auth.users where email = correo) then raise exception 'Ese usuario ya existe.'; end if;
  insert into auth.users(instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', correo,
    extensions.crypt(p_clave, extensions.gen_salt('bf', 10)), now(),
    '{"provider":"email","providers":["email"]}'::jsonb, jsonb_build_object('usuario', p_usuario), now(), now(), '', '', '', '');
  insert into auth.identities(id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), uid::text, uid, jsonb_build_object('sub', uid::text, 'email', correo, 'email_verified', true), 'email', now(), now(), now());
  insert into public.ast_perfiles(id, usuario, nombre, apellido, rut, cargo, rol, orden, creado_por)
  values (uid, p_usuario, trim(p_nombre), trim(coalesce(p_apellido,'')), coalesce(p_rut,''), coalesce(p_cargo,''), p_rol, coalesce(p_orden,100), p_por);
  return uid;
end $$;

create or replace function public.ast_admin_editar_usuario(p_id uuid, p_nombre text, p_apellido text, p_rut text, p_cargo text,
  p_rol text, p_permisos jsonb, p_orden int) returns void language plpgsql security definer set search_path=public
as $$
declare antes public.ast_perfiles; k text; limpio jsonb := '{}'::jsonb;
begin
  perform public.ast_exigir('usuarios', 5);
  select * into antes from public.ast_perfiles where id = p_id;
  if not found then raise exception 'La cuenta no existe.'; end if;
  if p_rol not in ('admin','gerencia','supervisor','planificador','calidad','prevencion','admin_taller','taller','visitante') then raise exception 'Perfil no válido.'; end if;
  if antes.rol = 'admin' and p_rol <> 'admin'
     and not exists(select 1 from public.ast_perfiles where rol='admin' and activo and id <> p_id) then
    raise exception 'Debe quedar al menos un administrador activo.';
  end if;
  for k in select jsonb_object_keys(coalesce(p_permisos,'{}'::jsonb)) loop
    if k in ('ast_dia','firmas','historico','dashboard','revision','auditoria','dispositivos','usuarios','configuracion','papelera') then
      limpio := limpio || jsonb_build_object(k, greatest(0, least(5, (p_permisos->>k)::int)));
    end if;
  end loop;
  update public.ast_perfiles set nombre = trim(p_nombre), apellido = trim(coalesce(p_apellido,'')), rut = coalesce(p_rut,''),
    cargo = coalesce(p_cargo,''), rol = p_rol, permisos = limpio, orden = coalesce(p_orden, orden), modificado = now()
  where id = p_id;
  perform public.ast_anotar('Modificó un usuario', antes.usuario||' · '||public.ast_rol_nombre(p_rol)||
    case when limpio <> '{}'::jsonb then ' · permisos ajustados '||limpio::text else '' end);
end $$;

-- ---------------------------------------------------------------------
-- 3. PAPELERA DE AST
--    «Eliminar» no borra: la AST sale de todas las listas y queda en la
--    papelera con su número, sus firmas, el motivo y quién la eliminó.
--    El administrador la puede recuperar. Los números no se reutilizan.
-- ---------------------------------------------------------------------
create table if not exists public.ast_papelera(
  ast_id text primary key,
  eliminada_en timestamptz not null default now(),
  eliminada_por uuid,
  eliminada_por_nombre text,
  motivo text not null
);
create table if not exists public.ast_papelera_historial(
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  ast_id text not null, accion text not null, motivo text, usuario text, nombre text
);
alter table public.ast_papelera enable row level security;
alter table public.ast_papelera_historial enable row level security;
revoke all on public.ast_papelera, public.ast_papelera_historial from anon, authenticated;

create or replace function public.ast_en_papelera(p_id text) returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.ast_papelera where ast_id = p_id) $$;
grant execute on function public.ast_en_papelera(text) to anon, authenticated;

drop policy if exists ast_registros_fuera_papelera on public.ast_registros;
create policy ast_registros_fuera_papelera on public.ast_registros as restrictive for select to anon, authenticated
  using (not public.ast_en_papelera(id::text));
drop policy if exists ast_registros_fuera_papelera_ed on public.ast_registros;
create policy ast_registros_fuera_papelera_ed on public.ast_registros as restrictive for update to anon, authenticated
  using (not public.ast_en_papelera(id::text));

create or replace function public.ast_num_txt(p_id text) returns text language sql stable security definer set search_path=public
as $$ select coalesce((select 'N° '||numero||case when rev>0 then ' Rev.'||rev else '' end from public.ast_correlativos where ast_id = p_id),'sin número') $$;

create or replace function public.ast_eliminar(p_id text, p_motivo text) returns jsonb language plpgsql security definer set search_path=public
as $$
declare r public.ast_registros; q jsonb := public.ast_quien(); m text := trim(coalesce(p_motivo,''));
begin
  perform public.ast_exigir('papelera', 5);
  if length(m) < 5 then raise exception 'Escribe el motivo (al menos 5 letras).'; end if;
  select * into r from public.ast_registros where id::text = p_id;
  if not found then raise exception 'La AST no existe.'; end if;
  if exists(select 1 from public.ast_papelera where ast_id = p_id) then raise exception 'Esa AST ya está en la papelera.'; end if;
  insert into public.ast_papelera(ast_id, eliminada_por, eliminada_por_nombre, motivo) values (p_id, auth.uid(), q->>'nombre', left(m,500));
  insert into public.ast_papelera_historial(ast_id, accion, motivo, usuario, nombre) values (p_id, 'eliminada', left(m,500), q->>'usuario', q->>'nombre');
  perform public.ast_anotar('Eliminó una AST (quedó en la papelera)', public.ast_num_txt(p_id)||' · '||coalesce(r.area,'')||' · '||r.fecha::text||' · motivo: '||left(m,300));
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ast_eliminar(text,text) to authenticated;

create or replace function public.ast_recuperar(p_id text) returns jsonb language plpgsql security definer set search_path=public
as $$
declare q jsonb := public.ast_quien();
begin
  perform public.ast_exigir('papelera', 5);
  delete from public.ast_papelera where ast_id = p_id;
  if not found then raise exception 'Esa AST no está en la papelera.'; end if;
  insert into public.ast_papelera_historial(ast_id, accion, usuario, nombre) values (p_id, 'recuperada', q->>'usuario', q->>'nombre');
  perform public.ast_anotar('Recuperó una AST de la papelera', public.ast_num_txt(p_id));
  return jsonb_build_object('ok', true);
end $$;
grant execute on function public.ast_recuperar(text) to authenticated;

create or replace function public.ast_papelera_lista() returns jsonb language plpgsql stable security definer set search_path=public
as $$
begin
  perform public.ast_exigir('papelera', 5);
  return coalesce((select jsonb_agg(jsonb_build_object(
      'id', r.id::text, 'fecha', r.fecha, 'area', r.area, 'linea', r.linea, 'estado', r.estado, 'responsable', r.responsable,
      'ran', r.ran, 'equipo', r.equipo, 'sup_nombre', r.sup_nombre, 'sup_hora', r.sup_hora,
      'descripcion', r.contenido->>'descripcion', 'areaN', r.contenido->>'areaN', 'lineaN', r.contenido->>'lineaN',
      'numero', c.numero, 'rev', c.rev, 'eliminada_en', p.eliminada_en, 'eliminada_por', p.eliminada_por_nombre, 'motivo', p.motivo)
      order by p.eliminada_en desc)
    from public.ast_papelera p join public.ast_registros r on r.id::text = p.ast_id
    left join public.ast_correlativos c on c.ast_id = p.ast_id), '[]'::jsonb);
end $$;
grant execute on function public.ast_papelera_lista() to authenticated;

-- ---------------------------------------------------------------------
-- 4. PARTICIPANTES DESPUÉS DE LA FIRMA: motivo de incorporación
-- ---------------------------------------------------------------------
alter table public.ast_participantes add column if not exists motivo text;

create or replace function public.ast_participantes_alta() returns trigger language plpgsql security definer set search_path=public
as $$
declare r public.ast_registros; rutn text;
begin
  select * into r from public.ast_registros where id::text = new.ast_id::text;
  if not found then raise exception 'La AST no existe.' using errcode = '42501'; end if;
  if public.ast_en_papelera(new.ast_id::text) then raise exception 'La AST está en la papelera.' using errcode = '42501'; end if;
  if r.estado not in ('borrador','pendiente','firmada') then
    raise exception 'La AST ya terminó su vigencia: no se pueden agregar participantes.' using errcode = '42501';
  end if;
  if coalesce(trim(new.nombre),'') = '' then raise exception 'Falta el nombre del participante.'; end if;
  if coalesce(new.firma,'') = '' then raise exception 'Falta la firma del participante.'; end if;
  new.declaracion_aceptada := coalesce(new.declaracion_aceptada, true);
  if not new.declaracion_aceptada then raise exception 'El participante debe aceptar la declaración.'; end if;
  rutn := upper(regexp_replace(coalesce(new.rut,''),'[^0-9kK]','','g'));
  if rutn <> '' and exists (select 1 from public.ast_participantes p where p.ast_id::text = new.ast_id::text
       and upper(regexp_replace(coalesce(p.rut,''),'[^0-9kK]','','g')) = rutn) then
    raise exception 'Esa persona ya está registrada en esta AST.';
  end if;
  new.post_firma := r.sup_firma is not null;
  if new.post_firma then new.motivo := left(coalesce(nullif(trim(new.motivo),''),'Sin motivo indicado'),300);
  else new.motivo := nullif(left(trim(coalesce(new.motivo,'')),300),''); end if;
  new.registrado_en := now();
  new.dispositivo := public.ast_dispositivo();
  new.registrado_por := public.ast_quien()->>'nombre';
  return new;
end $$;

create or replace function public.ast_participantes_auditar() returns trigger language plpgsql security definer set search_path=public
as $$
begin
  perform public.ast_anotar(case when new.post_firma then 'Agregó un participante después de la firma' else 'Registró un participante' end,
    new.nombre||coalesce(' · '||nullif(new.rut,''),'')||' · AST '||public.ast_num_txt(new.ast_id::text)||
    case when new.post_firma then ' · motivo: '||coalesce(new.motivo,'') else '' end);
  return null;
end $$;

-- ---------------------------------------------------------------------
-- 5. LECTURAS MÁS RÁPIDAS: los permisos se calculan una vez por consulta
--    y no una vez por fila (mismo resultado, menos trabajo para la base)
-- ---------------------------------------------------------------------
drop policy if exists ast_registros_leer on public.ast_registros;
create policy ast_registros_leer on public.ast_registros for select to anon, authenticated using (
  (select public.ast_acceso_ok()) and (
    (select public.ast_nivel('historico')) >= 1
    or ((select public.ast_nivel('ast_dia')) >= 1 and public.ast_del_dia(fecha::date, estado))));
create index if not exists ast_registros_fecha_idx on public.ast_registros(fecha);
create index if not exists ast_participantes_ast_idx on public.ast_participantes(ast_id);

commit;

select 'Migración 003 lista' as resultado,
  (select count(*) from information_schema.columns where table_name='ast_perfiles' and column_name in ('clave_temporal_en','clave_temporal_vence')) as columnas_clave,
  (select count(*) from information_schema.columns where table_name='ast_participantes' and column_name='motivo') as columna_motivo,
  (select count(*) from public.ast_papelera) as ast_en_papelera;
