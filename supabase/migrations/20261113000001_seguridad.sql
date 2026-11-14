-- =====================================================================
--  AST DIGITAL 3.1 · SEGURIDAD REAL EN SUPABASE
--  Taller SMAN · SM Cyclo de Chile Ltda.
--
--  Cómo usarlo:
--    Supabase → tu proyecto → SQL Editor → New query → pegar TODO → Run.
--  Qué hace, en orden:
--    0. Respalda las tres tablas actuales en un esquema privado (respaldo).
--    1. Crea las tablas nuevas: perfiles, dispositivos, accesos, firmas y números.
--    2. Crea las reglas que la base revisa en cada operación (RLS y disparadores).
--    3. Pasa a tablas los números oficiales y las firmas que ya existían.
--    4. Crea las cuentas iniciales (ver la sección 9, al final).
--  No borra ni cambia ninguna AST, participante ni firma existente.
--  Se puede ejecutar más de una vez: no duplica nada.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 0. RESPALDO (esquema «respaldo»: no se publica por la API)
-- ---------------------------------------------------------------------
create schema if not exists respaldo;
revoke all on schema respaldo from public;
do $$
declare s text := to_char(now() at time zone 'America/Santiago','YYYYMMDD_HH24MISS');
begin
  execute format('create table if not exists respaldo.%I as table public.ast_registros','ast_registros_'||s);
  execute format('create table if not exists respaldo.%I as table public.ast_participantes','ast_participantes_'||s);
  execute format('create table if not exists respaldo.%I as table public.ast_config','ast_config_'||s);
end $$;

-- contenido y datos deben ser jsonb (si eran json se convierten sin perder nada)
do $$
begin
  if (select data_type from information_schema.columns where table_schema='public' and table_name='ast_registros' and column_name='contenido')='json' then
    alter table public.ast_registros alter column contenido type jsonb using contenido::jsonb;
  end if;
  if (select data_type from information_schema.columns where table_schema='public' and table_name='ast_config' and column_name='datos')='json' then
    alter table public.ast_config alter column datos type jsonb using datos::jsonb;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 1. TABLAS NUEVAS
-- ---------------------------------------------------------------------
create table if not exists public.ast_perfiles(
  id uuid primary key references auth.users(id) on delete cascade,
  usuario text unique not null,
  nombre text not null,
  apellido text not null default '',
  rut text not null default '',
  cargo text not null default '',
  rol text not null check (rol in ('admin','gerencia','supervisor','calidad','prevencion','admin_taller','taller')),
  permisos jsonb not null default '{}'::jsonb,       -- ajustes individuales: {"modulo": nivel}
  activo boolean not null default true,
  cambiar_clave boolean not null default true,
  orden int not null default 100,                    -- posición en «Se envía a firma de»
  creado timestamptz not null default now(),
  creado_por text,
  modificado timestamptz,
  primer_ingreso timestamptz,
  ultimo_ingreso timestamptz,
  ultimo_dispositivo text
);
create table if not exists public.ast_dispositivos(
  id text primary key check (id ~ '^[A-Za-z0-9_-]{20,80}$'),
  usuario_id uuid references auth.users(id) on delete set null,
  nombre text, rut text, cargo text, agente text,
  primer_ingreso timestamptz not null default now(),
  ultimo_ingreso timestamptz not null default now(),
  ingresos int not null default 1,
  revocado boolean not null default false,
  revocado_por text, revocado_en timestamptz
);
create table if not exists public.ast_accesos(
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  usuario_id uuid, usuario text, nombre text, rol text, dispositivo text,
  accion text not null, detalle text
);
create index if not exists ast_accesos_ts on public.ast_accesos(ts desc);
create index if not exists ast_accesos_usr on public.ast_accesos(usuario_id, ts desc);
create table if not exists public.ast_firmas(
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references auth.users(id) on delete set null,
  nombre text, img text not null, origen text,
  activa boolean not null default true,
  creada timestamptz not null default now(), por text,
  hist jsonb not null default '[]'::jsonb
);
create unique index if not exists ast_firmas_una_activa on public.ast_firmas(usuario_id) where activa and usuario_id is not null;
create table if not exists public.ast_correlativos(
  ast_id text primary key,
  numero int not null, rev int not null default 0,
  base_id text, asignado timestamptz not null default now(),
  unique(numero, rev)
);
create sequence if not exists public.ast_numero_seq;

-- ---------------------------------------------------------------------
-- 2. FUNCIONES DE APOYO (la base decide quién es quién; nada viene del navegador)
-- ---------------------------------------------------------------------
create or replace function public.ast_hoy() returns date language sql stable
as $$ select (now() at time zone 'America/Santiago')::date $$;

