-- =====================================================================
--  AST DIGITAL 3.2 · VERIFICACIÓN (solo lectura, no cambia nada)
--  Córrelo en Supabase > SQL Editor después de las migraciones 001 y 002.
--  Cada fila debe decir «OK». Si alguna dice «REVISAR», no publiques la app todavía.
-- =====================================================================
with v as (
  select 'Tabla de cuentas (ast_perfiles) existe' c, to_regclass('public.ast_perfiles') is not null ok
  union all select 'Tabla de correlativos existe', to_regclass('public.ast_correlativos') is not null
  union all select 'Tabla de clave de emergencia existe', to_regclass('public.ast_emergencia') is not null
  union all select 'Clave de emergencia configurada (cifrada)', (select count(*) from public.ast_emergencia) = 1
  union all select 'La clave de emergencia no está en texto plano', (select hash like '$2%' from public.ast_emergencia limit 1)
  union all select 'Seguridad por filas (RLS) activa en ast_registros', (select relrowsecurity from pg_class where oid='public.ast_registros'::regclass)
  union all select 'RLS activa en ast_participantes', (select relrowsecurity from pg_class where oid='public.ast_participantes'::regclass)
  union all select 'RLS activa en ast_config', (select relrowsecurity from pg_class where oid='public.ast_config'::regclass)
  union all select 'RLS activa en ast_perfiles', (select relrowsecurity from pg_class where oid='public.ast_perfiles'::regclass)
  union all select 'Nadie puede borrar AST desde la app (sin regla DELETE)',
    not exists (select 1 from pg_policies where tablename='ast_registros' and cmd in ('DELETE','ALL'))
  union all select 'Regla que bloquea AST firmadas instalada', exists (select 1 from pg_trigger where tgname='ast_registros_reglas')
  union all select 'Registro de participantes después de la firma instalado', exists (select 1 from pg_trigger where tgname='ast_participantes_alta')
  union all select 'Columnas nuevas de participantes (5)', (select count(*) from information_schema.columns where table_schema='public' and table_name='ast_participantes'
      and column_name in ('post_firma','registrado_por','registrado_en','declaracion_aceptada','dispositivo')) = 5
  union all select 'No hay números correlativos repetidos', not exists (select numero, rev from public.ast_correlativos group by numero, rev having count(*) > 1)
  union all select 'Cada AST firmada tiene su número', not exists (select 1 from public.ast_registros r where r.estado in ('firmada','cerrada') and r.sup_firma is not null
      and not exists (select 1 from public.ast_correlativos c where c.ast_id = r.id::text))
  union all select 'Todo participante pertenece a una AST existente', not exists (select 1 from public.ast_participantes p
      where not exists (select 1 from public.ast_registros r where r.id::text = p.ast_id::text))
  union all select 'No quedan claves antiguas en la configuración', not exists (select 1 from public.ast_config where datos->'gen' ? 'CLAVE_ADMIN' or datos->'gen' ? 'PIN_MAESTRO')
  union all select 'Hay al menos un administrador activo', exists (select 1 from public.ast_perfiles where rol='admin' and activo)
)
select case when ok then 'OK' else 'REVISAR' end as estado, c as revision from v;

-- Conteos para comparar con los que anotaste ANTES de migrar (no deben bajar):
select (select count(*) from public.ast_registros) as ast_total,
       (select count(*) from public.ast_registros where sup_firma is not null) as ast_firmadas,
       (select count(*) from public.ast_participantes) as participantes,
       (select max(numero) from public.ast_correlativos) as ultimo_numero;
