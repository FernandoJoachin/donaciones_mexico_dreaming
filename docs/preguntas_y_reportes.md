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
