<<<<<<< HEAD
# Preguntas y reportes — Sistema de donaciones (SF Vibe Lab / Mexico Dreamin)

Cada entrada sigue las cinco partes de un buen reporte, más un campo "Después" para registrar qué se hizo con la respuesta y si se resolvió.

- **Contexto:** preguntas del equipo al cliente, enviadas por Slack
- **Quién preguntó:** Daniel Salvador Amaya Tapia y Fernando Joachín Prieto (en nombre del equipo)
- **Fecha de las preguntas:** 2026-11-03, 14:17
- **Autor del documento:** Equipo 3

---

## Entrada 1 — ¿A qué se refiere "sin login"? ¿Registro de donantes a través de un token?

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** definir si el donante podría entrar a una página de registro mediante token o si se deseaba que el donante fuera directo a un formulario de donación (criterio: que el requisito "sin login" quede sin ambigüedad).
2. **Qué hicieron:** leyeron el requisito "sin login" del documento de contexto y lo contrastaron con el flujo que ya tenían (registro por token). Luego preguntaron al cliente.
3. **Qué esperaban que pasara:** que el cliente confirmara que la página de registro a traves de un token es aceptable o si debía eliminarse.
4. **Qué pasó:** el cliente respondió que cualquier visitante del sitio debe poder donar. Dijo que no entiende qué significa "registro con token".
5. **Qué consultaron con la IA o la documentación y qué resultó:** Lineamientos del Proyecto de Donaciones para México Dreamin
- **Después:** el 2026-11-04 se aclaró que el token se elimina y el donante se identifica solo con su correo. La vista de registro nose conserva como paso del proceso y se unifico con el formulario de donación. **Resuelto.**

## Entrada 2 — ¿Cómo funcionan las múltiples campañas?

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** decidir la estructura del sitio: un solo sitio con todas las campañas activas, o un sitio/página independiente por campaña con su propio enlace.
2. **Qué hicieron:** plantearon las dos opciones al cliente.
3. **Qué esperaban que pasara:** que el cliente eligiera una de las dos.
4. **Qué pasó:** el cliente no estaba seguro. Al final se aclaró que a visión general es tener **un solo sitio concentrador** que liste las distintas campañas o causas activas (como la de *Mexico Dreamin* u otros eventos) para que el donante elija a cuál aportar. Sin embargo, se hizo hincapié en aplicar el principio de **MVP (Producto Mínimo Viable)** y simplicidad: si por tiempo se les complica, pueden definir y negociar que la primera entrega cubra solo una campaña activa.

5. **Qué consultaron con la IA o la documentación y qué resultó:** Lineamientos del Proyecto de Donaciones para México Dreamin
- **Después:** se definió un sitio central con varias campañas que lleva al proceso de donación. Flujo: sitio central → elegir campaña → presentación de la campaña → Donar → registro → donación y pasarela → agradecimiento con acceso al muro. **Resuelto.**

## Entrada 3 — ¿Cuál debería ser el monto mínimo de donación? (¿$50?)

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** fijar un monto mínimo de donación para validarlo en el formulario.
2. **Qué hicieron:** propusieron $50 como referencia.
3. **Qué esperaban que pasara:** que el cliente confirmara o corrigiera el monto.
4. **Qué pasó:** el cliente no dio un número. Dijo que el mínimo posible es lo que permita la pasarela de pago y pidió que el equipo lo investigue en la documentación de la pasarela.
5. **Qué consultaron con la IA o la documentación y qué resultó:** debe revisarse la documentación de la pasarela. 
- **Después:** **[Pendiente]** Por mientras se maneja con un monto mínimo de 50 pesos.