-- Niveles: 0 sin acceso · 1 solo lectura · 2 crear · 3 editar · 4 firmar · 5 administrar
create or replace function public.ast_nivel_base(p_rol text, p_mod text) returns int language sql immutable
as $$
  select coalesce((case p_rol
    when 'admin'        then '{"ast_dia":5,"firmas":5,"historico":5,"dashboard":5,"revision":5,"auditoria":5,"dispositivos":5,"usuarios":5,"configuracion":5}'
    when 'gerencia'     then '{"ast_dia":1,"firmas":4,"historico":3,"dashboard":1,"revision":1,"auditoria":1}'
    when 'supervisor'   then '{"ast_dia":3,"firmas":4,"historico":3,"dashboard":1,"revision":1}'
    when 'calidad'      then '{"ast_dia":1,"firmas":4,"historico":1,"dashboard":1,"revision":1}'
    when 'prevencion'   then '{"ast_dia":1,"firmas":4,"historico":3,"dashboard":1,"revision":1,"auditoria":1}'
    when 'admin_taller' then '{"ast_dia":3,"firmas":1,"historico":1,"dashboard":1,"revision":1,"auditoria":1,"dispositivos":3}'
    when 'taller'       then '{"ast_dia":2,"firmas":1}'
    else '{}' end)::jsonb->>p_mod, '0')::int
$$;

create or replace function public.ast_nivel(p_mod text) returns int language plpgsql stable security definer set search_path=public
as $$
declare p public.ast_perfiles;
begin
  if auth.uid() is null then return public.ast_nivel_base('taller', p_mod); end if;   -- taller sin cuenta
  select * into p from public.ast_perfiles where id = auth.uid() and activo;
  if not found then return 0; end if;                                                 -- cuenta deshabilitada o sin perfil
  if p.rol = 'admin' and p_mod in ('usuarios','configuracion') then return 5; end if; -- el administrador no se puede dejar fuera
  if p.permisos ? p_mod then return greatest(0, least(5, (p.permisos->>p_mod)::int)); end if;
  return public.ast_nivel_base(p.rol, p_mod);
end $$;

create or replace function public.ast_niveles() returns jsonb language sql stable security definer set search_path=public
as $$
  select jsonb_object_agg(m, public.ast_nivel(m))
  from unnest(array['ast_dia','firmas','historico','dashboard','revision','auditoria','dispositivos','usuarios','configuracion']) m
$$;

create or replace function public.ast_dispositivo() returns text language sql stable
as $$ select nullif(coalesce(current_setting('request.headers', true),'{}')::jsonb->>'x-ast-dispositivo','') $$;

-- ¿la solicitud viene de un acceso válido?
--   sin cuenta: un dispositivo registrado y no bloqueado
--   con cuenta: perfil activo y dispositivo no bloqueado
create or replace function public.ast_acceso_ok() returns boolean language sql stable security definer set search_path=public
as $$
  select case when auth.uid() is null then
      exists(select 1 from public.ast_dispositivos d where d.id = public.ast_dispositivo() and not d.revocado)
    else
      exists(select 1 from public.ast_perfiles p where p.id = auth.uid() and p.activo)
      and not exists(select 1 from public.ast_dispositivos d where d.id = public.ast_dispositivo() and d.revocado)
    end
$$;

-- AST «del día»: hoy, o ayer para el turno de noche, y todavía vigente
create or replace function public.ast_del_dia(f date, e text) returns boolean language sql stable
as $$ select f >= public.ast_hoy() - 1 and e in ('borrador','pendiente','firmada') $$;

create or replace function public.ast_quien() returns jsonb language sql stable security definer set search_path=public
as $$
  select coalesce(
    (select jsonb_build_object('id',p.id,'usuario',p.usuario,'nombre',trim(p.nombre||' '||p.apellido),'rol',p.rol)
       from public.ast_perfiles p where p.id = auth.uid()),
    (select jsonb_build_object('usuario','','nombre',coalesce(d.nombre,'Taller'),'rol','taller')
       from public.ast_dispositivos d where d.id = public.ast_dispositivo()),
    jsonb_build_object('usuario','','nombre','—','rol', case when auth.uid() is null then 'taller' else '?' end))
$$;

create or replace function public.ast_anotar(p_accion text, p_detalle text) returns void language plpgsql security definer set search_path=public
as $$
declare q jsonb := public.ast_quien();
begin
  insert into public.ast_accesos(usuario_id, usuario, nombre, rol, dispositivo, accion, detalle)
  values (auth.uid(), q->>'usuario', q->>'nombre', q->>'rol', public.ast_dispositivo(), left(p_accion,160), left(coalesce(p_detalle,''),600));
end $$;

create or replace function public.ast_rol_nombre(r text) returns text language sql immutable
as $$ select case r when 'admin' then 'Administrador' when 'gerencia' then 'Gerencia' when 'supervisor' then 'Supervisor'
  when 'calidad' then 'Calidad' when 'prevencion' then 'Prevención de Riesgos' when 'admin_taller' then 'Administrador de taller'
  when 'taller' then 'Personal de taller' else r end $$;

-- ---------------------------------------------------------------------
-- 3. REGLAS DE LAS AST (disparador: se cumplen aunque alguien manipule el navegador)
-- ---------------------------------------------------------------------
create or replace function public.ast_registros_reglas() returns trigger language plpgsql security definer set search_path=public
as $$
declare
  p public.ast_perfiles;
  libres text[] := array['auditoria','reemplazadaPor','enRevision','notas'];
  nviejas int; num int; r int; base text; reg jsonb; ahora timestamptz := now();
