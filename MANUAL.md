# Manual de uso · AST DIGITAL 3.3

Taller SMAN · SM Cyclo de Chile Ltda.

---

## 1. Lo nuevo en la 3.3, en corto

- Arriba a la derecha hay un **indicador de conexión**: Conectado, Sincronizando, Desconectado o Error de conexión.
- Sin conexión, la app muestra los **datos guardados en el equipo** en vez de una pantalla vacía.
- El **menú** es más corto y va en orden de uso. «AST registradas» está ahí.
- **Volver** regresa por el mismo camino que hiciste, con tus filtros y la posición de la pantalla.
- El administrador puede **eliminar** una AST: queda en la **papelera** y se puede recuperar.
- Quien se suma a una AST ya firmada indica el **motivo**.
- Las **claves temporales** vencen en 7 días y se ven en Usuarios.

---

## 2. La conexión

El indicador de arriba dice cómo está la conexión con la nube:

| Indicador | Qué significa |
|---|---|
| ● Conectado (verde) | Todo normal. |
| ● Sincronizando (azul) | La app está trayendo o enviando datos. Espera un momento. |
| ● Desconectado (gris) | Este equipo no tiene internet. |
| ● Error de conexión (rojo) | Hay internet, pero la nube no responde. |

Si se corta la conexión:

- Aparece un aviso abajo con **Reintentar** y **Detalle**. Detalle explica qué pasa y muestra las últimas consultas.
- Las listas, el dashboard y el archivo se siguen viendo con los **datos guardados en este equipo**, con la fecha y hora en que se guardaron.
- Lo que registres queda guardado en el equipo y se envía solo cuando vuelva la conexión. El supervisor no lo ve hasta entonces.
- La app prueba la conexión sola cada 15 segundos.

![Sin conexión: datos guardados y aviso](img/sin_conexion.png)

---

## 3. Taller: crear la AST del día

### 3.1 Entrar

1. Escanea el código QR del taller o abre el enlace de la app.
2. Toca **INGRESAR A TALLER SMAN**.
3. La primera vez en ese teléfono escribe tu nombre, RUT y cargo, y toca **Continuar**.

![Inicio del taller](img/m_inicio_taller.png)

### 3.2 Elegir el área y llenar la AST

1. Toca **INGRESA A TALLER SMAN** y luego tu área.
2. Al crear la AST todos los cuadros parten cerrados. Toca uno para abrirlo; al abrir otro, el anterior se cierra solo.
3. En **Antecedentes generales**, en «Se envía a firma de», elige quién debe autorizar. Si no está en la lista, elige **Otros** y escribe el nombre.
4. Responde los pasos 1 a 5, firma en «Firma del colaborador» y toca **Enviar a firma**.

![Áreas del taller](img/m_areas.png)
![Formulario con los cuadros cerrados](img/m_form_cerrado.png)

---

## 4. Supervisión: firmar

1. Entra con tu usuario y contraseña. El **ojo** muestra u oculta la contraseña.
2. En el inicio toca **FIRMAS PENDIENTES**.
3. Revisa la AST, firma y toca **Firmar y autorizar**. La AST recibe su número oficial.

El inicio muestra además **Hoy en el taller**: autorizadas, esperando firma, en llenado y cerradas. Al tocar una cifra se abren las AST de hoy.

![Inicio con sesión](img/inicio_sup.png)

---

## 5. Agregar a alguien después de la firma

1. Abre la AST de la línea y toca **Agregar participante**.
2. Escribe nombre y RUT, y elige el **motivo de incorporación** (llegó después de la charla, apoyo a la tarea, reemplazo, cambio de turno u otro).
3. Marca **Acepto la declaración**, firma y toca **Firmar e incorporarme**.

Queda en la **misma AST, con el mismo número**. Solo firma la persona nueva: nadie más tiene que volver a firmar. En la lista aparece «Se incorporó después de la firma», con fecha, hora, quién lo registró y el motivo.

![Agregar participante](img/m_participante.png)

---

## 6. El menú

Toca las tres líneas de arriba a la izquierda.