## Entrada 4 — ¿Qué información se le pide al usuario para donar?

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** definir los campos del formulario de donación.
2. **Qué hicieron:** preguntaron cuáles datos pedir.
3. **Qué esperaban que pasara:** recibir una lista de campos obligatorios.
4. **Qué pasó:** el cliente dijo que depende del tipo de donación elegido, pero lo mínimo es el correo y nombre del donante. Además de la información mínima necesaria para enviar la factura.
5. **Qué consultaron con la IA o la documentación y qué resultó:** Lineamientos del Proyecto de Donaciones para México Dreamin
- **Después:** el proyecto ya maneja modalidades (Privada = anónima, Pública = con crédito, representación de empresa = con factura). Por lo tanto, se modifico el formulario para solicitar los datos minimos del donante. Sin embargo, falta confirmar los datos mínimos de facturación. **[Pendiente]**

## Entrada 5 — ¿Envío de comprobante a qué se refiere? (ticket de Stripe o comprobante personalizado)

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** saber si basta el ticket de Stripe o si se debe generar un comprobante propio.
2. **Qué hicieron:** plantearon ambas opciones.
3. **Qué esperaban que pasara:** que el cliente eligiera una.
4. **Qué pasó:** el cliente dijo que si la pasarela de pago elegida ya genera y envía automáticamente el recibo o ticket por correo electrónico al donante, no es necesario enviar un segundo comprobante personalizado.
5. **Qué consultaron con la IA o la documentación y qué resultó:** Lineamientos del Proyecto de Donaciones para México Dreamin
- **Después:** el 2026-11-07, según Leo, el comprobante lo puede dar Stripe. Al completarse el pago se envía un correo al donante. 

## Entrada 6 — ¿Las facturas aplican solo para empresas? ¿Se podrá facturar?

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** delimitar si la facturación es solo para empresas y si entra en el alcance.
2. **Qué hicieron:** preguntaron al cliente.
3. **Qué esperaban que pasara:** una confirmación de alcance (empresas vs. personas).
4. **Qué pasó:** el cliente confirmó que las deducciones de impuestos están en el alcance. Cualquiera que pida la factura correspondiente debe recibirla.
5. **Qué consultaron con la IA o la documentación y qué resultó:** Lineamientos del Proyecto de Donaciones para México Dreamin
- **Después:** Se va implementar que tanto una persona moral como una física puede solicitar una factura.

## Entrada 7 — RF-S3: ¿debe existir el flujo de confirmación manual? ¿Hay un botón para confirmar?

- **Autor:** Daniel Salvador Amaya Tapia · **Fecha:** 2026-11-03 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** aclarar el requisito RF-S3.
2. **Qué hicieron:** citaron RF-S3 y preguntaron por el flujo.
3. **Qué esperaban que pasara:** que el cliente confirmara el comportamiento esperado y si era necesario.
4. **Qué pasó:** el cliente respondió a confirmación de pagos es responsabilidad de la pasarela y no del staff a mano. Salvo que quisieran contemplar transferencias bancarias o depósitos directos fuera de pasarela de pago (lo cual quedó fuera del alcance obligatorio), ese flujo manual no se debe implementar en el MVP
5. **Qué consultaron con la IA o la documentación y qué resultó:** Lineamientos del Proyecto de Donaciones para México Dreamin
- **Después:** Se descarto esa historia de usuario.

## Entrada 8 — ¿Qué es el "registro de preguntas y reportes" y qué debe contener?

- **Autor:** Fernando Joachin · **Fecha:** 2026-11-09, 21:40  **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** entender qué es el registro de preguntas y reportes, para qué sirve y qué debe incluir, para poder entregarlo bien.
2. **Qué hicieron:** buscaron información sobre ese registro y no la encontraron. Entonces preguntaron a Maliachi en Slack.
3. **Qué esperaban que pasara:** que se les aclarara el propósito y el contenido del entregable.
4. **Qué pasó:** Maliachi respondió que la última sección del documento trata justo de eso. Explicó que el reporte cubre cada vez que alguien del equipo preguntó algo en cualquier lugar. El entregable le sirve para saber cómo pensaban resolver los bloqueos que tuvieron en el camino.
5. **Qué consultaron con la IA o la documentación y qué resultó:** Revisar los Lineamientos del Proyecto de Donaciones para México Dreamin (no encontraron el registro). La respuesta llevó a la sección 12 ("Cómo pedir ayuda") y a este documento. **Resuelto.**
- **Después:** se creó este documento con una entrada por cada pregunta, con autor, fecha y las cinco partes de la sección 12.