begin
  if tg_op = 'DELETE' then
    raise exception 'Las AST no se eliminan: son documentos permanentes.' using errcode = '42501';
  end if;
  select * into p from public.ast_perfiles where id = auth.uid() and activo;

  if tg_op = 'INSERT' then
    if new.sup_firma is not null or new.sup_nombre is not null or new.sup_hora is not null or new.estado not in ('borrador','pendiente') then
      raise exception 'Una AST nueva no puede venir firmada.' using errcode = '42501';
    end if;
    new.contenido := coalesce(new.contenido,'{}'::jsonb) - 'correlativo' - 'rev' - 'firmas';
    return new;
  end if;

  -- ===== documento firmado o cerrado: bloqueado para todos =====
  if old.sup_firma is not null or old.estado in ('cerrada','anulada') then
    if (new.sup_firma, new.sup_nombre, new.sup_hora, new.sup_obs, new.fecha, new.area, new.linea, new.responsable,
        new.ran, new.cliente, new.equipo, new.turno, new.hora_inicio, new.hora_fin, new.doc)
       is distinct from
       (old.sup_firma, old.sup_nombre, old.sup_hora, old.sup_obs, old.fecha, old.area, old.linea, old.responsable,
        old.ran, old.cliente, old.equipo, old.turno, old.hora_inicio, old.hora_fin, old.doc) then
      raise exception 'AST firmada o cerrada: el documento está bloqueado.' using errcode = '42501';
    end if;
    if new.estado is distinct from old.estado and new.estado <> 'cerrada' then
      raise exception 'AST firmada o cerrada: el estado no se puede cambiar.' using errcode = '42501';
    end if;
    if (coalesce(new.contenido,'{}'::jsonb) - libres) is distinct from (coalesce(old.contenido,'{}'::jsonb) - libres) then
      raise exception 'AST firmada o cerrada: solo se pueden agregar notas de corrección.' using errcode = '42501';
    end if;
    if (new.contenido->'notas') is distinct from (old.contenido->'notas') then
      if public.ast_nivel('historico') < 3 then
        raise exception 'No tienes permiso para agregar notas de corrección.' using errcode = '42501';
      end if;
      nviejas := coalesce(jsonb_array_length(old.contenido->'notas'),0);
      if coalesce(jsonb_array_length(new.contenido->'notas'),0) < nviejas
         or (nviejas > 0 and (select jsonb_agg(x order by i) from jsonb_array_elements(new.contenido->'notas') with ordinality t(x,i) where i <= nviejas)
             is distinct from old.contenido->'notas') then
        raise exception 'Las notas anteriores no se pueden cambiar ni borrar.' using errcode = '42501';
      end if;
    end if;
    if (old.contenido ? 'reemplazadaPor') and (new.contenido->'reemplazadaPor') is distinct from (old.contenido->'reemplazadaPor') then
      raise exception 'El reemplazo de una versión no se puede cambiar.' using errcode = '42501';
    end if;
    return new;
  end if;

  -- ===== firma de aprobación =====
  if new.sup_firma is not null then
    if p.id is null or public.ast_nivel('firmas') < 4 then
      raise exception 'No tienes permiso para firmar AST.' using errcode = '42501';
    end if;
    if old.estado <> 'pendiente' then
      raise exception 'Solo se firman AST enviadas a firma.' using errcode = '42501';
    end if;
    if coalesce(old.contenido->>'supId','') <> '' and old.contenido->>'supId' <> p.id::text then
      raise exception 'Esta AST está asignada a otra persona.' using errcode = '42501';
    end if;
    new.estado := 'firmada';
    new.sup_nombre := trim(p.nombre||' '||p.apellido);
    new.sup_hora := to_char(ahora at time zone 'America/Santiago','HH24:MI');
    reg := jsonb_build_object('nombre', new.sup_nombre, 'usuarioId', p.id, 'usuario', p.usuario, 'perfil', p.rol,
      'rol', public.ast_rol_nombre(p.rol), 'fecha', to_char(ahora at time zone 'America/Santiago','YYYY-MM-DD'),
      'hora', new.sup_hora, 'ts', ahora, 'dispositivo', public.ast_dispositivo(),
      'metodo', left(coalesce(new.contenido->'firmas'->-1->>'metodo','firma trazada en pantalla'),60));
    new.contenido := (coalesce(new.contenido,'{}'::jsonb) - 'firmas' - 'enRevision' - 'correlativo' - 'rev')
      || jsonb_build_object('supId', p.id::text, 'supTaller', new.sup_nombre,
                            'firmas', coalesce(old.contenido->'firmas','[]'::jsonb) || jsonb_build_array(reg));
    -- número oficial: una sola vez, sin repetir (secuencia de la base)
    base := nullif(new.contenido->>'versionBase','');
    select numero into num from public.ast_correlativos where ast_id = base;
    if num is not null then
      perform pg_advisory_xact_lock(num);
      select coalesce(max(rev),0)+1 into r from public.ast_correlativos where numero = num;
    else
      num := nextval('public.ast_numero_seq'); r := 0;
    end if;
    insert into public.ast_correlativos(ast_id, numero, rev, base_id) values (new.id::text, num, r, base)
      on conflict (ast_id) do nothing;
    select c.numero, c.rev into num, r from public.ast_correlativos c where c.ast_id = new.id::text;
    new.contenido := new.contenido || jsonb_build_object('correlativo', num)
      || case when r > 0 then jsonb_build_object('rev', r) else '{}'::jsonb end;
    return new;
  end if;

  -- ===== cambios en una AST sin firma =====
  if new.estado = 'firmada' then
    raise exception 'Para aprobar una AST hay que firmarla.' using errcode = '42501';
  end if;
  new.sup_nombre := null; new.sup_hora := null;
  new.contenido := (coalesce(new.contenido,'{}'::jsonb) - 'correlativo' - 'rev' - 'firmas')
    || case when old.contenido ? 'firmas' then jsonb_build_object('firmas', old.contenido->'firmas') else '{}'::jsonb end;

  if old.estado = 'pendiente' and public.ast_nivel('firmas') < 4 then
    -- enviada a firma: quien no firma solo puede cerrarla al terminar la vigencia
    if not (new.estado = 'cerrada' and (new.contenido - 'auditoria') is not distinct from (old.contenido - 'auditoria')) then
      raise exception 'La AST está esperando firma: no se puede modificar.' using errcode = '42501';
    end if;
  end if;
  if old.estado = 'pendiente' and new.estado = 'borrador' and coalesce(old.contenido->>'supId','') <> ''
     and old.contenido->>'supId' <> p.id::text then
    raise exception 'Solo quien debe firmar puede devolver esta AST.' using errcode = '42501';
  end if;
  if old.estado = 'pendiente' and coalesce(new.contenido->>'supId','') is distinct from coalesce(old.contenido->>'supId','')
     and coalesce(new.contenido->>'supId','') <> p.id::text then
    raise exception 'Solo puedes tomar una AST a tu propio nombre.' using errcode = '42501';
  end if;
  return new;
