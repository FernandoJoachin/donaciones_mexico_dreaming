# Bitácora de IA

Una entrada por uso relevante de la IA. Cada entrada lleva fecha, autor, herramienta, historia relacionada, qué se pidió,
qué se obtuvo y se verificó, qué se corrigió y cuánto aceleró (estimación de cuánto habría tomado sin IA).
Las entradas donde la IA se equivocó están marcadas con **⚠ Error de la IA**.

> **Estado:** el autor de esta versión es José Carlos Leo Fernández. Las entradas de Daniel Amaya y Fernando Joachín
> las completa cada quien (ver la sección "Pendiente por integrante"); no se redactan por ellos.
> Las aceleraciones son **estimaciones** del autor.

## Entradas

### 1. ⚠ Error de la IA — "anónimo = solo correo"
- **Fecha:** 2026-11-08
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-03 (formulario de donación) y el mockup de la página Donar
- **Qué se pidió:** actualizar el mockup y las historias a partir de la reunión del 7 de noviembre.
- **Qué se obtuvo:** el mockup y un mensaje al equipo decían que la donación anónima pide solo el correo.
- **Qué se verificó y cómo:** se contrastó con la transcripción de la reunión (min 20:27 a 21:13): se acordó pedir **siempre**
  nombre, apellidos y correo, y filtrar lo anónimo en código al mostrar el muro.
- **Qué se corrigió:** el mockup de Donar. La historia US-03 en Jira no se había tocado.
- **Aceleración estimada:** ~1 h (revisar la reunión a mano contra el backlog). Sin la transcripción habría pasado sin detectarse.

### 2. Transcripción local de la reunión y conciliación con Jira
- **Fecha:** 2026-11-08
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (con Whisper.cpp local, modelo large-v3-turbo-q5_0, y la integración con Jira)
- **Historia:** varias (US-02, US-10, US-11, US-20 y tareas de documentación)
- **Qué se pidió:** transcribir el video de la reunión del 7 de noviembre y revisar que las historias de Jira reflejen lo acordado.
- **Qué se obtuvo:** transcripción con minutos y una lista de cambios por historia (por ejemplo, factura solo por pie de página y
  correo; campañas pasadas y porcentaje del padre como V3).
- **Qué se verificó y cómo:** cada cambio se ligó al minuto de la transcripción; las decisiones dudosas se confirmaron
  con el autor antes de editar Jira. Un resumen de Jira superó los 255 caracteres y se acortó.
- **Qué se corrigió:** se descartó un ticket de "resumen de monto antes de pagar" porque ese paso lo hace la pasarela.
- **Aceleración estimada:** ~4 h (escuchar 1 h de reunión y reconciliar a mano los tickets afectados).

### 3. Detalle de campaña: endpoint Apex y componente
- **Fecha:** 2026-11-09
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-02 / SCRUM-8
- **Qué se pidió:** una página de presentación de una campaña con su avance y un botón para donar, que no muestre datos de otra
  campaña con un Id inventado.
- **Qué se obtuvo:** `obtenerCampana` en `MesaRegalosController` (con un ayudante compartido con la lista), el componente
  `mesaCampanaDetalle` y 4 pruebas nuevas.
- **Qué se verificó y cómo:** las pruebas de Apex en la org de desarrollo (35 de 35 pasan); consulta como visitante a campañas
  inexistentes, pausadas o con Id malformado (devuelve nulo); revisión visual del sitio publicado.
- **Qué se corrigió:** la tarjeta quedaba angosta; se ensanchó y se rediseñó con la imagen como hero.
- **Aceleración estimada:** ~5 h.

### 4. ⚠ Error de la IA — propiedad Boolean con valor por defecto `true`
- **Fecha:** 2026-11-09
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-5 / SCRUM-86 (landing del inicio)
- **Qué se pidió:** que el componente de campañas incluya la portada del inicio y se pueda apagar desde Experience Builder.
- **Qué se obtuvo:** una propiedad `@api incluirPortada = true`.
- **Qué se verificó y cómo:** el despliegue a la org falló con `LWC1503`: una propiedad pública booleana no puede inicializarse en `true`.
- **Qué se corrigió:** se invirtió a `sinPortada = false` y un getter `incluirPortada`.
- **Aceleración estimada:** ~30 min; el compilador de la plataforma detectó el error, no la revisión de código.

### 5. ⚠ Error de la IA — home con título y paquetes que ya no iban
- **Fecha:** 2026-11-09
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-5 (sitio central) y SCRUM-61 (paquetes por campaña)
- **Qué se pidió:** reconstruir el inicio como una landing, tomando como base el inicio anterior.
- **Qué se obtuvo:** una propuesta que conservaba el título "México Dreaming" y una sección de paquetes fijos de $1,000, $3,000 y $5,000;
  el paso 2 hablaba de aparecer como "Anónimo" sin pedir datos.