## Entrada 9 — ¿Se puede invitar a la persona al proyecto de Jira en lugar de dar un enlace al tablero en el README?

- **Autor:** Fernando Joachin · **Fecha:** 2026-11-09, 21:40  **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** cumplir el requisito de dar acceso al tablero de Jira sin publicar un enlace que no funcionaría para quien no tenga acceso.
2. **Qué hicieron:** revisaron cómo funciona el acceso a los tableros de Jira. Concluyeron que, hasta donde saben, un tablero no puede hacerse público. Propusieron invitar a la persona correspondiente al proyecto.
3. **Qué esperaban que pasara:** Que se aceptara la invitación como alternativa al enlace en el README.
4. **Qué pasó:** Solicitarón que se le enviaran una invitación al correo (roderykmaliachi@gmail.com). 
5. **Qué consultaron con la IA o la documentación y qué resultó:** el conocimiento previo sobre los permisos de los tableros de Jira (no públicos) llevó a proponer la invitación.
- **Después:** Enviar la invitación

## Entrada 10 — Si Jira ya registra quién trabajó en cada tarea y su rama de GitHub, ¿hace falta una bitácora de contribuciones aparte?

- **Autor:** Fernando Joachin · **Fecha:** 2026-11-09, 21:40 **Dónde** En #questions en Slack
1. **Qué intentaban lograr:** evitar duplicar información: saber si basta con Jira o si se necesita un registro de contribuciones separado.
2. **Qué hicieron:** observaron que Jira ya registra quién trabajó en cada tarea y la rama asociada en GitHub. Preguntaron si eso bastaba.
3. **Qué esperaban que pasara:** que se aceptara Jira como evidencia de las contribuciones.
4. **Qué pasó:** Maliachi respondió que la información de Jira es suficiente. La condición es que los números de los reportes de la pestaña Summary sean correctos, y Fernando es responsable de esa información.
5. **Qué consultaron con la IA o la documentación y qué resultó:** revisaron lo que Jira ya muestra (responsable y rama por tarea). Eso les permitió proponer no duplicar el registro. **Resuelto.**
- **Después:** Se decidió crear una bitácora para atributir tareas fuera de Jira. Igualmente se mantiene Jira como fuente de verdad.

---

=======
# Preguntas y reportes

Registro individual de cada vez que alguien del equipo preguntó algo, en cualquier lugar (reunión, Slack, Jira, chat con la IA), o encontró un
bloqueo, con **cómo pensábamos resolverlo** y **qué pasó después**. Mínimo de la rúbrica: 4 entradas por integrante, en al menos 2 semanas distintas.

> **Definición:** la dio la profesora Maliachi en #questions el 10 de noviembre de 2026, al responderle a Fernando: el reporte es sobre cada vez que
> alguien del equipo preguntó algo en cualquier parte, y sirve para que ella sepa cómo pensábamos resolver los bloqueos que tuvimos en el camino.
> Solo se anota lo que ocurrió y se puede comprobar (bitácora de IA, Jira, historial de Git, `docs/seguridad.md`). Cada integrante completa y confirma su sección.

Semanas: **S1** = 2 a 8 de noviembre de 2026; **S2** = 9 a 15 de noviembre.

## José Carlos Leo Fernández

