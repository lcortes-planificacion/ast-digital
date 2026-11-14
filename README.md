# AST DIGITAL · SM Cyclo de Chile Ltda. · Taller SMAN

Versión **3.3**. Aplicación web para crear, firmar y archivar el Análisis Seguro de Trabajo (AST) del taller.

- Publicada en GitHub Pages: `https://lcortes-planificacion.github.io/ast-digital/ast-digital.html`
- Datos e inicio de sesión: Supabase (base de datos, reglas de seguridad RLS y Supabase Auth)

> Hoy (13-11-2026) está publicada la **3.2**, con las migraciones 001 y 002 ya corridas en Supabase.
> Para pasar a la 3.3 solo falta la **migración 003** y subir el nuevo `ast-digital.html`.

---

## Qué hay en esta carpeta

| Archivo | Para qué |
|---|---|
| `ast-digital.html` | La app completa (un solo archivo). |
| `index.html` | Redirige a `ast-digital.html`. |
| `supabase/migrations/…001_seguridad.sql` | Migración 001 (ya corrida). Plantilla sin claves, solo como registro. |
| `supabase/migrations/…002_participantes_emergencia.sql` | Migración 002 (ya corrida). Plantilla sin claves, solo como registro. |
| `supabase/migrations/…003_papelera_roles_claves.sql` | **Migración 003: la que hay que correr ahora.** No lleva claves. |
| `supabase/verificacion.sql` | Revisión de solo lectura para después de migrar. |
| `.env.example` | Lista de configuraciones (sin valores reales). |
| `docs/MANUAL.md` | Manual de uso con capturas. |
| `docs/PRUEBAS.md` | Resultado de las pruebas. |
| `CHANGELOG.md` | Lista de cambios. |
| `pruebas/` | Scripts de prueba (solo para una base de prueba, nunca la real). |

### Por qué es un solo archivo HTML

La app está hecha en un solo HTML con JavaScript, sin React ni TypeScript, y sin compilador.
Se mantuvo así a propósito: rehacerla habría puesto en riesgo lo que ya funciona.
No necesita `npm install` para funcionar.

---

## Orden de instalación de la 3.3

1. Respaldo en Supabase.
2. Migración 003.
3. Verificación.
4. Subir `ast-digital.html` a GitHub.

**No vuelvas a correr la migración 002 después de la 003**: devolvería el registro de participantes a la versión sin motivo.
La 003 sí se puede correr más de una vez.

---

## 1. Supabase

### 1.1 Respaldo

1. Entra a https://supabase.com/dashboard y abre el proyecto.
2. **Table Editor** → pasa el mouse sobre `ast_registros` en la lista de la izquierda → **⋮** → **Export data → Export table as CSV**.
3. Repite con `ast_participantes` y `ast_perfiles`. Guarda los archivos con la fecha de hoy.
   Si no aparece «Export data»: **SQL Editor → New query**, escribe `select * from ast_registros;`, **Run**, y arriba de los resultados **Export → CSV**.

La migración también guarda su propio respaldo de `ast_perfiles` y `ast_participantes` dentro de la base (esquema `respaldo`).

### 1.2 Migración 003

1. **SQL Editor → New query**.
2. Abre `supabase/migrations/20261113000003_papelera_roles_claves.sql` con el Bloc de notas, **Ctrl + A**, **Ctrl + C**, y pégalo en Supabase.
3. Pulsa **Run**. Debe aparecer: `Migración 003 lista · columnas_clave 2 · columna_motivo 1 · ast_en_papelera 0`.

### 1.3 Verificar

1. **New query**, pega `supabase/verificacion.sql` y pulsa **Run**.
2. Supabase muestra solo el último resultado: la lista de revisión. Todas las filas deben decir **OK**.
3. Para ver los conteos, selecciona con el mouse solo la primera consulta (la que empieza con `select (select count(*)`) y pulsa **Run**: el total de AST no debe bajar (hoy son 711).

### 1.4 Variables, Edge Functions y claves

- **Variables:** la app usa solo la URL del proyecto y la clave pública, que ya están en el bloque `CONFIG` de `ast-digital.html` (ver `.env.example`). No cambian.
- **Edge Functions:** no se usan. La papelera, las claves temporales y el acceso de emergencia funcionan con funciones seguras dentro de la base, sin exponer la clave `service_role`.
- **Nunca** pegues la clave `service_role` en el HTML ni en GitHub.

### 1.5 Cuota de Supabase (aviso naranjo)

Supabase avisó que la organización superó la cuota del plan gratis el mes pasado y que restringirá el proyecto desde el **05-12-2026** si sigue así.
Lo más probable es que se haya pasado la **transferencia de datos (egress)**: cada vez que alguien abría el Dashboard, Revisión o Personal, la app descargaba todas las AST con sus imágenes de firma.
La 3.3 deja de hacerlo, así que el consumo debería bajar bastante desde que la publiques.

Para confirmarlo: **Organization → Usage** en Supabase. Si quieres ver cuánto pesan las firmas, corre en SQL Editor:

```sql
select pg_size_pretty(sum(pg_column_size(sup_firma))::bigint) as firmas_supervisor,
       pg_size_pretty(sum(pg_column_size(contenido))::bigint)  as contenido
from ast_registros;
```

---

## 2. GitHub (publicar la app)

### Opción A · Desde la página web

1. Entra a https://github.com/lcortes-planificacion/ast-digital.
2. **Respaldo:** abre `ast-digital.html` → botón de descarga (flecha hacia abajo, arriba a la derecha). Guárdalo como `ast-digital-respaldo-v3.2.html`.
3. Vuelve a la página principal → **Add file → Upload files**.
4. Arrastra desde la carpeta `ast-digital`: `ast-digital.html`, `README.md`, `CHANGELOG.md` y las carpetas `docs`, `supabase` y `pruebas`.
5. En el mensaje escribe `AST Digital 3.3`, deja marcado **Commit directly to the main branch** y pulsa **Commit changes**.
6. Espera 2 o 3 minutos. En **Actions** el último proceso debe quedar con check verde.
7. Abre la app y recarga con **Ctrl + Shift + R**. En el teléfono o en la app instalada, ciérrala del todo y ábrela de nuevo.
8. Revisa que arriba a la derecha aparezca el indicador **● Conectado**: eso confirma que estás en la 3.3.

### Opción B · Con Git (en una rama)

```bash
git clone https://github.com/lcortes-planificacion/ast-digital.git
cd ast-digital
git checkout -b version-3.3
# copia aquí el contenido de la carpeta ast-digital
git add .
git status            # revisa que no aparezca ningún archivo con claves
git commit -m "AST Digital 3.3"
git push -u origin version-3.3
```

Luego en GitHub: **Pull requests → New pull request** → `version-3.3` hacia `main` → **Merge**.

### Volver atrás si algo falla

Sube otra vez `ast-digital-respaldo-v3.2.html` con el nombre `ast-digital.html`.
La migración 003 no borra datos y la 3.2 funciona igual con ella, así que no hace falta deshacerla.

---

## 3. Probar en tu computador antes de publicar (opcional)

```bash
cd ast-digital
python -m http.server 8080
```

Abre `http://localhost:8080/ast-digital.html`. **Cuidado:** se conecta a la base real.

---

## 4. Pruebas realizadas

Todas en una copia local de Supabase con las tres migraciones, nunca en la base real. Detalle en [`docs/PRUEBAS.md`](docs/PRUEBAS.md).
Después de publicar, haz la revisión rápida del final del manual.