end $$;

create or replace function public.ast_registros_auditar() returns trigger language plpgsql security definer set search_path=public
as $$
declare acc text;
begin
  acc := case
    when tg_op = 'INSERT' and new.contenido ? 'versionDe' then 'Creó una nueva versión de AST'
    when tg_op = 'INSERT' then 'Creó una AST'
    when old.sup_firma is null and new.sup_firma is not null then 'Firmó y aprobó una AST'
    when old.estado = 'pendiente' and new.estado = 'borrador' then 'Devolvió una AST a corrección'
    when old.estado <> 'pendiente' and new.estado = 'pendiente' then 'Envió una AST a firma'
    when old.estado <> new.estado and new.estado = 'cerrada' then 'Cerró una AST'
    when (new.contenido->'notas') is distinct from (old.contenido->'notas') then 'Agregó una nota de corrección'
    when (new.contenido->'enRevision') is distinct from (old.contenido->'enRevision') then null
    else 'Modificó una AST' end;
  if acc is not null then
    perform public.ast_anotar(acc, concat_ws(' · ', new.id::text, coalesce(new.contenido->>'areaN', new.area), nullif(new.contenido->>'lineaN',''),
      new.fecha::text, case when new.contenido ? 'correlativo' then 'N° '||(new.contenido->>'correlativo') end));
  end if;
  return null;
end $$;

drop trigger if exists ast_registros_reglas on public.ast_registros;
create trigger ast_registros_reglas before insert or update or delete on public.ast_registros
  for each row execute function public.ast_registros_reglas();
drop trigger if exists ast_registros_auditar on public.ast_registros;
create trigger ast_registros_auditar after insert or update on public.ast_registros
  for each row execute function public.ast_registros_auditar();

create or replace function public.ast_participantes_reglas() returns trigger language plpgsql security definer set search_path=public
as $$
begin
  if tg_op <> 'INSERT' then
    raise exception 'Los registros de participantes no se modifican ni se eliminan.' using errcode = '42501';
  end if;
  return new;
end $$;
drop trigger if exists ast_participantes_reglas on public.ast_participantes;
create trigger ast_participantes_reglas before update or delete on public.ast_participantes
  for each row execute function public.ast_participantes_reglas();

-- ---------------------------------------------------------------------
-- 4. RLS: SE BORRAN LAS POLÍTICAS ABIERTAS Y SE CREAN LAS NUEVAS
-- ---------------------------------------------------------------------
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies where schemaname='public'
           and tablename in ('ast_registros','ast_participantes','ast_config','ast_perfiles','ast_dispositivos',
                             'ast_accesos','ast_firmas','ast_correlativos')
  loop execute format('drop policy %I on public.%I', r.policyname, r.tablename); end loop;
end $$;

alter table public.ast_registros     enable row level security;
alter table public.ast_participantes enable row level security;
alter table public.ast_config        enable row level security;
alter table public.ast_perfiles      enable row level security;
alter table public.ast_dispositivos  enable row level security;
alter table public.ast_accesos       enable row level security;
alter table public.ast_firmas        enable row level security;
alter table public.ast_correlativos  enable row level security;