- **Trabajo diario:** Inicio · Nueva AST · Firmas pendientes · AST registradas · Archivo histórico · RAN TALLER
- **Control:** Dashboard · Revisión de AST · Personal registrado
- **Administración** (se abre al tocarla): Usuarios y accesos · Papelera de AST · Configuración
- **Mi cuenta:** Mi cuenta y contraseña

Para cerrar sesión usa el botón rojo de arriba a la derecha. Cada persona ve solo lo que su perfil permite.

![Menú](img/menu.png)

**AST registradas** muestra todas las AST del período con su estado, con buscador y filtros. **Configuración** reúne en una sola pantalla las áreas, formularios, catálogos y ajustes.

![AST registradas en el teléfono](img/m_registradas.png)
![Configuración](img/configuracion.png)

---

## 7. Volver

El botón **Volver** de arriba regresa por el mismo camino que hiciste. Por ejemplo:

Inicio → Nueva AST → Ensamble → Línea 1 → Agregar participante

Al tocar **Volver** cuatro veces: Línea 1 → Ensamble → Nueva AST → Inicio.

Al volver a una lista, quedan los mismos filtros y la misma posición. El botón atrás del teléfono o del navegador hace lo mismo.

---

## 8. Administración

### 8.1 Eliminar y recuperar una AST

1. Abre la AST. Al final aparece **Administración de esta AST** (solo para el administrador).
2. Toca **Eliminar (enviar a la papelera)** y escribe el motivo. Es obligatorio.
3. La AST sale de todas las listas y del dashboard.

Para recuperarla: **Menú → Administración → Papelera de AST → Recuperar**. Vuelve tal como estaba.

Nada se borra de verdad: la AST conserva su número, sus firmas y sus participantes. Quedan registrados el motivo, quién la eliminó y cuándo. El número nunca se vuelve a usar.

![Papelera](img/papelera.png)

### 8.2 Usuarios, perfiles y claves temporales

**Menú → Administración → Usuarios y accesos.** Las pestañas de arriba llevan a Matriz de permisos, Firmas digitales, Dispositivos e Historial de accesos.

Perfiles:

| Perfil | Qué puede hacer |
|---|---|
| Administrador | Todo, incluidos usuarios, configuración y papelera. |
| Supervisor | Firmar AST, editar las del día y ver el histórico. |
| Planificador | Ver AST, histórico, dashboard y revisión. No firma ni crea. |
| Usuario estándar (taller) | Crear la AST del día y registrarse como participante. |
| Visitante | Solo mirar las AST, el histórico y el dashboard. |

También siguen Gerencia, Calidad, Prevención de Riesgos y Administrador de taller. Los permisos de cada persona se pueden ajustar en la Matriz de permisos.

Claves temporales:

- Cada cuenta con clave temporal muestra cuándo se creó y cuándo vence (7 días).
- **Generar clave temporal** crea una nueva y la muestra **una sola vez**, con botón Copiar. La app no la guarda: anótala o cópiala y entrégala en persona.
- Si la clave vence sin usarse, la persona no puede entrar hasta que generes otra.
- Las contraseñas deben tener al menos 8 caracteres, con letras y números.

![Clave temporal: se muestra una sola vez](img/clave_una_vez.png)
![Clave temporal vencida](img/m_clave_vencida.png)

### 8.3 Acceso de emergencia del administrador

En la pantalla de ingreso: **Acceso de emergencia del administrador**. Escribe la clave de emergencia, tu usuario y una contraseña nueva. Después de 3 intentos fallidos, ese equipo queda bloqueado 15 minutos. Cada intento queda registrado.

---

## 9. Revisión rápida después de publicar

1. [ ] Arriba a la derecha dice **● Conectado**.
2. [ ] Dashboard, Archivo histórico, AST registradas, RAN TALLER y Revisión de AST cargan sin el error de conexión.
3. [ ] El menú tiene las secciones Trabajo diario, Control, Administración y Mi cuenta.
4. [ ] Abrir una AST desde AST registradas y tocar Volver: vuelve a la lista en el mismo lugar.
5. [ ] Eliminar una AST de prueba con motivo, verla en la Papelera y recuperarla.
6. [ ] Agregar un participante a una AST firmada: pide el motivo y el número no cambia.
7. [ ] En Usuarios se ve quién tiene clave temporal y cuándo vence.