- **Qué se verificó y cómo:** se comparó con las decisiones de la reunión (siempre se piden nombre y correo; los paquetes
  son por campaña). Además el autor indicó que el título del sitio ya no podía ser el del evento.
- **Qué se corrigió:** se quitó la sección de paquetes, se reescribieron los pasos y el título pasó a "Apoya a la comunidad".
- **Aceleración estimada:** ~2 h.

### 6. Página de facturas y enlace en el pie
- **Fecha:** 2026-11-09
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-20 / SCRUM-86 (subtarea SCRUM-128)
- **Qué se pidió:** una página informativa con el proceso para pedir factura, enlazada desde el pie, sin formulario ni datos guardados.
- **Qué se obtuvo:** el componente `mesaFacturas`, el enlace "Facturas" en `mesaPie` y la actualización de la historia en Jira.
- **Qué se verificó y cómo:** se abrió la página publicada y se leyeron los enlaces del pie en el sitio real.
- **Qué se corrigió:** el correo de contacto es un marcador (`facturas@ejemplo.org`) que el equipo debe sustituir.
- **Aceleración estimada:** ~2 h.

### 7. Prueba de seguridad del visitante
- **Fecha:** 2026-11-09
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-16 / SCRUM-82 y `docs/seguridad.md`
- **Qué se pidió:** ejecutar la prueba como visitante sin login y documentarla para que otra persona la repita.
- **Qué se obtuvo:** los pasos y los resultados reales descritos en `docs/seguridad.md`.
- **Qué se verificó y cómo:** cada paso se ejecutó contra el sitio publicado; no se dieron por buenos resultados esperados sin correrlos.
- **Qué se corrigió:** nada que corregir; se dejó escrito que el muro se probó sin donantes en la org (límite de la prueba).
- **Aceleración estimada:** ~1.5 h.

### 8. ⚠ Error de la IA — "las páginas dan 200" no era un sitio público
- **Fecha:** 2026-11-10
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-86 / sitio en la sandbox UADY
- **Qué se pidió:** limpiar la sandbox UADY (automatizaciones de otros proyectos que impedían guardar donativos) y armar y publicar el sitio nuevo "Mesa de regalos".
- **Qué se obtuvo:** una prueba en Apex que confirmó el flujo completo de un donativo después de desactivar `OpportunityTrigger` y 4 reglas de validación de Campaign (con respaldo previo). La IA también reportó que las 5 páginas del sitio respondían "200".
- **Qué se verificó y cómo:** el autor abrió el sitio desde el celular y vio la pantalla de inicio de sesión. Se comprobó con `curl` que la respuesta traía un redireccionamiento a login: el 200 era de la página de login, no del sitio.
- **Qué se corrigió:** se dejó de usar el código de respuesta como prueba y se anotaron los pasos pendientes (activar el sitio, hacerlo público y dar al usuario guest acceso a `MesaRegalosController`). Esos pasos de seguridad los hace el dueño de la cuenta.
- **Aceleración estimada:** ~3 h (diagnosticar los bloqueos de la sandbox y armar las 5 páginas).

### 9. ⚠ Error de la IA — "el flujo de donar funciona" solo se había probado como administrador
- **Fecha:** 2026-11-10
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-86 / sitio en la sandbox UADY y `docs/seguridad.md`
- **Qué se pidió:** probar el sitio publicado como visitante (detalle de campaña, formulario de donar) antes de avisar al equipo.
- **Qué se obtuvo:** la IA había dado por bueno el flujo de donar porque la prueba en Apex, corrida como administrador, pasaba. Al hacer la prueba real como visitante, el formulario falló con "Ocurrió un error". Con el registro de depuración del usuario guest se vio la causa: el trigger `PreApproveStudent`, de otro proyecto de la sandbox, busca la campaña `FONDOS SDU`, que el guest no puede ver, y cancelaba la donación. Antes de eso, la IA había instalado en la sandbox una versión vieja de `MesaRegalosController` (sin el método de campañas) y la lista salía con "No pudimos cargar las campañas".
- **Qué se verificó y cómo:** se repitió el envío como visitante en un navegador sin sesión y se consultó la org: el donativo quedó `Prospecting` y no apareció en el muro ni en el total. También se encontró en el muro público un reconocimiento de demostración de $99,000 que no creó el código; se ocultó.
- **Qué se corrigió:** se desplegó el código completo de `entrega-1`, se desactivó `PreApproveStudent` (con respaldo y con la aprobación del autor) y se documentó en `docs/seguridad.md`. Lección: una prueba con permisos de administrador no demuestra lo que puede hacer el visitante.
- **Aceleración estimada:** ~2 h (la depuración con el registro del guest habría llevado más sin la IA).

