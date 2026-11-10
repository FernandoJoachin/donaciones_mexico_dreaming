# Preguntas y reportes

Registro individual de las preguntas que nos hicimos o hicimos a otras personas y de los problemas que reportamos durante el proyecto,
cada uno con **lo que pasó después**. Mínimo de la rúbrica: 4 entradas por integrante, en al menos 2 semanas distintas.

> **Supuesto:** no encontramos una definición de este registro en la guía (Fernando preguntó en #questions el 9 de noviembre y no hay respuesta visible).
> Lo tomamos así: *pregunta* = algo que no sabíamos y preguntamos (al cliente, al profesor, al equipo o a la IA); *reporte* = un problema que encontramos y avisamos o corregimos.
> Si el profesor lo define distinto, se ajusta el formato.
> Solo se anota lo que ocurrió y se puede comprobar (bitácora de IA, Jira, historial de Git, `docs/seguridad.md`). Cada integrante completa y confirma su sección.

Semanas: **S1** = 2 a 8 de noviembre de 2026; **S2** = 9 a 15 de noviembre.

## José Carlos Leo Fernández

| # | Fecha (semana) | Tipo | Qué se preguntó o reportó | Qué pasó después |
|---|---|---|---|---|
| 1 | 8 nov (S1) | Reporte | El mockup y un mensaje al equipo decían que la donación anónima pide solo el correo, y en la reunión del 7 de noviembre se acordó pedir siempre nombre, apellidos y correo (min 20:27 a 21:13 de la transcripción). | Se corrigió el mockup de Donar; la historia US-03 se revisó con el resto de historias al conciliar la reunión con Jira (bitácora, entradas 1 y 2). |
| 2 | 9 nov (S2) | Reporte | El despliegue de la landing falló con `LWC1503`: una propiedad pública booleana no puede tener valor inicial `true`. | Se invirtió la propiedad a `sinPortada = false` con un getter `incluirPortada`; desplegó bien (bitácora, entrada 4). |
| 3 | 9 nov (S2) | Reporte | La primera versión del inicio conservaba el título "México Dreaming" y paquetes fijos de $1,000, $3,000 y $5,000 que ya no iban según la reunión. | Se quitaron los paquetes, se reescribieron los pasos y el título pasó a "Apoya a la comunidad" (bitácora, entrada 5). |
| 4 | 10 nov (S2) | Pregunta | Al abrir el sitio desde el celular salió la pantalla de inicio de sesión. ¿Por qué, si las páginas respondían 200? | El 200 era de la página de login, no del sitio. Faltaba activar el sitio, hacerlo público y dar al usuario guest acceso a `MesaRegalosController`. Esos pasos de seguridad los hizo el dueño de la cuenta desde la interfaz y se verificó por consulta (bitácora, entrada 8). |
| 5 | 10 nov (S2) | Pregunta | ¿Por qué el asistente no podía hacer público el sitio ni dar el permiso al guest, si antes sí parecía poder? | La IA no cambia ajustes de seguridad ni de acceso público aunque se lo pidan; dio el paso a paso para la sandbox UADY (Salesforce Classic) y el cambio se hizo a mano. Después se comprobó que el sitio está activo y público y que el guest solo tiene una clase de Apex. |
| 6 | 10 nov (S2) | Reporte | Al donar como visitante en la sandbox UADY salía "Ocurrió un error", aunque la prueba de Apex como administrador pasaba. | Con el registro de depuración del guest se vio que un trigger de otro proyecto (`PreApproveStudent`) cancelaba la donación. Se desactivó con respaldo y con aprobación del autor, y la donación quedó pendiente sin salir en el muro. Documentado en `docs/seguridad.md` y en la bitácora (entrada 9). |
| 7 | 10 nov (S2) | Reporte | En el muro público de la sandbox UADY aparecía un reconocimiento de $99,000 que el código no creó. | Se ocultó (`Mostrar_En_Muro__c` en falso, no se borró). Queda anotado como riesgo cerrado en `docs/seguridad.md`. |

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