-- AST
create policy ast_registros_leer on public.ast_registros for select to anon, authenticated using (
  public.ast_acceso_ok() and (
    public.ast_nivel('historico') >= 1
    or (public.ast_nivel('ast_dia') >= 1 and public.ast_del_dia(fecha::date, estado))));
create policy ast_registros_crear on public.ast_registros for insert to anon, authenticated with check (
  public.ast_acceso_ok() and public.ast_nivel('ast_dia') >= 2
  and fecha::date >= public.ast_hoy() - 1 and estado in ('borrador','pendiente'));
create policy ast_registros_editar on public.ast_registros for update to anon, authenticated
  using (public.ast_acceso_ok() and (
    (public.ast_del_dia(fecha::date, estado) and (public.ast_nivel('ast_dia') >= 2 or public.ast_nivel('firmas') >= 4))
    or public.ast_nivel('historico') >= 3))
  with check (public.ast_acceso_ok());
-- sin política de borrado: nadie elimina AST

-- Participantes: se ven y se agregan solo en las AST que uno puede ver
create policy ast_participantes_leer on public.ast_participantes for select to anon, authenticated using (
  exists (select 1 from public.ast_registros r where r.id::text = ast_participantes.ast_id::text));
create policy ast_participantes_crear on public.ast_participantes for insert to anon, authenticated with check (
  public.ast_acceso_ok() and exists (select 1 from public.ast_registros r
    where r.id::text = ast_participantes.ast_id::text and r.estado in ('borrador','pendiente','firmada')));

-- Configuración: la general la leen todos; el resto solo administración
create policy ast_config_leer on public.ast_config for select to anon, authenticated using (
  id = 'main' or public.ast_nivel('configuracion') >= 5);
create policy ast_config_crear on public.ast_config for insert to authenticated with check (public.ast_nivel('configuracion') >= 3);
create policy ast_config_editar on public.ast_config for update to authenticated
  using (public.ast_nivel('configuracion') >= 3) with check (public.ast_nivel('configuracion') >= 3);

-- Perfiles: cada uno ve el suyo; administración ve todos. Se escriben solo por funciones.
create policy ast_perfiles_leer on public.ast_perfiles for select to authenticated using (
  id = auth.uid() or public.ast_nivel('usuarios') >= 1);
-- Dispositivos y accesos: lectura según permiso; se escriben solo por funciones.
create policy ast_dispositivos_leer on public.ast_dispositivos for select to authenticated using (
  usuario_id = auth.uid() or public.ast_nivel('dispositivos') >= 1 or public.ast_nivel('usuarios') >= 1);
create policy ast_accesos_leer on public.ast_accesos for select to authenticated using (
  usuario_id = auth.uid() or public.ast_nivel('auditoria') >= 1 or public.ast_nivel('usuarios') >= 1);
-- Firmas registradas: cada uno la suya; administración todas.
create policy ast_firmas_leer on public.ast_firmas for select to authenticated using (
  (usuario_id = auth.uid() and public.ast_acceso_ok()) or public.ast_nivel('usuarios') >= 5);
create policy ast_firmas_crear on public.ast_firmas for insert to authenticated with check (public.ast_nivel('usuarios') >= 5);
create policy ast_firmas_editar on public.ast_firmas for update to authenticated
  using (public.ast_nivel('usuarios') >= 5) with check (public.ast_nivel('usuarios') >= 5);
-- Números oficiales: se ven junto con las AST que uno puede ver; los asigna solo la base.
create policy ast_correlativos_leer on public.ast_correlativos for select to anon, authenticated using (
  exists (select 1 from public.ast_registros r where r.id::text = ast_correlativos.ast_id));

