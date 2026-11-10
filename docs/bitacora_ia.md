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

## Pendiente por integrante

| Integrante | Entradas | Errores de la IA marcados |
|---|---|---|
| José Carlos Leo Fernández | 8 | 4 (entradas 1, 4, 5 y 8) |
| Daniel Amaya | por completar | por completar |
| Fernando Joachín | por completar | por completar |

Requisito de la rúbrica: mínimo 3 entradas con error de la IA, incluyendo a los tres integrantes.