### 10. Muro de agradecimiento: consulta, agrupación y estados
- **Fecha:** 2026-11-10
- **Autor:** Fernando Joachín
- **Herramienta:** GitHub Copilot (Copilot SDK en VS Code; modelo no identificado en el historial)
- **Historia:** US-09 / SCRUM-49 (criterios SCRUM-50 a SCRUM-58)
- **Qué se pidió:** implementar el muro con donaciones pagadas, anonimato, agrupación de aportes, ordenamiento, podio, carga, error y estado vacío.
- **Qué se obtuvo:** cambios en `MesaRegalosController`, `MesaRegalosDonativoTest` y el componente `mesaMuro`; el muro consulta reconocimientos públicos de la campaña, excluye oportunidades no pagadas, agrupa por contacto y suma sus montos. Se agregaron datos de prueba y pruebas para el muro y el avance.
- **Qué se verificó y cómo:** las pruebas Apex pasaron en `mesa-dev` (17 pruebas). En `donation-UADY-lab`, la ejecución de pruebas se bloqueó por la automatización preexistente `PreApproveStudent`, que espera una campaña `FONDOS SDU`; el despliegue autorizado se hizo sin ejecutar pruebas. La compilación de los cambios del componente se validó con un dry-run.
- **Qué se corrigió:** se agregó tratamiento explícito de error y estado vacío y una alternativa a `ResizeObserver` para el entorno de Live Preview. El funcionamiento visual del spinner y el auto-scroll en Live Preview no quedó confirmado por esa validación.
- **Aceleración estimada:** ~4 h (análisis de criterios, cambios de Apex y LWC, y pruebas).

### 11. ⚠ Error de la IA — "datos de prueba en la org equivocada"
- **Fecha:** 2026-11-10
- **Autor:** Fernando Joachín
- **Herramienta:** GitHub Copilot (Copilot SDK en VS Code; modelo no identificado en el historial)
- **Historia:** US-09 / SCRUM-49 (muro de agradecimiento)
- **Qué se pidió:** preparar datos de prueba para revisar el muro y consultar la información cargada.
- **Qué se obtuvo:** los datos de demostración y el permiso requerido se aplicaron inicialmente en `mesa-dev`, aunque no era la org que el autor quería usar.
- **Qué se verificó y cómo:** el autor señaló que esa no era la org correcta. Después se identificó en `donation-UADY-lab` la campaña activa México Dreamin y se consultaron los registros de prueba.
- **Qué se corrigió:** se limpiaron los registros de demostración y se revocó el permiso aplicado en `mesa-dev`; luego se prepararon en `donation-UADY-lab` 12 donaciones pagadas y una pendiente. La consulta confirmó un total pagado de $37,300 MXN. Aprendizaje: confirmar la org destino antes de ejecutar cambios de datos o permisos.
- **Aceleración estimada:** ~1 h (preparar, limpiar y comprobar datos en ambas orgs).

### 12. Podio y avance configurable de la campaña
- **Fecha:** 2026-11-10
- **Autor:** Fernando Joachín
- **Herramienta:** GitHub Copilot (Copilot SDK en VS Code; modelo no identificado en el historial)
- **Historia:** US-09 / SCRUM-49; criterio del porcentaje de avance (identificador específico pendiente)
- **Qué se pidió:** acercar el podio al diseño de referencia y mostrar el porcentaje de la meta alcanzada.
- **Qué se obtuvo:** actualización del podio y del panel de avance en `mesaMuro`; la meta se configura mediante la propiedad `metaCampana` de la página, con valor predeterminado de $50,000 MXN, sin agregar un campo a Campaign.
- **Qué se verificó y cómo:** Salesforce rechazó actualizar `Campaign.ExpectedRevenue`; se comprobó así que no era una opción editable en esa org. El componente con la propiedad configurable pasó el dry-run y se desplegó en `donation-UADY-lab`. Con los datos de prueba, $37,300 frente a $50,000 equivale a 75% redondeado.
- **Qué se corrigió:** se dejó de depender de `ExpectedRevenue` y se usó la propiedad de página elegida por el autor. La apariencia final y el valor mostrado en la página no quedaron verificados visualmente en esta actividad.
- **Aceleración estimada:** ~2 h (ajuste del podio, configuración de la meta y validación en Salesforce).

