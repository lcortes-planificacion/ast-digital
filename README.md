# AST DIGITAL · SM Cyclo de Chile Ltda. · Taller SMAN

Versión **3.2**. Aplicación web para crear, firmar y archivar el Análisis Seguro de Trabajo (AST) del taller.

- Publicada en GitHub Pages: `https://lcortes-planificacion.github.io/ast-digital/ast-digital.html`
- Datos e inicio de sesión: Supabase (base de datos, reglas de seguridad RLS y Supabase Auth)

> **Ojo:** mientras no subas esta versión a GitHub, la app publicada sigue siendo la **2.1**.
> Por eso hoy la lista «Se envía a firma de» aparece vacía: esa versión no conoce las cuentas nuevas.

---

## Qué hay en esta carpeta

| Archivo | Para qué |
|---|---|
| `ast-digital.html` | La app completa (un solo archivo). |
| `index.html` | Redirige a `ast-digital.html`. |
| `supabase/migrations/…001_seguridad.sql` | Migración 001: cuentas, permisos, RLS, correlativo. **Plantilla sin claves.** |
| `supabase/migrations/…002_participantes_emergencia.sql` | Migración 002: participantes después de la firma y acceso de emergencia. **Plantilla sin claves.** |
| `supabase/verificacion.sql` | Revisión de solo lectura para después de migrar. |
| `.env.example` | Lista de configuraciones (sin valores reales). |
| `docs/MANUAL.md` | Manual de uso con capturas. |
| `docs/PRUEBAS.md` | Resultado de las 148 pruebas. |
| `CHANGELOG.md` | Lista de cambios. |
| `pruebas/` | Scripts de prueba (solo para una base de prueba). |

Los SQL **listos para pegar**, con las claves reales, vienen aparte en la carpeta `NO_SUBIR_A_GITHUB`.
El repositorio es público (GitHub Pages), así que esa carpeta nunca se sube.

### Por qué es un solo archivo HTML

La app está hecha en un solo HTML con JavaScript, sin React ni TypeScript, y sin compilador.
Se mantuvo así a propósito: rehacerla habría puesto en riesgo lo que ya funciona.
Tampoco necesita `npm install` para funcionar.

---

## Orden de instalación (importante)

1. Respaldo en Supabase.
2. Migración 001 (si ya la corriste en la 3.1, se puede correr otra vez sin problema).
3. Migración 002.
4. Verificación.
5. Recién ahí, subir `ast-digital.html` a GitHub.

Si subes la app antes de migrar, la 3.2 no podrá iniciar sesión, porque necesita las cuentas de la migración 001.

---

## 1. Supabase

### 1.1 Respaldo antes de tocar nada

1. Entra a https://supabase.com/dashboard y abre el proyecto de AST Digital.
2. **Database → Backups**. Si tu plan tiene respaldos diarios, revisa que exista el de hoy.
3. Además, saca una copia propia: **Table Editor** → abre `ast_registros` → botón **Export → Export table as CSV**. Repite con `ast_participantes` y `ast_config`.
4. Guarda los 3 CSV en tu computador con la fecha de hoy.
5. Anota los conteos de hoy. En **SQL Editor → New query** pega esto y pulsa **Run**:

   ```sql
   select (select count(*) from ast_registros) ast, (select count(*) from ast_participantes) participantes;
   ```

Las migraciones también hacen su propio respaldo dentro de la base (esquema `respaldo`), pero no reemplazan tu copia.

### 1.2 Migración 001 (seguridad)

1. Abre **SQL Editor → New query**.
2. Abre en tu computador `NO_SUBIR_A_GITHUB/1_migracion_001_seguridad_LISTA.sql`, copia todo y pégalo.
3. Pulsa **Run**. Al final debe aparecer una fila que dice que la migración quedó lista.
4. Si ya la habías corrido en la 3.1, no pasa nada: no duplica cuentas ni cambia contraseñas ya cambiadas.

### 1.3 Migración 002 (participantes y emergencia)

1. **New query** otra vez.
2. Pega `NO_SUBIR_A_GITHUB/2_migracion_002_participantes_emergencia_LISTA.sql` y pulsa **Run**.
3. Debe aparecer: `Migración 002 lista · columnas_nuevas 5 · clave_emergencia_configurada 1`.

### 1.4 Verificar

