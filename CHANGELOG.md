# Cambios

## 3.3 · 13-11-2026

**Conexión (la falla del Dashboard y el Archivo histórico)**
- Causa: el Dashboard, Revisión, Personal y «AST guardadas» descargaban todas las AST completas, con las imágenes de firma (varios MB por consulta). La app cortaba la espera a los 7 segundos y lo mostraba como «Sin conexión con la nube». Esas descargas también gastan la cuota de transferencia de Supabase.
- Ahora las listas e indicadores piden solo las columnas que usan, nunca las firmas. Las listas largas se piden de a 250 filas.
- Espera de 30 segundos para leer y 20 para guardar.
- Mensajes claros según el problema: sin internet en el equipo, la nube tardó demasiado, no se pudo llegar a Supabase, error del servidor o proyecto restringido por cuota.
- Indicador arriba: Conectado · Sincronizando · Desconectado · Error de conexión. Al tocarlo muestra el detalle y las últimas consultas.
- Reconexión automática cada 15 segundos y al volver la red.
- Sin conexión se ven los datos guardados en el equipo (con fecha y hora), en vez de una pantalla vacía.
- El aviso de conexión ya no se deforma ni tapa los botones.

**Menú lateral**
- De 24 opciones a 13 para el administrador, en orden de uso: Trabajo diario · Control · Administración (plegada) · Mi cuenta.
- «AST registradas» sale del inicio y pasa al menú. «AST guardadas» se unió con ella (mostraban lo mismo).
- Las 8 pantallas de configuración quedan juntas en «Configuración».
- Se quitaron del menú las «Acciones de esta pantalla» (repetían la barra de abajo) y el «Cerrar sesión» repetido (queda el botón de arriba).

**Navegación**
- «Volver» regresa por el camino que hiciste, con los filtros y la posición de la pantalla.
- El botón atrás del navegador o del teléfono hace lo mismo que «Volver».
- Las barras de abajo ya no repiten «Volver» ni «Inicio».

**Inicio**
- Tarjetas INGRESA A TALLER SMAN y FIRMAS PENDIENTES, más un resumen de hoy (autorizadas, esperando firma, en llenado, cerradas).

**Administración de AST**
- El administrador puede eliminar cualquier AST con motivo obligatorio. No se borra: va a la papelera con su número, sus firmas, el motivo, quién y cuándo. Se puede recuperar. El número nunca se reutiliza.
- Nuevos perfiles: Planificador (ve todo, no firma ni crea) y Visitante (solo lectura). «Personal de taller» se llama ahora «Usuario estándar (taller)».

**Participantes después de la firma**
- Se pide el motivo de incorporación. Queda en la base, en la lista de participantes y en el historial.

**Claves temporales**
- Usuarios muestra quién tiene clave temporal, cuándo se creó y cuándo vence (7 días).
- «Generar clave temporal» muestra la clave una sola vez, con botón Copiar. La app no la guarda.
- Una clave temporal vencida no da acceso a nada hasta que el administrador genere otra.
- Contraseñas con al menos 8 caracteres, letras y números.

**Base de datos (migración 003)**
- Papelera, perfiles nuevos, motivo, vencimiento de claves.
- Los permisos se calculan una vez por consulta y no una vez por fila (más rápido, mismo resultado).
- Respaldo automático de cuentas y participantes antes de modificar. No borra datos.

**Corrección**
- Las AST antiguas dirigidas a un supervisor de la lista ya no aparecen como «(Otros)».

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
