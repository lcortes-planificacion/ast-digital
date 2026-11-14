# Resultados de las pruebas · AST DIGITAL 3.2

Fecha: 13-11-2026. Todas las pruebas se corrieron contra una **copia local de Supabase**
(PostgreSQL + PostgREST + inicio de sesión), con las dos migraciones aplicadas, y la app 3.2 abierta en Chromium.
No se tocó la base real.

| Grupo | Resultado |
|---|---|
| Recorrido completo en la app (teléfono, PC, notebook, tablet, monitor) | 66/66 |
| Seguridad de la base (permisos, bloqueos, firmas, correlativos) | 55/55 |
| Migración 002 (participantes después de la firma, «Otros», acceso de emergencia) | 27/27 |

**Importante:** estas pruebas no reemplazan una revisión en la base real después de correr las migraciones.
Para eso usa `supabase/verificacion.sql` y la lista de revisión del README.

## 1. Recorrido completo en la app

✅ Portada sin «Sumitomo Drive» suelto
✅ Inicio sin la tarjeta grande de bienvenida
✅ Dos tarjetas compactas: INGRESA A TALLER SMAN y FIRMAS PENDIENTES
✅ Las tarjetas tienen ícono
✅ FIRMAS PENDIENTES muestra la cantidad (0)
✅ Tarjetas compactas (alto < 110 px)
✅ Áreas: 11 cuadros
✅ Áreas: sin «Resumen del área»
✅ Áreas: ningún botón tapa los cuadros
✅ Áreas: sin desplazamiento horizontal
✅ Áreas: botón Volver visible
✅ Formulario nuevo: todos los cuadros cerrados (9 cuadros)
✅ Cada cuadro tiene su flecha visible de 30 px o más
✅ Un clic abre el cuadro
✅ La flecha queda girada y se avisa abierto (aria-expanded)
✅ Un clic en la flecha lo cierra
✅ Solo un cuadro abierto a la vez (abrió Paso 2, se cerró Paso 1)
✅ El campo que se escribe no queda detrás de los botones
✅ «Se envía a firma de»: nombres de la base + Otros (Alexis Núñez, Luis Cortés, Bryan Mendoza, Richard Williams, Maybeth Prado, Francisco Yáñez, Bernardo Pérez, Jazmin Villarroel, Otros)
✅ «Otros» abre un campo de texto para escribir el nombre
✅ Al elegir un nombre de la lista se oculta el campo de texto
✅ Abrir otros pasos no borra la firma
✅ Barra de botones abajo, sin «Volver» encima del formulario
✅ Formulario sin desplazamiento horizontal
✅ AST enviada a firma
✅ AST enviada a «Otros»: nombre escrito, sin cuenta asociada (Juan Externo Contratista)
✅ Login: la contraseña tiene el ojo para mostrar/ocultar
✅ El ojo muestra la contraseña
✅ El ojo la vuelve a ocultar
✅ Login: enlace de acceso de emergencia
✅ Supervisor entra y cambia la clave temporal (con ojo en los 3 campos)
✅ Inicio con sesión: sin tarjeta grande, con tarjetas compactas y buscador
✅ Firma del supervisor guardada (Bryan Mendoza 00:22)
✅ Ver AST: cuadros cerrados al abrir (9)
✅ Ver AST: acordeón exclusivo
✅ Número correlativo asignado al firmar (5)
✅ AST de «Otros» la firma un responsable autorizado y queda su nombre real (Bryan Mendoza, N° 6)
✅ El taller ve la AST firmada con su número
✅ Botón «Agregar participante» en la AST firmada
✅ Aparece la declaración exacta
✅ Sin aceptar la declaración no deja registrar
✅ Participante agregado a la misma AST, marcado después de la firma
✅ Queda fecha, hora y quién lo registró (Juan Pérez)
✅ Se conserva el número correlativo
✅ No se alteran las firmas previas
✅ No se creó una AST nueva (1)
✅ La lista de participantes lo muestra como incorporado después de la firma
✅ Sin errores JS (taller)
✅ Administración de usuarios
✅ Barra de usuarios: Nuevo usuario y Clave de emergencia
✅ Crear usuario: la contraseña temporal tiene ojo
✅ Crea un usuario
✅ Usuario deshabilitado desaparece de «Se envía a firma de»
✅ Su firma histórica se conserva en la AST
✅ En el teléfono del taller, la lista ya no muestra al deshabilitado (10 opciones)
✅ Historial: participante agregado después de la firma
✅ Sin errores JS (supervisor y administrador)
✅ Pantalla de emergencia: clave y contraseñas con ojo
✅ La clave no está en el código de la app
✅ Clave equivocada: rechazada y sigue sin sesión
✅ Clave correcta: entra como administrador con su contraseña nueva
✅ Sin errores JS (emergencia)
✅ pc: áreas sin desplazamiento horizontal, sin botones encima y sin scroll vertical
✅ notebook: áreas sin desplazamiento horizontal, sin botones encima y sin scroll vertical
✅ tablet: áreas sin desplazamiento horizontal, sin botones encima y sin scroll vertical
✅ monitor: áreas sin desplazamiento horizontal, sin botones encima y sin scroll vertical