-- Permisos de tabla (la RLS filtra filas; esto cierra operaciones completas)
revoke delete, truncate on public.ast_registros, public.ast_participantes, public.ast_config from anon, authenticated;
revoke insert, update, delete, truncate on public.ast_perfiles, public.ast_dispositivos, public.ast_accesos, public.ast_correlativos from anon, authenticated;
revoke delete, truncate on public.ast_firmas from anon, authenticated;
revoke insert, update on public.ast_config from anon;
revoke all on public.ast_firmas from anon;
grant select on public.ast_registros, public.ast_participantes, public.ast_config, public.ast_correlativos to anon, authenticated;
grant insert, update on public.ast_registros to anon, authenticated;
grant insert on public.ast_participantes to anon, authenticated;
grant insert, update on public.ast_config to authenticated;
grant select on public.ast_perfiles, public.ast_dispositivos, public.ast_accesos to authenticated;
grant select, insert, update on public.ast_firmas to authenticated;
revoke all on sequence public.ast_numero_seq from anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. FUNCIONES PARA LA APP
-- ---------------------------------------------------------------------
-- Registro del dispositivo (taller y cuentas). Devuelve si está bloqueado.
create or replace function public.ast_registrar_dispositivo(p_id text, p_nombre text, p_rut text, p_cargo text, p_agente text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare d public.ast_dispositivos; nuevo boolean := false;
begin
  if p_id is null or p_id !~ '^[A-Za-z0-9_-]{20,80}$' then raise exception 'Identificador de dispositivo no válido.'; end if;
  select * into d from public.ast_dispositivos where id = p_id;
  if not found then
    insert into public.ast_dispositivos(id, usuario_id, nombre, rut, cargo, agente)
    values (p_id, auth.uid(), left(p_nombre,120), left(p_rut,20), left(p_cargo,80), left(p_agente,300)) returning * into d;
    nuevo := true;
  elsif not d.revocado then
    update public.ast_dispositivos set ultimo_ingreso = now(), ingresos = ingresos + 1,
      usuario_id = coalesce(auth.uid(), usuario_id),
      nombre = coalesce(nullif(left(p_nombre,120),''), nombre), rut = coalesce(nullif(left(p_rut,20),''), rut),
      cargo = coalesce(nullif(left(p_cargo,80),''), cargo), agente = left(p_agente,300)
    where id = p_id returning * into d;
  end if;
  insert into public.ast_accesos(usuario_id, usuario, nombre, rol, dispositivo, accion, detalle)
  values (auth.uid(), coalesce((select usuario from public.ast_perfiles where id = auth.uid()),''),
          coalesce((select trim(nombre||' '||apellido) from public.ast_perfiles where id = auth.uid()), d.nombre, '—'),
          coalesce((select rol from public.ast_perfiles where id = auth.uid()),'taller'), p_id,
          case when d.revocado then 'Intento de ingreso desde un dispositivo bloqueado'
               when nuevo then 'Registró un dispositivo nuevo' else 'Ingresó a la app' end, left(p_agente,160));
  return jsonb_build_object('id', d.id, 'revocado', d.revocado, 'nuevo', nuevo, 'primer_ingreso', d.primer_ingreso);
end $$;

-- Datos de la cuenta con la que se inició sesión
create or replace function public.ast_mi_perfil(p_ingreso boolean default false) returns jsonb language plpgsql security definer set search_path=public
as $$
declare p public.ast_perfiles;
begin
  select * into p from public.ast_perfiles where id = auth.uid();
  if not found then return null; end if;
  if p_ingreso and p.activo then
    update public.ast_perfiles set ultimo_ingreso = now(), primer_ingreso = coalesce(primer_ingreso, now()),
      ultimo_dispositivo = public.ast_dispositivo() where id = p.id;
    perform public.ast_anotar('Inició sesión', public.ast_rol_nombre(p.rol));
  end if;
  return jsonb_build_object('id',p.id,'usuario',p.usuario,'nombre',trim(p.nombre||' '||p.apellido),'nom',p.nombre,'ape',p.apellido,
    'rut',p.rut,'cargo',p.cargo,'rol',p.rol,'rolNombre',public.ast_rol_nombre(p.rol),'activo',p.activo,
    'cambiar',p.cambiar_clave,'niveles',public.ast_niveles());
end $$;

-- Lista para «Se envía a firma de»: solo cuentas activas que pueden firmar
create or replace function public.ast_firmantes() returns table(id uuid, nombre text, rol text, orden int)
language sql stable security definer set search_path=public
as $$
  select p.id, trim(p.nombre||' '||p.apellido), p.rol, p.orden from public.ast_perfiles p
  where p.activo and (case when p.permisos ? 'firmas' then (p.permisos->>'firmas')::int else public.ast_nivel_base(p.rol,'firmas') end) >= 4
  order by p.orden, p.nombre
$$;

create or replace function public.ast_cambie_mi_clave() returns void language plpgsql security definer set search_path=public
as $$ begin
  update public.ast_perfiles set cambiar_clave = false where id = auth.uid();
  perform public.ast_anotar('Cambió su contraseña','');
end $$;

create or replace function public.ast_registrar(p_accion text, p_detalle text) returns void language plpgsql security definer set search_path=public
as $$ begin
  if not public.ast_acceso_ok() then return; end if;
  perform public.ast_anotar('App: '||left(p_accion,140), p_detalle);
end $$;

-- ----- administración (solo quien tiene nivel 5 en usuarios) -----
create or replace function public.ast_exigir(p_mod text, p_min int) returns void language plpgsql stable security definer set search_path=public
as $$ begin
  if public.ast_nivel(p_mod) < p_min or not public.ast_acceso_ok() then
    raise exception 'No tienes permiso para esta operación.' using errcode = '42501';
  end if;
end $$;

-- Interna: no se puede llamar desde la app (solo desde el SQL Editor o desde ast_admin_crear_usuario)
create or replace function public.ast_crear_cuenta(p_usuario text, p_nombre text, p_apellido text, p_rut text, p_cargo text,
  p_rol text, p_clave text, p_orden int, p_por text) returns uuid language plpgsql security definer set search_path=public
as $$
declare uid uuid := gen_random_uuid(); correo text;
begin
  p_usuario := lower(trim(p_usuario));
  if p_usuario !~ '^[a-z0-9._-]{3,30}$' then raise exception 'Usuario no válido: 3 a 30 letras sin tildes, números, punto o guion.'; end if;
  if p_rol not in ('admin','gerencia','supervisor','calidad','prevencion','admin_taller','taller') then raise exception 'Perfil no válido.'; end if;
  if length(coalesce(p_clave,'')) < 8 then raise exception 'La contraseña debe tener al menos 8 caracteres.'; end if;
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
revoke execute on function public.ast_crear_cuenta(text,text,text,text,text,text,text,int,text) from public, anon, authenticated;

create or replace function public.ast_admin_crear_usuario(p_usuario text, p_nombre text, p_apellido text, p_rut text, p_cargo text,
  p_rol text, p_clave text, p_orden int) returns uuid language plpgsql security definer set search_path=public
as $$
declare uid uuid;
begin
  perform public.ast_exigir('usuarios', 5);
  uid := public.ast_crear_cuenta(p_usuario, p_nombre, p_apellido, p_rut, p_cargo, p_rol, p_clave, p_orden,
           (select usuario from public.ast_perfiles where id = auth.uid()));
  perform public.ast_anotar('Creó un usuario', lower(p_usuario)||' · '||public.ast_rol_nombre(p_rol));
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
  if p_rol not in ('admin','gerencia','supervisor','calidad','prevencion','admin_taller','taller') then raise exception 'Perfil no válido.'; end if;
  if antes.rol = 'admin' and p_rol <> 'admin'
     and not exists(select 1 from public.ast_perfiles where rol='admin' and activo and id <> p_id) then
    raise exception 'Debe quedar al menos un administrador activo.';
  end if;
  for k in select jsonb_object_keys(coalesce(p_permisos,'{}'::jsonb)) loop
    if k in ('ast_dia','firmas','historico','dashboard','revision','auditoria','dispositivos','usuarios','configuracion') then
      limpio := limpio || jsonb_build_object(k, greatest(0, least(5, (p_permisos->>k)::int)));
    end if;
  end loop;
  update public.ast_perfiles set nombre = trim(p_nombre), apellido = trim(coalesce(p_apellido,'')), rut = coalesce(p_rut,''),
    cargo = coalesce(p_cargo,''), rol = p_rol, permisos = limpio, orden = coalesce(p_orden, orden), modificado = now()
  where id = p_id;
  perform public.ast_anotar('Modificó un usuario', antes.usuario||' · '||public.ast_rol_nombre(p_rol)||
    case when limpio <> '{}'::jsonb then ' · permisos ajustados '||limpio::text else '' end);
end $$;

create or replace function public.ast_admin_activar(p_id uuid, p_activo boolean) returns void language plpgsql security definer set search_path=public
as $$
declare u public.ast_perfiles;
begin
  perform public.ast_exigir('usuarios', 5);
  select * into u from public.ast_perfiles where id = p_id;
  if not found then raise exception 'La cuenta no existe.'; end if;
  if not p_activo and p_id = auth.uid() then raise exception 'No puedes deshabilitar tu propia cuenta.'; end if;
  if not p_activo and u.rol = 'admin' and not exists(select 1 from public.ast_perfiles where rol='admin' and activo and id <> p_id) then
    raise exception 'Debe quedar al menos un administrador activo.';
  end if;
  update public.ast_perfiles set activo = p_activo, modificado = now() where id = p_id;
  update auth.users set banned_until = case when p_activo then null else 'infinity'::timestamptz end where id = p_id;
  perform public.ast_anotar(case when p_activo then 'Habilitó un usuario' else 'Deshabilitó un usuario' end, u.usuario);
end $$;

create or replace function public.ast_admin_clave(p_id uuid, p_clave text) returns void language plpgsql security definer set search_path=public
as $$
declare u public.ast_perfiles;
begin
  perform public.ast_exigir('usuarios', 5);
  if length(coalesce(p_clave,'')) < 8 then raise exception 'La contraseña debe tener al menos 8 caracteres.'; end if;
  select * into u from public.ast_perfiles where id = p_id;
  if not found then raise exception 'La cuenta no existe.'; end if;
  update auth.users set encrypted_password = extensions.crypt(p_clave, extensions.gen_salt('bf', 10)), updated_at = now() where id = p_id;
  update public.ast_perfiles set cambiar_clave = true where id = p_id;
  perform public.ast_anotar('Restableció la contraseña de un usuario', u.usuario);
end $$;

create or replace function public.ast_admin_dispositivo(p_id text, p_revocar boolean) returns void language plpgsql security definer set search_path=public
as $$
begin
  perform public.ast_exigir('dispositivos', 3);
  update public.ast_dispositivos set revocado = p_revocar,
    revocado_por = case when p_revocar then (select usuario from public.ast_perfiles where id = auth.uid()) end,
    revocado_en = case when p_revocar then now() end
  where id = p_id;
  if not found then raise exception 'El dispositivo no existe.'; end if;
  perform public.ast_anotar(case when p_revocar then 'Bloqueó un dispositivo' else 'Desbloqueó un dispositivo' end, p_id);
end $$;

revoke execute on function public.ast_anotar(text,text) from public, anon, authenticated;
grant execute on function public.ast_registrar_dispositivo(text,text,text,text,text), public.ast_firmantes(),
  public.ast_niveles(), public.ast_registrar(text,text), public.ast_hoy() to anon, authenticated;
grant execute on function public.ast_mi_perfil(boolean), public.ast_cambie_mi_clave(),
  public.ast_admin_crear_usuario(text,text,text,text,text,text,text,int), public.ast_admin_editar_usuario(uuid,text,text,text,text,text,jsonb,int),
  public.ast_admin_activar(uuid,boolean), public.ast_admin_clave(uuid,text), public.ast_admin_dispositivo(text,boolean) to authenticated;

-- ---------------------------------------------------------------------
-- 6. NÚMEROS OFICIALES QUE YA EXISTÍAN (versión 3.0) Y AST FIRMADAS SIN NÚMERO
-- ---------------------------------------------------------------------
insert into public.ast_correlativos(ast_id, numero, rev)
select k, (c.datos->'mapa'->>k)::int, coalesce((c.datos->'rev'->>k)::int, 0)
from public.ast_config c, jsonb_object_keys(coalesce(c.datos->'mapa','{}'::jsonb)) k
where c.id = 'correlativo'
on conflict do nothing;
select setval('public.ast_numero_seq', greatest(coalesce((select max(numero) from public.ast_correlativos),0), 1),
              coalesce((select max(numero) from public.ast_correlativos),0) > 0);
do $$
declare x record; num int; r int; base text;
begin
  for x in select * from public.ast_registros a
           where a.sup_firma is not null and not exists(select 1 from public.ast_correlativos c where c.ast_id = a.id::text)
           order by a.fecha, a.sup_hora nulls last, a.creado
  loop
    base := nullif(x.contenido->>'versionBase','');
    select numero into num from public.ast_correlativos where ast_id = base;
    if num is not null then select coalesce(max(rev),0)+1 into r from public.ast_correlativos where numero = num;
    else num := nextval('public.ast_numero_seq'); r := 0; end if;
    insert into public.ast_correlativos(ast_id, numero, rev, base_id) values (x.id::text, num, r, base);
  end loop;
end $$;

-- Firmas registradas en la versión 3.0: quedan sin cuenta hasta que el administrador las asocie
insert into public.ast_firmas(nombre, img, origen, activa, creada, por, hist)
select f->>'nombre', f->>'img', coalesce(f->>'origen','trazo'), coalesce((f->>'activa')::boolean, true), coalesce((f->>'creada')::timestamptz, now()),
       f->>'por', jsonb_build_array(jsonb_build_object('ts', now(), 'q', 'Migración 3.1', 'a', 'Pasada desde la versión 3.0: falta asociarla a una cuenta'))
from public.ast_config c, jsonb_array_elements(coalesce(c.datos->'lista','[]'::jsonb)) f
where c.id = 'firmas' and f->>'img' is not null and f->>'img' <> 'app:gerencia'
  and not exists (select 1 from public.ast_firmas z where z.img = f->>'img');
-- La firma de Gerencia que viene incluida en la app
insert into public.ast_firmas(nombre, img, origen, activa, por, hist)
select 'Gerencia', 'app:gerencia', 'app', true, 'Migración 3.1', '[]'::jsonb
where not exists (select 1 from public.ast_firmas where img = 'app:gerencia');

-- ---------------------------------------------------------------------
-- 9. CUENTAS INICIALES
--    Lista de «Se envía a firma de», en este orden. Contraseña temporal: la
--    app obliga a cambiarla en el primer ingreso. Ajusta los perfiles después
--    desde la app (Administración de usuarios y permisos).
-- ---------------------------------------------------------------------
do $$
declare c record;
begin
  for c in select * from (values
    ('anunez',      'Alexis',   'Núñez',      'supervisor', 1, '__C1__'),
    ('lcortes',     'Luis',     'Cortés',     'admin',      2, '__C2__'),
    ('bmendoza',    'Bryan',    'Mendoza',    'supervisor', 3, '__C3__'),
    ('rwilliams',   'Richard',  'Williams',   'supervisor', 4, '__C4__'),
    ('mprado',      'Maybeth',  'Prado',      'supervisor', 5, '__C5__'),
    ('fyanez',      'Francisco','Yáñez',      'supervisor', 6, '__C6__'),
    ('bperez',      'Bernardo', 'Pérez',      'supervisor', 7, '__C7__'),
    ('jvillarroel', 'Jazmin',   'Villarroel', 'supervisor', 8, '__C8__')
  ) as t(usuario, nombre, apellido, rol, orden, clave)
  loop
    if not exists (select 1 from public.ast_perfiles where usuario = c.usuario) then
      perform public.ast_crear_cuenta(c.usuario, c.nombre, c.apellido, '', '', c.rol, c.clave, c.orden, 'script inicial');
    end if;
  end loop;
end $$;

commit;

-- Resultado: debe mostrar las 8 cuentas
select usuario, nombre, apellido, rol, orden, activo from public.ast_perfiles order by orden;
