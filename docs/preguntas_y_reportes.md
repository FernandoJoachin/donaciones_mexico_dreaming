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