1. **New query**, pega `supabase/verificacion.sql` y pulsa **Run**.
2. Todas las filas deben decir **OK**.
3. En la segunda tabla, compara los conteos con los que anotaste en el paso 1.1. No deben bajar.
4. Revisa **Authentication → Providers → Email**: debe estar activado. Las cuentas usan correos internos `usuario@ast-sman.local`; no se envían correos.

### 1.5 Variables, Edge Functions y claves

- **Variables:** la app solo necesita la URL del proyecto y la clave pública. Ya están en el bloque `CONFIG` de `ast-digital.html` y no cambian. Si algún día cambias de proyecto, edita esas dos líneas (ver `.env.example`).
- **Edge Functions:** esta versión **no usa** Edge Functions. El acceso de emergencia funciona con una función segura dentro de la base de datos. La clave queda cifrada (bcrypt), no se puede leer desde la app y cada intento queda registrado. Así no hace falta exponer la clave `service_role`.
- **Nunca** copies la clave `service_role` en el HTML ni en GitHub.

---

## 2. GitHub (publicar la app)

### Opción A · Desde la página web (la más simple)

1. Entra a https://github.com/lcortes-planificacion/ast-digital.
2. **Respaldo:** abre `ast-digital.html` → botón **⋯ → Download** (o «Download raw file»). Guárdalo como `ast-digital-respaldo-v2.1.html`.
3. Vuelve a la página principal del repositorio → **Add file → Upload files**.
4. Arrastra estos archivos y carpetas desde la carpeta `ast-digital` (no la carpeta `NO_SUBIR_A_GITHUB`):
   `ast-digital.html`, `README.md`, `CHANGELOG.md`, `.env.example`, `.gitignore`, `docs/`, `supabase/`, `pruebas/`.
   Al subir `ast-digital.html` se reemplaza el anterior. `index.html` no cambió, no hace falta subirlo.
   (`.gitignore` y `.env.example` empiezan con punto: si tu computador no los muestra, puedes omitirlos.)
5. Abajo, en **Commit changes**, escribe: `AST Digital 3.2`.
6. Marca **Commit directly to the main branch** y pulsa **Commit changes**.
7. Espera 1 a 3 minutos. Revisa en **Actions** que el despliegue de Pages termine en verde.
8. Abre la app, recarga con **Ctrl + Shift + R** (en el teléfono, cierra y vuelve a abrir) y revisa que el inicio muestre las dos tarjetas compactas (INGRESA A TALLER SMAN y FIRMAS PENDIENTES) en vez de la tarjeta grande de bienvenida.

### Opción B · Con Git (en una rama, para revisar antes)

```bash
git clone https://github.com/lcortes-planificacion/ast-digital.git
cd ast-digital
git checkout -b version-3.2
# copia aquí el contenido de la carpeta ast-digital (no NO_SUBIR_A_GITHUB)
git add .
git status            # revisa que no aparezca ningún archivo *_LISTA.sql ni claves_temporales.txt
git commit -m "AST Digital 3.2"
git push -u origin version-3.2
```

Luego en GitHub: **Pull requests → New pull request** → `version-3.2` hacia `main` → **Merge**.
GitHub Pages publica lo que queda en `main`.

### Volver atrás si algo falla

Sube otra vez el respaldo `ast-digital-respaldo-v2.1.html` con el nombre `ast-digital.html`.
Las migraciones no borran datos, así que no hace falta deshacerlas.

---

## 3. Probar en tu computador antes de publicar (opcional)

Necesitas Python (viene en Mac y Linux; en Windows se instala desde python.org).

```bash
cd ast-digital
python -m http.server 8080
```

Abre `http://localhost:8080/ast-digital.html`.
**Cuidado:** esta copia local se conecta a la base real. Lo que hagas ahí queda guardado de verdad.

---

## 4. Primer ingreso después de migrar

1. Cada persona entra con su usuario y la clave temporal de `claves_temporales.txt` (entrégalas en persona). La app obliga a cambiarla.
2. El taller sigue entrando sin clave, con **INGRESAR A TALLER SMAN** y registrando el equipo.
3. Si pierdes el acceso de administración: en la pantalla de ingreso toca **Acceso de emergencia del administrador**.
4. Cambia la clave de emergencia apenas puedas: **Usuarios → Clave de emergencia**.

---

## 5. Pruebas realizadas

148 de 148 pruebas correctas, en una copia local de Supabase. El detalle está en [`docs/PRUEBAS.md`](docs/PRUEBAS.md).
Después de publicar, haz la revisión rápida del final del manual en la base real.
