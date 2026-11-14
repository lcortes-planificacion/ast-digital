# Cambios

## 3.2 · 13-11-2026

**Diseño**
- Se quitó la tarjeta grande de bienvenida del inicio.
- El inicio muestra dos tarjetas compactas: **INGRESA A TALLER SMAN** (ícono de ingreso) y **FIRMAS PENDIENTES** (ícono de firma, con la cantidad de AST esperando firma).
- Áreas del taller: se quitó «Resumen del área» (ese dato es del panel de indicadores). Cuadros más compactos: en notebook y PC caben todas las áreas sin desplazarse.
- La barra de botones ahora va abajo, a todo el ancho y fuera del contenido: ya no tapa cuadros ni campos. Al escribir, el campo sube solo si quedaría detrás de la barra.
- Se quitó «Sumitomo Drive» del inicio.

**Cuadros de la AST**
- Al crear una AST todos los cuadros parten cerrados.
- Solo un cuadro abierto a la vez (al abrir uno se cierra el anterior), también al ver una AST.
- Cada cuadro tiene una flecha visible de 36 px que gira al abrir. Un clic abre y un clic cierra.
- El estado (Pendiente, Completo, Sin firma…) queda en la misma línea del título.

**Participantes después de la firma**
- En una AST ya firmada aparece «Agregar participante». La persona queda en la **misma AST, con el mismo número**.
- Debe aceptar la declaración y firmar. Queda con fecha, hora, equipo y quién lo registró, marcado «Se incorporó después de la firma».
- Las firmas anteriores no se tocan (lo controla la base de datos, no solo la app). Queda en el historial de accesos.
- No se puede registrar dos veces el mismo RUT ni agregar personas a una AST cerrada o anulada.

**«Se envía a firma de»**
- La lista sale de las cuentas activas con permiso de firma, con el nombre tal como está en la base.
- Si una cuenta se deshabilita, desaparece de la lista; sus firmas anteriores se conservan.
- «Otros» abre un campo para escribir el nombre. No se asocia a ninguna cuenta. La AST la firma un responsable con permiso de firma y queda su nombre real.

**Contraseñas y acceso de emergencia**
- Ojo para mostrar u ocultar la contraseña en el ingreso, al crear usuarios, al cambiar la clave y en el acceso de emergencia.
- Acceso de emergencia del administrador: la clave se guarda cifrada en la base y no está en la app. Bloquea por 15 minutos después de 3 intentos fallidos por equipo (6 en total) y registra cada intento. Sirve para recuperar o crear una cuenta de administrador con contraseña personal. No sirve para iniciar sesión directo.
- El administrador puede cambiar la clave de emergencia desde Usuarios.
- Se desactivaron el PIN por fecha y la clave de respaldo de la versión 2, que estaban en el navegador.

**Base de datos (migración 002)**
- Respaldo automático de participantes antes de modificar la tabla.
- 5 columnas nuevas en participantes. No se borra ni se renumera nada.
- Se eliminan las claves antiguas guardadas en la configuración pública.

## 3.1
Seguridad con Supabase Auth y reglas RLS, cuentas personales, matriz de permisos, dispositivos, correlativo asignado por la base.

## 3.0
Correlativo, archivo histórico, firmas digitales, flujo de aprobación, diseño azul oscuro.