| # | Fecha (semana) | Dónde | El bloqueo (pregunta o problema) | Cómo pensábamos resolverlo | Qué pasó después |
|---|---|---|---|---|---|
| 1 | 8 nov (S1) | Chat con la IA | El mockup y un mensaje al equipo decían que la donación anónima pide solo el correo; en la reunión del 7 de noviembre se acordó pedir siempre nombre, apellidos y correo (min 20:27 a 21:13). | Contrastar lo que dijo la IA con la transcripción de la reunión antes de dar nada por bueno. | Se corrigió el mockup de Donar y se revisaron las historias contra la reunión en Jira (bitácora, entradas 1 y 2). |
| 2 | 9 nov (S2) | Despliegue a la org | El despliegue de la landing falló con `LWC1503`: una propiedad pública booleana no puede empezar en `true`. | Leer el error del compilador y cambiar el diseño de la propiedad. | Se invirtió a `sinPortada = false` con un getter `incluirPortada`; desplegó bien (bitácora, entrada 4). |
| 3 | 9 nov (S2) | Chat con la IA | La primera versión del inicio conservaba el título "México Dreaming" y paquetes fijos que ya no iban según la reunión. | Comparar la propuesta con las decisiones de la reunión. | Se quitaron los paquetes, se reescribieron los pasos y el título pasó a "Apoya a la comunidad" (bitácora, entrada 5). |
| 4 | 10 nov (S2) | Celular y chat con la IA | Al abrir el sitio desde el celular salió el inicio de sesión. ¿Por qué, si las páginas respondían 200? | Comprobar con `curl` a dónde redirigía la respuesta. | El 200 era de la página de login. Faltaba activar el sitio, hacerlo público y dar al guest acceso a `MesaRegalosController`; esos pasos los hizo el dueño de la cuenta y se verificaron por consulta (bitácora, entrada 8). |
| 5 | 10 nov (S2) | Chat con la IA | ¿Por qué el asistente no podía hacer público el sitio ni dar el permiso al guest, si antes parecía poder? | Pedir el paso a paso para la sandbox UADY (Salesforce Classic) y hacerlo a mano. | La IA no cambia ajustes de seguridad ni de acceso público. Se hizo a mano y después se comprobó que el sitio está activo y público y que el guest solo tiene una clase de Apex. |
| 6 | 10 nov (S2) | Sitio publicado, como visitante | Al donar como visitante en la sandbox UADY salía "Ocurrió un error", aunque la prueba de Apex como administrador pasaba. | Activar el registro de depuración del usuario guest y leer la causa. | Un trigger de otro proyecto (`PreApproveStudent`) cancelaba la donación. Se desactivó con respaldo y aprobación del autor; la donación quedó pendiente y fuera del muro. En `docs/seguridad.md` y bitácora (entrada 9). |
| 7 | 10 nov (S2) | Sitio publicado, como visitante | En el muro público de la UADY aparecía un reconocimiento de $99,000 que el código no creó. | Consultar de dónde venía el registro y ocultarlo sin borrarlo. | Se ocultó (`Mostrar_En_Muro__c` en falso). Riesgo cerrado en `docs/seguridad.md`. |
| 8 | 10 nov (S2) | Chat con la IA | Las donaciones no tienen precio fijo: ¿cómo se manejan en Stripe? | Investigar en la documentación de Stripe. | Un Payment Link con "el cliente elige cuánto pagar" sirve (mínimo y máximo opcionales). Pendiente que Daniel lo pruebe. |
| 9 | 10 nov (S2) | Chat con la IA | ¿Cómo pasar a Stripe el monto que el donante ya eligió en nuestro formulario? | Revisar qué parámetros acepta el link. | En el link solo confirmamos el correo y el Id del donativo; el monto no. Opciones: 9 links (8 montos fijos y uno libre) para la Entrega 1, o crear la sesión de pago desde Salesforce en la Entrega 2. Pendiente de decidir con Daniel. |

## Daniel Amaya

Pendiente: cada integrante escribe sus entradas. Para ubicarlas: su mensaje a #questions del 3 de noviembre (preguntas al cliente) y la respuesta del cliente del 4 de noviembre.

| # | Fecha (semana) | Tipo | Qué se preguntó o reportó | Qué pasó después |
|---|---|---|---|---|
| — | por completar | | | |

## Fernando Joachín

Pendiente: cada integrante escribe sus entradas. Para ubicarlas: sus mensajes a #questions del 9 de noviembre (qué es este registro, y si se puede invitar al profesor a Jira en vez de dar un enlace público).

| # | Fecha (semana) | Tipo | Qué se preguntó o reportó | Qué pasó después |
|---|---|---|---|---|
| — | por completar | | | |
>>>>>>> origin/SCRUM-89-docs-preguntas-y-reportes