### 13. ⚠ Error de la IA — "el auto-scroll no cumplía CA8 y reiniciaba al principio"
- **Fecha:** 2026-11-10
- **Autor:** Fernando Joachín
- **Herramienta:** GitHub Copilot (Copilot SDK en VS Code; modelo no identificado en el historial)
- **Historia:** US-09 / SCRUM-57 (CA8) y SCRUM-58 (CA9)
- **Qué se pidió:** hacer que la lista más larga que el área visible se desplazara sola hacia abajo mientras se permanece en el muro.
- **Qué se obtuvo:** varias versiones de la animación. Una reiniciaba el scroll al principio al llegar al final y otra no produjo el auto-scroll observado por el autor.
- **Qué se verificó y cómo:** el autor reportó que ya no podía bajar hasta el final y, tras la corrección siguiente, que el auto-scroll seguía sin ocurrir. El dry-run y los despliegues comprobaron compilación, no el comportamiento en la página.
- **Qué se corrigió:** se eliminó el salto automático al inicio, se cambió la animación por pasos temporizados y se redujo la altura máxima del contenedor para hacer visible el desbordamiento; la interacción permite scroll manual. La última versión se desplegó, pero su funcionamiento visual aún requiere confirmación. Aprendizaje: compilar y desplegar no sustituye comprobar el desplazamiento real y el acceso manual al final de la lista.
- **Aceleración estimada:** ~1.5 h (depurar la interacción entre dimensiones del contenedor, temporizador y scroll manual).

### 14. Elaboración de prompt para documentar el uso de IA en la bitácora
- **Fecha:** 2026-11-10
- **Autor:** Fernando Joachín
- **Herramienta:** ChatGPT (GPT-6)
- **Historia:** Documentación del uso de IA en el proyecto; historia específica no identificada.
- **Qué se pidió:** elaborar un prompt para que GitHub Copilot analizara su historial de conversación, identificara las actividades realizadas por Fernando y generara las entradas correspondientes para `bitacora_ia.md`, siguiendo el formato utilizado por los demás integrantes.
- **Qué se obtuvo:** un prompt estructurado con instrucciones para identificar actividades reales, documentar solicitudes y resultados, registrar verificaciones y correcciones, estimar el tiempo ahorrado y actualizar la tabla de resumen de integrantes.
- **Qué se verificó y cómo:** se revisó la estructura de las entradas existentes en la bitácora y se adaptó el prompt para conservar el formato, la numeración y los criterios de documentación del equipo.
- **Qué se corrigió:** se ajustó el prompt para evitar información inventada, distinguir los errores reales de IA de las simples iteraciones y solicitar aprobación antes de modificar el archivo.
- **Aceleración estimada:** ~30 min (elaboración y ajuste de las instrucciones para documentar el uso de IA).
:::

### 15. Elaboración del documento de preguntas y reportes (sección 12)
- **Fecha:** 2026-11-10
- **Autor:** Fernando Joachín
- **Herramienta:** Claude (Sonnet 5.5)
- **Historia:** Documentación de las preguntas del equipo y los reportes de bloqueos (sección 12, "Cómo pedir ayuda");
- **Qué se pidió:** generar `preguntas_y_reportes.md` a partir de capturas de Slack con las preguntas hechas al cliente y sus respuestas. Cada entrada debía llevar autor, fecha y las cinco partes de un buen reporte: qué intentaban lograr, qué hicieron, qué esperaban que pasara, qué pasó y qué consultaron con la IA o la documentación. Después se pidió agregar tres preguntas propias que faltaban.
- **Qué se obtuvo:** un documento con 12 entradas (9 preguntas de Daniel y 3 de Fernando), un campo "Después" para registrar el seguimiento y una tabla de estado por pregunta, autor y resolución.
- **Qué se verificó y cómo:** se contrastó el documento con las capturas de Slack. Eso permitió detectar que faltaban las preguntas propias sobre el log de preguntas y reportes, el acceso al tablero de Jira y la bitácora de contribuciones. También se revisó que las respuestas del cliente estuvieran bien resumidas.
- **Qué se corrigió:** Los datos que no se podían confirmar con las capturas (fecha de las respuestas, fecha exacta de algunas preguntas, qué se consultó con la IA o la documentación) se dejaron marcados como "Por confirmar" o "Por completar" en lugar de inventarlos.
- **Aceleración estimada:** ~40 min (lectura de las capturas, redacción de las 12 entradas en el formato de cinco partes y armado de la tabla de estado).


## Pendiente por integrante

| Integrante | Entradas | Errores de la IA marcados |
|---|---|---|
| José Carlos Leo Fernández | 9 | 5 (entradas 1, 4, 5, 8 y 9) |
| Daniel Amaya | por completar | por completar |
| Fernando Joachín | 5 (entradas 10–15) | 2 (entradas 11 y 13) |

Requisito de la rúbrica: mínimo 3 entradas con error de la IA, incluyendo a los tres integrantes.