## 2. Seguridad de la base


**Taller sin cuenta**

✅ Sin dispositivo registrado no ve ninguna AST
✅ Registra su dispositivo
✅ Ve solo las AST del día (['hoy1'])
✅ Consulta directa al historial devuelve vacío
✅ Pedir una AST histórica por su id devuelve vacío
✅ Participantes: solo los de AST del día
✅ No ve los números del historial
✅ Crea una AST del día
✅ No puede crear AST con fecha antigua
✅ No puede crear una AST ya firmada
✅ No puede firmar (aunque mande la firma directo)
✅ No puede modificar una AST enviada a firma
✅ No puede eliminar AST
✅ No puede tocar una AST histórica
✅ No ve las cuentas de usuarios
✅ No ve la auditoría
✅ No ve las firmas registradas
✅ De la configuración solo ve la general
✅ No puede cambiar la configuración
✅ No puede crear un administrador
✅ La función interna de creación no se puede llamar
✅ No puede inventar un número oficial
✅ Lista de firmantes: 8 nombres en orden

**Cuentas**

✅ Ingreso con usuario y contraseña
✅ Contraseña equivocada no entra
✅ Perfil y permisos vienen de la base (supervisor)
✅ Un supervisor no puede cambiarse el rol
✅ Un supervisor no puede usar las funciones de administración
✅ Supervisor ve el historial (7)
✅ Otro supervisor no puede firmar una AST asignada a Bryan
✅ Otro supervisor no puede devolver una AST asignada a Bryan
✅ Bryan firma su AST
✅ El nombre del firmante lo pone la base, no el navegador (Bryan Mendoza)
✅ La base asigna el número oficial (5)
✅ Firma con fecha, hora y cuenta registradas por la base
✅ Ni el administrador puede modificar una AST firmada
✅ Ni el administrador puede quitar una firma
✅ Ni el administrador puede eliminar una AST
✅ Se puede agregar una nota de corrección
✅ Una nota ya escrita no se puede cambiar
✅ Nueva versión firmada: mismo número, Rev.1

**Número oficial con firmas simultáneas**

✅ 20 firmas al mismo tiempo: 20 números distintos y seguidos

**Desactivar cuentas y bloquear dispositivos**

✅ Administrador deshabilita a Richard
✅ Con la sesión que ya tenía abierta no ve nada
✅ Ya no puede iniciar sesión
✅ Deja de aparecer en «Se envía a firma de»
✅ Sus firmas anteriores siguen en el historial
✅ Administrador bloquea el teléfono de Juan
✅ El teléfono bloqueado ya no ve AST
✅ Ni puede crear AST
✅ El administrador no se puede deshabilitar a sí mismo

**Perfiles nuevos**

✅ Administrador crea cuentas de Calidad y de Personal de taller
✅ Personal de taller con cuenta tampoco ve el historial
✅ Calidad no puede agregar notas (solo lectura del historial)
✅ La auditoría registra firmas, accesos y bloqueos

## 3. Migración 002


**Participantes después de la firma**

✅ La clave antigua ya no está en la configuración pública
✅ AST de hoy firmada con número 5
✅ Se agrega un participante a la AST ya firmada
✅ Queda marcado «después de la firma», con hora y quién lo registró (Pedro Rojas)
✅ El número y la firma original no cambian
✅ No se creó otra AST
✅ No se puede registrar dos veces la misma persona
✅ Sin firma no se registra
✅ Sin aceptar la declaración no se registra
✅ Un participante no se puede modificar
✅ No se agregan participantes a una AST cerrada
✅ Auditoría: «Agregó un participante después de la firma»

**«Otros»**

✅ Se envía a un nombre escrito (sin cuenta)
✅ Un responsable autorizado la firma y queda su nombre real (Bryan Mendoza)
✅ El taller sigue sin poder firmar una AST dirigida a «Otros»
✅ Nadie puede reemplazar la firma de una AST firmada

**Acceso de emergencia**

✅ La clave de emergencia no se puede leer ni siquiera como administrador
✅ Clave equivocada: rechazada
✅ No sirve para tomar una cuenta que no es de administrador
✅ Clave correcta: recupera la cuenta del administrador
✅ Entra con su nueva contraseña personal
✅ La clave de emergencia no sirve para iniciar sesión
✅ Puede crear una cuenta de administrador nueva
✅ Después de 3 intentos fallidos el equipo queda bloqueado 15 minutos (incluso con la clave correcta)
✅ Cada uso queda en el historial (correcto, fallido y bloqueo)
✅ Un supervisor no puede cambiar la clave de emergencia
✅ El administrador puede cambiarla

## Cómo repetir las pruebas

Los scripts están en `pruebas/`. Necesitan una base de prueba (nunca la real):
`t32.js` (Playwright, recorrido en pantalla), `prueba_rls.py` (seguridad), `prueba_m002.py` (migración 002).
La clave de emergencia de prueba se entrega por la variable `CLAVE_EMERGENCIA_PRUEBA`; no va escrita en los archivos.
