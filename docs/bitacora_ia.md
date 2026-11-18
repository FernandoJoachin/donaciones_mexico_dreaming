# Bitácora de IA

Una entrada por uso relevante de la IA. Cada entrada lleva fecha, autor, herramienta, historia relacionada, qué se pidió,
qué se obtuvo y se verificó, qué se corrigió y cuánto aceleró (estimación de cuánto habría tomado sin IA).
Las entradas donde la IA se equivocó están marcadas con **⚠ Error de la IA**.

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

### 16. ⚠ Error de la IA — "CSS duplicado en el aviso de privacidad"
- **Fecha:** 2026-10-28
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-03 (aviso de privacidad)
- **Qué se pidió:** una página de aviso de privacidad para el sitio, con el responsable, el domicilio y el correo de contacto editables sin desplegar.
- **Qué se obtuvo:** el componente `mesaAviso` (HTML, JS, CSS y meta) con el texto en secciones. Las propiedades de responsable,
  domicilio, correo, plazo, versión y fecha se editan en Experience Builder.
- **Qué se verificó y cómo:** la IA revisó que el XML y el JS fueran válidos, sin desplegar. El autor lo desplegó en la org.
  La vista previa local marcó el error LWR3009, que se atribuyó al `@import` del CSS; esa causa no se confirmó.
- **Qué se corrigió:** el CSS repetía estilos que ya existen en `mesaEstilos` (banda, burbujas, título, tarjeta). El autor lo
  detectó y pidió reutilizarlos. Quedó solo el `@import` más las reglas propias de esa página.
- **Aceleración estimada:** ~3 h (redactar el aviso por secciones y armar el componente configurable).

### 17. ⚠ Error de la IA — "import faltante de resolverUrl en mesaDonacion"
- **Fecha:** 2026-10-28 (cambio) y 2026-10-30 (corrección)
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-03 (aviso de privacidad)
- **Qué se pidió:** revisar por qué el enlace "Ver aviso de privacidad" no redirigía.
- **Qué se obtuvo:** el enlace se arma con `resolverUrl` (getter `avisoHref`) en `mesaRegistro`, `mesaReencuentro` y
  `mesaDonacion`, para respetar el prefijo del sitio.
- **Qué se verificó y cómo:** el autor reprodujo el síntoma: sin token la donación abría bien; con token el componente no se
  dibujaba, aunque el navbar sí aparecía. La IA comparó los archivos de su carpeta y dedujo la causa. El autor confirmó que era esa.
- **Qué se corrigió:** `mesaDonacion` usaba `resolverUrl` sin importarlo. La instrucción original se dio como si los tres
  componentes importaran igual. Se agregó el import en `mesaDonacion`.
- **Aceleración estimada:** ~1.5 h (rastrear un componente que falla sin error visible).

### 18. Análisis para enviar correos: Flow o Apex
- **Fecha:** 2026-10-30
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-pendiente (correos de campaña)
- **Qué se pidió:** saber si los correos automáticos solo se pueden hacer con Flows o también con Apex, y revisar el plan de
  envío a unas 120 personas.
- **Qué se obtuvo:** una comparación Flow vs Apex (`Send Email` frente a `Messaging.sendEmail`, y un Flow que llama a un
  `@InvocableMethod`). Recomendaciones: el enlace de donar va en todas las campañas; el de reencuentro solo si la persona no
  lo ha llenado o cambió la versión del aviso; la baja se filtra con `HasOptedOutOfEmail`, sin depender de
  `Consentimiento_Contacto__c`.
- **Qué se verificó y cómo:** fue un análisis sin cambios al repo. La IA marcó que no tenía certeza de que la acción de correo
  respete la baja por sí sola, y recomendó probarlo con un contacto dado de baja. Esa prueba sigue pendiente porque los Flows
  están pausados.
- **Qué se corrigió:** nada. El tema de si el reencuentro va en cada campaña se retomó en el rediseño del 9 de noviembre (entrada 5).
- **Aceleración estimada:** ~2 h (leer documentación y comparar opciones).

### 19. ⚠ Error de la IA — "lógica de empresa mal interpretada"
- **Fecha:** 2026-11-09
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** Varias (US02,03,05,06,09,11,15,19 ) (rediseño: sin token, registro y donación unificados)
- **Qué se pidió:** primero un inventario de lo creado (campos, funciones), y luego el impacto de los cambios en el controlador,
  la interfaz y las pruebas, sin modificar nada.
- **Qué se obtuvo:** el inventario, una tabla de impacto y la especificación final tras varias rondas de feedback: visibilidad
  Pública/Anónima, consentimiento Sí/No obligatorio, monto siempre público, donación de empresa y campos a eliminar.
- **Qué se verificó y cómo:** no se tocó código hasta que el autor confirmó cada decisión por escrito. Las propuestas se
  contrastaron con el código y las pruebas existentes.
- **Qué se corrigió:** la IA interpretó mal el apartado de empresa. El autor lo aclaró: un checkbox que oculta nombre y
  apellidos, un solo input cuyo valor se copia a ambos campos, y sin crear ni buscar Accounts.
- **Aceleración estimada:** ~6 h (mapear cada campo, método y prueba afectado, y documentar el plan).

### 20. ⚠ Error de la IA — "falta el .cls-meta.xml de la clase de pruebas"
- **Fecha:** 2026-11-09
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** Del plan anterior #19 {continuación} (registro y donación sin token)
- **Qué se pidió:** la parte de servidor del rediseño, sin romper lo existente.
- **Qué se obtuvo:** campos nuevos y permission set actualizado; `guardarDonativo` con validaciones, campo trampa y tope por
  hora; `darseDeBaja`; `confirmarPago` con reconocimiento público o anónimo; y `MesaRegalosDonativoTest` con 12 pruebas.
- **Qué se verificó y cómo:** el autor corrió `--dry-run` con `RunLocalTests` en la org, y pasó tras el ajuste.
- **Qué se corrigió:** la clase de pruebas nueva no traía su `.cls-meta.xml` y el despliegue marcó `ConversionError`. Se
  entregó el archivo faltante.
- **Aceleración estimada:** ~8 h (más de 700 líneas de Apex, validaciones y pruebas).

### 21. ⚠ Error de la IA — "propiedad paginaDonar eliminada del meta"
- **Fecha:** 2026-11-09
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** [completar con el SCRUM de Jira] (formulario único y baja)
- **Qué se pidió:** la interfaz del rediseño.
- **Qué se obtuvo:** `mesaRegistro` reescrito como formulario único, el componente nuevo `mesaBaja`, y cambios en `mesaInicio`
  y `mesaMuro`.
- **Qué se verificó y cómo:** `--dry-run` en la org, con una lista de pruebas manuales sugerida.
- **Qué se corrigió:** la IA quitó la propiedad `paginaDonar` del `js-meta.xml`. Salesforce no permite quitar propiedades de
  componentes en uso en un sitio, y el despliegue falló. El autor quitó los componentes del Builder y el despliegue pasó. La
  IA propuso además dejar la propiedad obsoleta hasta el paso 5.
- **Aceleración estimada:** ~6 h.

### 22. ⚠ Error de la IA — "scripts de apoyo sin actualizar en el paso 5"
- **Fecha:** 2026-11-09 y 2026-11-10
- **Autor:** Daniel Salvador Amaya Tapia
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** (limpieza técnica y despliegue)
- **Qué se pidió:** eliminar lo obsoleto (token, Reencuentro, campos y pruebas viejas) y desplegar en una org nueva.
- **Qué se obtuvo:** controlador y servicio reescritos solo con el flujo nuevo; borrado de 13 campos, un trigger, 2
  componentes y la clase de pruebas vieja; limpieza del permission set; manifiestos de borrado y un checklist de la org nueva.
  Luego un diagnóstico de los fallos, a partir de los logs que pegó el autor: las 110 pruebas fallaron por
  `CampaignTriggerHandler` de otro proyecto de esa sandbox; 16 fallos vinieron de una regla de validación sobre Campaign
  (`Visibility_Start_Date__c`) que tampoco es de este proyecto; y `crear-campana.apex` falló porque el usuario no tenía
  Marketing User.
- **Qué se verificó y cómo:** el autor corrió los dry-run. Los 38 componentes validaron sin errores
  (`numberComponentErrors: 0`); los fallos eran de pruebas y de otro código. La conclusión fue validar en una org limpia
  (Developer Edition).
- **Qué se corrigió:** el paso 5 no incluyó actualizar los scripts de apoyo. `crear-campana.apex` no creaba el estado
  «Registrado», y `simulador-donativo.apex` y `tokens-faltantes.apex` usaban métodos ya eliminados. Se detectó cuando el autor
  preguntó. También se corrigió un comando de exclusión de git pensado para otro shell, porque en PowerShell podía guardar el
  archivo con una codificación incorrecta.
- **Aceleración estimada:** ~5 h.

### 23. ⚠ Error de la IA — "mergeó un PR a la rama equivocada"
- **Fecha:** 2026-11-15
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-10 / SCRUM-62 (PR #17 de Daniel)
- **Qué se pidió:** mergear los PR abiertos (#17, #18 y #19) a `entrega-1`.
- **Qué se obtuvo:** la IA mergeó el #17 sin revisar su rama base, que era `main`. GitHub lo marcó como mergeado, pero los cambios no llegaron a `entrega-1`.
- **Qué se verificó y cómo:** después del merge se revisó el historial de `entrega-1` y faltaban los permission sets nuevos; el commit del merge colgaba de `main`.
- **Qué se corrigió:** el PR #20 (de `main` a `entrega-1`) llevó solo los 9 archivos de Daniel. Lección: revisar la rama base antes de mergear.
- **Aceleración estimada:** ~20 min (detectarlo a mano habría tardado más, porque GitHub decía "Merged").

### 24. ⚠ Error de la IA — "imágenes de las campañas desde GitHub"
- **Fecha:** 2026-11-15
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-13 / SCRUM-79 (imagen en cada campaña)
- **Qué se pidió:** campañas de demostración más realistas, con imagen.
- **Qué se obtuvo:** cinco ilustraciones servidas desde `raw.githubusercontent.com`. En el sitio no cargaban: la política de seguridad de contenido del sitio bloquea imágenes de otros dominios. Al pasarlas a un recurso estático con ruta relativa tampoco salían, porque el controlador solo acepta URL `https://`.
- **Qué se verificó y cómo:** se abrió el sitio como visitante con un navegador automatizado y se leyeron los errores de la consola y el tamaño real de cada imagen.
- **Qué se corrigió:** las imágenes quedaron en el recurso estático `MesaCampanasImg` y el script usa la dirección completa del sitio. No se cambió la configuración de seguridad del sitio.
- **Aceleración estimada:** ~1 h.

### 25. Historia de cada campaña (US-22)
- **Fecha:** 2026-11-15
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-22 / SCRUM-132
- **Qué se pidió:** que cada campaña cuente su historia (retro de la presentación del 12 de noviembre: "no parecía un sitio de donación").
- **Qué se obtuvo:** campos en Campaign (resumen, historia, a quién ayuda, quién organiza), el objeto hijo `Nivel_Impacto__c`, el número de donantes en el controlador, la página de campaña en dos columnas, el monto elegido que llega al formulario (`?monto=`) y el contenido ficticio de las 5 campañas.
- **Qué se verificó y cómo:** 3 pruebas nuevas de Apex pasan en la org de desarrollo (una prueba del muro ya fallaba antes, sin estos cambios). Prueba como visitante en la sandbox UADY, en escritorio y celular: la historia y los niveles se ven y elegir un nivel abre el formulario con ese monto.
- **Qué se corrigió:** el permission set rechazó permisos de campo en campos obligatorios y pedía lectura de Campaign; el script no podía escribir `Orden__c` sin permiso de campo, así que se agregó al permission set de administración.
- **Aceleración estimada:** ~6 h.

### 26. Diagnóstico de la prueba del muro que fallaba (US-21)
- **Fecha:** 2026-11-15
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-21 / SCRUM-134
- **Qué se pidió:** saber por qué fallaba `muroConsolidaPorDonanteSeparaAnonimosYExcluyePendientes` (Expected 1, Actual null en la línea 324) y corregirla.
- **Qué se obtuvo:** el código del muro estaba bien; la prueba guardaba los montos como llaves de un `Map<Decimal, Integer>`. El monto llega como `1000.00` y se buscaba con `get(1000)`: en Apex `1000.00 == 1000` es verdadero, pero en un Map son llaves distintas.
- **Qué se verificó y cómo:** se repitió el escenario de la prueba con Apex anónimo en la org de desarrollo, deshaciendo los datos al final: el muro devolvió renglones de 1000 y 5000 y 3000 en el total anónimo. Aparte se comprobó que `m.get(1000)` da `null` cuando la llave guardada es `1000.00`.
- **Qué se corrigió:** solo la prueba, que ahora usa `item.monto.intValue()` como llave. Pasan las 39 pruebas de `MesaRegalosDonativoTest` y `MesaCampanasTest` en la org de desarrollo.
- **Aceleración estimada:** ~1 h.

### 27. Integración de pagos con Stripe Checkout y webhook (US-05)
- **Fecha:** 2026-11-15
- **Autor:** Fernando Joachín
- **Herramienta:** Claude (Anthropic), con acceso a la carpeta del proyecto y a la cuenta de prueba de Stripe
- **Historia:** US-05 / SCRUM-9
- **Qué se pidió:** analizar el proyecto, proponer e implementar el pago con Stripe para que la donación quede registrada como pendiente antes de pagar, se cobre exactamente el monto elegido y se confirme sola; más una guía de pruebas.
- **Qué se obtuvo:** primero una propuesta (sin tocar código) que comparó Checkout, Elements y los Payment Links existentes, y dejó cuatro decisiones al autor: X = $100 MXN (el mínimo que ya existía), facturación fuera de esta historia, aviso en el sitio (sin correo) y reemplazar los Payment Links. Después: `MesaPagosStripe` (sesión de Checkout y firma), `MesaStripeWebhook` (aviso de pago), `iniciarPago` y `estadoPago` en el controlador, credencial con nombre, configuración `Stripe_Config__c`, permission set `Mesa_Sitio_Pagos`, cambios en `mesaRegistro` y `mesaMuro`, 16 pruebas en `MesaPagosStripeTest` y `docs/guia_pruebas_stripe.md`.
- **Qué se verificó y cómo:** pago de prueba de punta a punta en la sandbox UADY con la tarjeta `4242…`: Stripe cobró MXN $1,000.00 con `client_reference_id` y `metadata.donativo_id` iguales al Id del donativo, y el evento `checkout.session.completed` se entregó al webhook sin pendientes (revisado con la API de Stripe). El sitio mostró el agradecimiento al volver.
- **Qué se corrigió:** ver entradas 28 a 30.
- **Aceleración estimada:** ~12 h (diseño, Apex, LWC, pruebas y guía).

### 28. ⚠ Error de la IA — metadata inválida y el mismo error de la entrada 21
- **Fecha:** 2026-11-15
- **Autor:** Fernando Joachín
- **Herramienta:** Claude (Anthropic)
- **Historia:** US-05 / SCRUM-9
- **Qué se pidió:** desplegar la integración de Stripe.
- **Qué se obtuvo:** el despliegue falló con dos errores: la credencial con nombre traía `description`, que no es válida en la versión 62.0, y la IA había quitado del `js-meta.xml` de `mesaRegistro` las cuatro propiedades de Payment Link, que el sitio publicado todavía tenía guardadas. Es el mismo error de la entrada 21.
- **Qué se verificó y cómo:** la salida de `sf project deploy start`. Como el despliegue es todo o nada, la org no cambió.
- **Qué se corrigió:** se quitó `description` y las propiedades se conservaron marcadas como "(Ya no se usa)"; el código ya no las lee.
- **Aceleración estimada:** ~15 min. Lección: revisar la bitácora antes de quitar propiedades de un componente que está en un sitio.

### 29. ⚠ Error de la IA — parámetro de Stripe ya no soportado
- **Fecha:** 2026-11-15
- **Autor:** Fernando Joachín
- **Herramienta:** Claude (Anthropic)
- **Historia:** US-05 / SCRUM-9
- **Qué se pidió:** abrir la pasarela desde el sitio.
- **Qué se obtuvo:** el sitio mostraba "No pudimos abrir la pasarela de pago". La IA había enviado `payment_method_types`, que Stripe ya no acepta al crear sesiones de Checkout (ahora los métodos se eligen en el Dashboard). Además, el registro de errores solo guardaba el código HTTP, así que la causa no se veía.
- **Qué se verificó y cómo:** la cuenta de Stripe no tenía ninguna sesión creada; un script de diagnóstico en Apex anónimo repitió la petición y mostró la respuesta completa (`HTTP 400`, `param: payment_method_types`).
- **Qué se corrigió:** se quitó el parámetro. En la revisión final se mejoró el registro para guardar tipo, código, parámetro y mensaje del error de Stripe.
- **Aceleración estimada:** ~30 min, aunque el registro pobre alargó el diagnóstico.

### 30. ⚠ Error de la IA — al usuario guest le faltaba un permiso de la credencial
- **Fecha:** 2026-11-15
- **Autor:** Fernando Joachín
- **Herramienta:** Claude (Anthropic)
- **Historia:** US-05 / SCRUM-9
- **Qué se pidió:** que el visitante del sitio (usuario guest) pudiera abrir la pasarela.
- **Qué se obtuvo:** con el usuario administrador funcionaba y con el guest no. El permission set que preparó la IA daba acceso al principal de la credencial pero no la lectura del objeto *User External Credential*, que Salesforce también exige.
- **Qué se verificó y cómo:** se activó un registro de depuración del usuario guest y se leyó el error: `You don't have read permissions on the User External Credential object`.
- **Qué se corrigió:** se agregó solo esa lectura a `Mesa_Sitio_Pagos`. Después de desplegarlo, el sitio abrió Stripe.
- **Aceleración estimada:** ~1 h.

### 31. Revisión de buenas prácticas del código de pagos
- **Fecha:** 2026-11-15
- **Autor:** Fernando Joachín
- **Herramienta:** Claude (Anthropic)
- **Historia:** US-05 / SCRUM-9
- **Qué se pidió:** revisar que el código generado siguiera buenas prácticas.
- **Qué se obtuvo:** una revisión con lo que estaba bien y seis puntos. Se aplicaron tres: cobrar siempre en pesos (`adaptive_pricing[enabled]=false`, porque con Adaptive Pricing un donante extranjero podía pagar en otra moneda y el webhook rechazaría la confirmación), el registro de errores de Stripe (entrada 29) y borrar los scripts temporales de diagnóstico. Quedó sin aplicar la llave de idempotencia con huella de los datos.
- **Qué se verificó y cómo:** la configuración de métodos de pago y la sesión pagada se leyeron con la API de Stripe; las pruebas de Apex se corren al desplegar.
- **Qué se corrigió:** lo descrito arriba.
- **Aceleración estimada:** ~1 h.

### 32. Revisión del PR de pagos y muro por campaña (SCRUM-135)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-05 / SCRUM-9 (revisión del PR #27) y SCRUM-135
- **Qué se pidió:** revisar el PR de Stripe antes de mergearlo y, a pedido de Fernando, quitar del inicio el botón "Ver quién ya se sumó", porque cada campaña tiene su propio muro.
- **Qué se obtuvo:** la revisión confirmó que el PR conserva los cambios previos de `entrega-1` y valida firma, monto, moneda y duplicados; dejó como pendientes que los avisos rechazados solo quedan en el log (US-17 CA1, US-08) y el correo del comprobante (US-07). Para el muro: el botón se quitó del inicio (en el cierre queda "Quiero donar") y cada campaña tiene "Ver muro de agradecimiento", que abre `muro?campana=<Id>`.
- **Qué se verificó y cómo:** las 57 pruebas de Apex del PR pasan en la org de desarrollo; el código desplegado en la sandbox UADY es el mismo del PR. Como visitante en UADY: el inicio ya no tiene el botón, y desde "Becas de conectividad" el enlace abre el muro de esa campaña, sin mensaje de gracias.
- **Qué se corrigió:** al mergear el PR #27 se había perdido la fila de Daniel en la tabla de abajo; se restauró tal como estaba.
- **Aceleración estimada:** ~1 h.

### 33. Comprobante por correo con leyenda de factura (US-07)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-07 / SCRUM-136 (CA3 y CA4)
- **Qué se pidió:** que al confirmarse el pago el donante reciba un comprobante por correo, con la leyenda para pedir factura, sin depender de la cuenta de Stripe.
- **Qué se obtuvo:** la clase `MesaComprobante` (Queueable) que `confirmarPago` programa solo para los donativos que acaba de pagar; el correo lleva referencia, campaña, monto, fecha, id del pago y la leyenda de factura. El correo de facturación quedó en la etiqueta personalizada `Mesa_Correo_Facturas`. Se eligió un Queueable para que el correo corra en otra transacción, después del commit: si falla, el pago ya quedó confirmado (la misma regla de la sesión de automatización).
- **Qué se verificó y cómo:** 5 pruebas nuevas y las 58 existentes pasan en la org de desarrollo (63 en total), incluida una que confirma el mismo pago dos veces y espera un solo correo. Antes de escribir código se comprobó, sin enviar nada, que la sandbox UADY no permite enviar correos. En UADY, con Apex anónimo y deshaciendo los datos al final: el pago quedó en "Closed Won" y el envío falló con `NO_SINGLE_MAIL_PERMISSION` sin romper la confirmación.
- **Qué se corrigió:** el primer script de verificación no compiló porque leía un campo que solo ven las pruebas (`@TestVisible`); se cambió por el valor que devuelve el envío.
- **Aceleración estimada:** ~2 h.

### 34. ⚠ Error de la IA — el comprobante nunca llegó porque el correo salía como usuario guest (SCRUM-137)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-07 / SCRUM-137
- **Qué se pidió:** averiguar por qué, después de un pago de prueba real en el sitio, el correo del comprobante (entrada 33) no llegó, y arreglarlo.
- **Qué se obtuvo / qué falló:** la IA había dado por bueno el Queueable de la entrada 33 porque con un administrador el envío sí funcionaba. Pero el Queueable corre como quien lo programa, y en el pago real ese usuario es el guest del sitio, cuyo perfil y permission sets no tienen "Send Email" (`PermissionsEmailSingle = false`). El envío fallaba con `NO_SINGLE_MAIL_PERMISSION`, y el código atrapaba el error a propósito para no deshacer el pago, así que el trabajo terminó "sin error". La verificación de la entrada 33 probó el envío con otro usuario, no con el del pago real.
- **Qué se cambió:** se descartó dar "Send Email" al guest (más permisos para un visitante anónimo). `confirmarPago` ahora publica el evento de plataforma `Comprobante_Pago__e` (después del commit) y un trigger lo atiende como usuario interno (Automated Process). El resultado queda en `Opportunity.Comprobante_Estado__c` ("Enviado" o el código de error), que también evita un segundo envío si el aviso de Stripe se repite. `confirmarPago` no cambió: sigue llamando a `MesaComprobante.programar`.
- **Qué se verificó y cómo:** 6 pruebas de la clase pasan y las demás pruebas del proyecto también, en la org de desarrollo. En la sandbox UADY se publicó el evento para un donativo pagado y el trigger lo dejó en "Enviado". Pendiente: confirmar con un pago real que el guest puede publicar el evento (no se puede probar como guest desde Apex anónimo); si no pudiera, `Comprobante_Estado__c` quedaría vacío.
- **Segundo hallazgo (misma entrada):** con el trigger funcionando, el donativo quedaba en "Enviado" pero el correo no llegaba a Outlook. La dirección del usuario Automated Process es `autoproc@00d2e000000mhlwuae` (sin dominio); Salesforce acepta el envío pero el servidor receptor puede rechazar un remitente así (causa probable, aún sin confirmar con el registro de correo). Se agregó soporte para una dirección de toda la organización verificada (etiqueta `Mesa_Correo_Remitente`); si no existe, se envía como antes. La dirección la crea y verifica una persona en Setup.
- **Confirmado y mejorado:** con la dirección `contact.devxstudio@gmail.com` verificada como dirección de toda la organización, el comprobante llegó a Outlook: la causa era el remitente. Después se rediseñó el correo (encabezado, monto destacado, botón al muro de la campaña, aviso de factura) y se corrigió el saludo: decía "Hola, Anónimo" porque el contacto se había creado antes en un donativo anónimo y conservó ese nombre; ahora el saludo usa el nombre público del donativo y, si no es confiable, va sin nombre. Queda pendiente, y es código de otros integrantes, que el sitio no actualiza el nombre de un contacto reutilizado.
- **Aceleración estimada:** ~1 h.

### 35. Feedback del panel: formulario más claro, mensaje de pago fallido y página de gracias (SCRUM-138, 139 y 140)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** US-02 / US-07 (CA2) — SCRUM-138, SCRUM-139 y SCRUM-140
- **Qué se pidió:** aplicar el feedback del panel (Gilbert, Andrea y Eduardo) a partir de la transcripción de la sesión: quitar "Paquete", no preguntar dos veces lo mismo a quien dona de forma anónima, redactar mejor la pregunta de avisos, explicar qué pasó cuando el pago falla y agradecer mejor después de pagar.
- **Qué se obtuvo:** las opciones de monto dicen "$1,000 MXN", etc. Con visibilidad Anónima ya no aparece la casilla de autorización del muro; al continuar se autoriza publicar solo «Anónimo» y el monto, y el texto lo dice. La pregunta de avisos ahora es "¿Podemos guardar tus datos para invitarte a futuras campañas?" (el panel señaló que ser anónimo no significa no guardar los datos). El mensaje de pago no completado distingue entre cancelar y rechazo del banco. La página de gracias, solo cuando el webhook ya confirmó el pago, muestra la referencia, avisa del comprobante por correo y enlaza a otras campañas.
- **Decisión que la IA tomaría en silencio y que se dejó explícita:** al ocultar la casilla, el formulario envía `consentimientoPublicacion = true` por el donante anónimo. Se hizo así porque el servidor exige ese valor y el reconocimiento y la tarjeta "Aportaciones anónimas" dependen de él; el servidor no cambió, y el texto en pantalla avisa de lo que se autoriza.
- **Qué se verificó y cómo:** desplegado y publicado en la sandbox UADY. Como visitante: las opciones dicen "$1,000 MXN"; con "Anónima" aparece el aviso y no la casilla; con "Pública" sí aparece la casilla. No se probó un pago completo (lo prueba el equipo con Stripe).
- **Lo que ya estaba resuelto:** el listado ya tenía las pestañas "Activas" y "Pasadas", y cada campaña ya tiene descripción propia en la org; por eso SCRUM-139 solo cambió el mensaje de pago fallido.
- **Aceleración estimada:** ~1 h.

### 36. Diagrama de objetos y guía de registros para la demo (SCRUM-142)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** documentación de la Entrega 2 — SCRUM-142
- **Qué se pidió:** el panel pidió a casi todos los equipos un diagrama de qué objetos se usan y cómo se relacionan, y mostrar los registros reales de la org.
- **Qué se obtuvo:** `docs/modelo_datos.md`, con un diagrama Mermaid, una tabla de qué es cada objeto (estándar o propio), las decisiones del modelo (Opportunity como donativo, Lookup contra Master-Detail, el muro leyendo de `Reconocimiento_Publico__c`) y cuatro consultas SOQL con un orden sugerido para la demo de 5 minutos.
- **Qué se verificó y cómo:** los objetos, campos y tipos de relación (Lookup o Master-Detail) se leyeron de los metadatos del repo, no de memoria. Las consultas no se ejecutaron todavía con datos de una demo real; falta ensayarlas después del pago de prueba.
- **Aceleración estimada:** ~45 min.

### 37. ⚠ Error de la IA — el Case con origen "Web" disparaba un proceso ajeno que lo rechazaba (SCRUM-141)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** feedback del panel (Andrea: "¿cómo se contactan con ustedes si algo pasó con su pago?") — SCRUM-141
- **Qué se pidió:** un formulario "¿Necesitas ayuda?" que cree un Case, sin dar permisos nuevos al usuario guest.
- **Qué se obtuvo:** el método `enviarAyuda` en `MesaRegalosController` (una clase a la que el guest ya tiene acceso y que corre en modo sistema, así que el guest no necesita permisos sobre Case), el componente `mesaAyuda` y un botón "¿Necesitas ayuda?" en el pie del sitio, que abre una ventana. Lleva campo trampa, validaciones, tope de 20 mensajes por hora y solo devuelve el número del Case.
- **Qué falló:** la IA marcó el Case con `Origin = 'Web'`, el valor estándar y obvio. Como visitante el formulario respondió "Ocurrió un error". Al reproducirlo como administrador apareció la causa: la sandbox trae un proceso antiguo (2020, `NuevoCasoDesdeFormularioCommunity`, de otra persona) que se dispara con todo Case de origen Web y manda una alerta de correo que falla (`CANNOT_EXECUTE_FLOW_TRIGGER`). Ese proceso no es del equipo y no se modificó (regla: solo sumar).
- **Qué se cambió:** el Case ya no lleva origen; se reconoce por el asunto "Ayuda desde el sitio" (también para el tope por hora). Hay una prueba que lo exige y un comentario en el código con el motivo.
- **Qué se verificó y cómo:** 59 pruebas de Apex pasan en la org de desarrollo (5 nuevas). En UADY, como visitante, el formulario creó el Case 00001012 y mostró su número; los Cases de prueba se borraron después.
- **Aceleración estimada:** ~1.5 h.

### 38. ⚠ Error de la IA — las tarjetas de monto no coincidían con lo que logra cada campaña (SCRUM-143)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** feedback del panel sobre el flujo de donación (Eduardo: "se siente como una pasarela de pagos", Andrea: pasos claros, Gilbert: menos clics) — SCRUM-143
- **Qué se pidió:** mejorar el flujo de donación con las recomendaciones del panel y mejorar el diseño visual.
- **Qué se obtuvo:** el formulario en tres pasos numerados (aportación, cómo aparecer, datos), tarjetas de monto y de visibilidad en lugar de botones sueltos, un panel de resumen de la causa (imagen, avance, personas que ya donaron, lo que logra el monto elegido y tres señales de confianza), el botón con el monto ("Donar $1,500.00 MXN") y una versión móvil donde el resumen se compacta. Es solo interfaz: el servidor, las validaciones y los permisos no cambiaron.
- **Qué falló:** la primera versión dejó las tarjetas de monto fijas ($1,000, $3,000 y $5,000) y el resumen buscaba un nivel de impacto con ese monto exacto. En la campaña de prueba los niveles son $250, $1,500 y $4,000, así que ninguna tarjeta explicaba nada y justo faltaba lo que el panel pidió (saber en qué se dona). Se vio al revisar la página como visitante. Además, un ajuste de CSS para móvil dejó una llave de más y hubo que reescribir ese bloque.
- **Qué se cambió:** las tarjetas salen de los niveles de impacto de la campaña (hasta cuatro, con su descripción) y, si la campaña no tiene, de los paquetes fijos. Un monto que no es un paquete viaja como "Otro monto", que el servidor ya valida (mínimo y máximo).
- **Qué se verificó y cómo:** desplegado y publicado en UADY; como visitante en escritorio y en móvil, con el monto que llega desde la página de la campaña ya elegido y el botón con el monto. No se probó el pago completo en esta pantalla (lo prueba el equipo con Stripe).
- **Aceleración estimada:** ~2 h.

### 39. Simplificar "Tus datos" y acomodar las tarjetas de monto (SCRUM-144)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** feedback del panel ("ya te dije que soy anónimo y me preguntas otra vez", "más simple, directo al grano") — SCRUM-144
- **Qué se pidió:** acomodar mejor las tarjetas de monto y hacer más simple el paso de datos, con el feedback de la clase.
- **Qué se obtuvo:** el paso 3 pasó de seis elementos a tres: correo, una casilla opcional "Quiero enterarme de futuras campañas" y "Acepto el aviso de privacidad" con su enlace en la misma línea. Se quitó la casilla "Autorizo que mi donativo se publique…": la opción "Con mi nombre" del paso 2 ahora dice que al elegirla se autoriza publicar nombre y monto. Nombre y Apellidos van lado a lado, los títulos de los pasos son más cortos y las tarjetas de monto quedan en filas parejas (una fila si caben, 2×2 si no).
- **Decisiones que la IA tomaría en silencio y que se dejaron explícitas:** (1) el consentimiento de publicación ya no es una casilla; el formulario envía `consentimientoPublicacion = true` en ambos modos y el texto de cada opción dice lo que se autoriza (el servidor no cambió y sigue exigiendo ese valor). (2) La casilla de novedades sin marcar guarda el consentimiento de avisos como «No»: el valor por defecto es no recibir, y recibir es una acción de la persona. (3) El enlace al aviso de privacidad sigue accesible, ahora dentro de la casilla.
- **Qué se verificó y cómo:** desplegado y publicado en UADY; como visitante se revisó cada paso con "Con mi nombre" elegido (campos de nombre lado a lado, correo y casillas) y las tarjetas de monto. El servidor no cambió. No se probó un pago completo.
- **Aceleración estimada:** ~1 h.

### 40. Formulario a la derecha y montos más flexibles (SCRUM-145)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** observación de uso sobre el flujo de donación — SCRUM-145
- **Qué se pidió:** analizar si el formulario debía ir a la derecha (el botón "Donar" de la página de la campaña está ahí y el cursor tenía que cruzar la pantalla), aplicar buenas prácticas de UI y UX y dar más flexibilidad a los montos, con "otro monto" más amigable.
- **Qué se obtuvo:** en escritorio el formulario pasa a la columna derecha, donde queda el cursor al pulsar "Donar", y el resumen de la causa a la izquierda; en móvil el resumen se compacta arriba. Los montos son tarjetas rápidas y compactas (los niveles de impacto de la campaña) más un campo "$ ___ MXN" siempre visible: elegir una tarjeta lo llena y se puede ajustar, y al escribir una cantidad que coincide con una tarjeta, esa se marca. Debajo hay un mensaje que dice qué alcanza a cubrir ese monto ("Con $1,200 alcanza para: …") o el mínimo, en rojo si no se llega.
- **Criterios de UX usados (principios generales, no datos medidos):** el control de acción queda donde está el cursor (ley de Fitts) y en la misma zona que el botón que llevó ahí (consistencia); los montos rápidos reducen escritura y el monto libre da control sin un clic extra; mostrar de inmediato lo que logra el monto refuerza el motivo de donar; el error aparece junto al campo, no al final.
- **Decisión que la IA tomaría en silencio y que se dejó explícita:** todo monto viaja ahora como monto libre (`paquete = 'Abierto'`), ya no como paquetes fijos `P1000/P3000/P5000`. El servidor ya validaba el monto libre (mínimo y máximo) y no cambió; las campañas sin niveles de impacto muestran montos comunes ($500, $1,000, $3,000 y $5,000).
- **Qué se verificó y cómo:** desplegado y publicado en UADY; como visitante en escritorio: la tarjeta de $500 llena el campo y se marca, escribir $1,200 quita la marca y actualiza el mensaje, y $50 muestra el mínimo en rojo; en móvil las tarjetas quedan en una fila. Un primer intento de revisar con tamaño de ventana emulado desacomodó los clics y se repitió con el tamaño normal. No se probó un pago completo.
- **Aceleración estimada:** ~1.5 h.

### 41. "Otro monto" en la página de la campaña y enlaces en el correo (SCRUM-146)
- **Fecha:** 2026-11-16
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** observaciones del equipo en el chat (Daniel) — SCRUM-146
- **Qué se pidió:** revisar lo que habían hecho Daniel y Joachín y continuar con los cambios que discutieron: que quien llega a "Lo que logra tu aportación" sepa que puede dar otro monto, y que el correo lleve un enlace al sitio y otro a la página de facturas.
- **Qué se obtuvo:** la revisión del repo y de Jira no encontró commits ni PRs nuevos de Daniel ni de Joachín desde la tarde (solo SCRUM-144 y 145 pasaron a Finalizado al mergear). Se agregó la tarjeta «Otro monto» (borde punteado) junto a los niveles de impacto de la página de la campaña, que lleva al formulario sin monto elegido. En el correo, el aviso de factura ahora tiene «Ver los pasos para pedir tu factura», que lleva a la página de facturas, y debajo del botón hay «Conocer las demás campañas» con el enlace al sitio. Ambos enlaces salen solo si la URL del sitio está configurada.
- **Una interpretación que se corrigió:** el mensaje del chat «apóyate de los pasos en esta página» no era claro; la IA no lo adivinó y se preguntó. La respuesta fue que se refería al correo y a la factura, y de ahí salió el enlace a la página de facturas.
- **Qué se verificó y cómo:** 10 pruebas de `MesaComprobanteTest` pasan en la org de desarrollo (una nueva para los enlaces). En UADY, como visitante, la tarjeta aparece en la campaña y lleva a `/registro?campana=…` sin `monto`. Se reenvió el correo de un donativo de prueba y se envió sin error.
- **Lo que no se tocó:** el scroll al error del formulario, que Daniel dijo que haría él.
- **Aceleración estimada:** ~45 min.

### 42. El error del formulario aparece junto al paso y la página baja sola (SCRUM-147)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** observación del equipo en el chat (Daniel) — SCRUM-147
- **Qué se pidió:** Daniel había dicho que haría el scroll al error del formulario; se pidió revisar si lo subió y, si no, arreglarlo.
- **Qué se obtuvo:** la revisión no encontró PRs ni commits suyos, así que se hizo aquí. El problema era real: todos los errores salían en un solo mensaje arriba de la página, lejos del botón, y nada desplazaba la vista. Ahora el error aparece dentro del paso con el problema (monto en el 1, forma de aparecer o nombre en el 2, correo o aviso en el 3) y los errores del servidor justo arriba del botón. Al fallar, la página baja sola hasta el mensaje y lo centra, y el mensaje desaparece en cuanto la persona edita algo. El banner superior queda solo para el estado de pago no completado.
- **Qué se verificó y cómo:** desplegado y publicado en UADY; como visitante se eligió un monto y "Anónima", se dejó el correo vacío y se pulsó Donar: apareció «Escribe un correo válido.» bajo el título del paso 3, la página pasó de 0 a 611 px de desplazamiento y el mensaje quedó dentro de la pantalla. Al escribir en el correo, el mensaje se quitó. No se probó un error del servidor. El servidor no cambió.
- **Aceleración estimada:** ~30 min.

### 43. Entradas de preguntas y reportes de José de la semana del 16 y 17 de noviembre (SCRUM-148)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** documentación de la Entrega 2 — SCRUM-148
- **Qué se pidió:** escribir las entradas de preguntas y reportes de José para la Entrega 2 (cada integrante necesita al menos una de esta semana).
- **Qué se obtuvo:** tres entradas nuevas (20: el comprobante no llegaba; 21: el formulario de ayuda fallaba por un proceso ajeno; 22: pregunta abierta sobre el consentimiento implícito), el encabezado con la semana S3 y una actualización de las entradas 18 y 19, que ya se resolvieron con Stripe Checkout.
- **Qué se verificó y cómo:** cada hecho sale de entradas de esta bitácora (33, 34, 37 y 39), de `docs/seguridad.md` y de los PRs #27, #30 y #33; no se escribió nada que no conste ahí. La entrada 22 queda como pendiente a propósito, porque la decisión no se confirmó con el cliente. Las entradas de Daniel y Fernando no se tocaron: las escribe cada uno.
- **Aceleración estimada:** ~30 min.

### 44. Correo de facturas real en la sandbox (SCRUM-149)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** cierre de la Entrega 2 — SCRUM-149
- **Qué se pidió:** poner una dirección real en lugar de `facturas@ejemplo.org` para la demo.
- **Qué se obtuvo:** el correo aparece en dos sitios, y se cambiaron los dos en la sandbox UADY: la etiqueta `Mesa_Correo_Facturas` (la usa el correo del comprobante) y la propiedad `correoFacturas` de la página de facturas, que vive en la configuración del sitio y no en el código. Se usó la cuenta del equipo que ya envía los comprobantes, para que las respuestas lleguen a un buzón que se controla. No se subió la dirección al repositorio.
- **Qué se verificó y cómo:** la página de facturas publicada muestra la dirección nueva. El correo del comprobante la toma de la etiqueta en el siguiente envío (no se reenvió uno).
- **Aceleración estimada:** ~15 min.

### 45. Pruebas de Apex que fallaban en la sandbox UADY por NPSP (SCRUM-150)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** reporte de Daniel en el chat ("hubo unas pruebas que parecen aplicar solo en la primera ejecución… tienen un tema de NPSP; a mí no me corrían ni antes de lo agregado") — SCRUM-150
- **Qué se pidió:** correr las pruebas para ver si fallan y por qué.
- **Qué se obtuvo:** en la sandbox UADY (que tiene NPSP) se corrieron las pruebas dos veces: 4 de las 74 fallan y **fallan igual las dos veces**, no solo la primera, todas en `MesaRegalosDonativoTest`. En la org de desarrollo (sin NPSP) pasaban. Había dos causas, ambas de NPSP y no del código de la app: (1) dos pruebas afirmaban que no se crean cuentas, pero NPSP crea solo la cuenta de hogar de cada contacto; (2) dos pruebas crean varios donantes en una transacción y los procesos de NPSP agotan el límite de 100 consultas. Se descartó que fuera culpa de los cambios de Daniel: su versión del archivo solo agrega el tipo de registro.
- **Qué se cambió:** la comprobación pasó a «no hay cuentas que no sean de un contacto», que se cumple con y sin NPSP; y en las dos pruebas pesadas las donaciones del escenario comparten persona (menos contactos nuevos) y la verificación corre dentro de `Test.startTest/stopTest`. La intención de cada prueba se conserva.
- **Qué se verificó y cómo:** la clase pasa 23 de 23 en la org de desarrollo y, en una validación sin guardar contra la sandbox UADY con la versión de Daniel más estos cambios, 23 de 23. No se desplegó nada a UADY para no pisar su trabajo. Un primer intento con solo `Test.startTest` no bastó (seguía pasándose del límite en la preparación); compartir contactos sí.
- **Aceleración estimada:** ~1 h.

### 46. ⚠ Error de la IA — encabezado con navegación, nombres de campañas y campañas primero (SCRUM-151)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** feedback del panel y revisión de los sitios de los equipos 1, 2, 4, 5 y 6 — SCRUM-151
- **Qué se pidió:** mejorar la interfaz para que en móvil sea más amigable y en la web tenga mejor navegación, tomando lo que gustó de los demás equipos y lo que dijo el panel sobre el uso de «campaña».
- **Qué se observó en los demás equipos:** el Equipo 4 tiene encabezado con marca y pestañas «Campañas / Campañas pasadas», un aviso junto a Donar («el pago se hace en una pasarela externa, no necesitas cuenta») y la nota de que solo aparecen quienes eligieron ser reconocidos; el Equipo 1, una cuadrícula limpia con «Activa», avance y «Cierra el…»; el Equipo 6, contador y avance temáticos, «¿para qué se usará el dinero?» y montos más campo libre (se le criticó la legibilidad); el Equipo 5, un diagrama de arquitectura muy elogiado. Del Equipo 2 solo se vio el panel de administración.
- **Qué se obtuvo:** un encabezado nuevo (`mesaEncabezado`) con marca, «Campañas activas», «Campañas pasadas», «Quién ya se sumó», «Facturas», «Ayuda» y el botón Donar, y un menú desplegable en móvil. Las pestañas del listado ahora se llaman «Campañas activas» y «Campañas pasadas», como pidió el panel, y el encabezado abre la pestaña con `?pestana=` y baja a la lista. En el inicio, las campañas van justo debajo de la portada y los pasos y la información quedan debajo. Se agregaron frases de confianza junto a Donar y en el muro. No cambió el servidor.
- **Decisión sobre el nombre:** en español se conserva «campaña»; lo que se corrigió fue el genérico «Campañas», que no decía qué lista era. Para la presentación en inglés se usa *fundraising campaign* y no *campaign* a secas (ya anotado en las notas de la presentación).
- **Qué falló (error de la IA):** (1) se supuso que el componente principal de todas las páginas estaba en la región «header» del sitio, pero en el muro, el registro y las facturas está en «content»; el primer intento falló al editar esas páginas. (2) El encabezado se hizo con `position: sticky` y en la página de la campaña se iba al bajar; se cambió a `position: fixed` con un espacio reservado. (3) El desplazamiento automático a la lista falló tres veces (esperar a los datos, un retraso corto, un `console.log` para depurar) hasta ver que el componente no vuelve a pintarse con los datos y que la página vuelve arriba si se baja antes de terminar de cargar; funciona con una sola espera de 1.3 s tras el primer pintado.
- **Qué se verificó y cómo:** desplegado y publicado en UADY; como visitante, el encabezado aparece en inicio, campaña, muro, registro y facturas, no tapa el contenido (el contenido empieza justo debajo) y se queda arriba al bajar; el menú móvil abre, marca la página actual y «Ayuda» abre la ventana; `?pestana=pasadas` selecciona la pestaña y baja a la lista. No se probó un pago completo. Las páginas del sitio (Experience Builder) no están en el repositorio: el encabezado se agregó a las 5 páginas desde la configuración del sitio.
- **Ajuste de tamaños y distribución (mismo día, a pedido de José):** se midieron los tamaños reales y el botón «Donar» salía en 13 px frente a 15.2 px de los enlaces (el tema reduce la letra de los botones); ahora la escala es explícita: enlaces y Donar 16 px, nombre del sitio 18 px, frase 13 px, y en el menú móvil 18 px con filas de 53 px. El menú pasa a hamburguesa a 1,200 px (a 1,210 px todo cabe en una línea, con 40 px entre la marca y los enlaces) y en móvil el botón Donar queda **visible en la barra**, junto al menú, de 44 px de alto como mínimo. Se comprobó sin desbordes a 320, 375, 768, 1,210 y 1,366 px; a 320 px se oculta el nombre y queda solo el ícono.
- **Portada compacta en móvil (mismo día):** a pedido de José, la portada del inicio se compactó en pantallas chicas (título más chico, sin la frase de abajo y sin el botón «Quiero donar», porque «Donar» ya está en la barra): pasó de unos 575 px a 249 px y la primera campaña queda en el px 576 de 812, visible en la primera pantalla. Al verificarlo apareció un error de la IA en la lista de campañas, que tiene su propia entrada (47).
- **Aceleración estimada:** ~3 h.

### 47. ⚠ Error de la IA — un reemplazo borró la línea que pedía las campañas y la lista quedó en «Cargando» (SCRUM-151)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-151 (encabezado y navegación del sitio)
- **Qué se pidió:** que la página de inicio bajara sola hasta la lista de campañas cuando se llega desde el encabezado con `?pestana=activas` o `?pestana=pasadas`.
- **Qué falló:** para ajustar `renderedCallback` en `mesaCampanas`, la IA reemplazó un tramo del archivo con un script que cortaba desde el inicio de esa función hasta la siguiente línea de referencia (`get hayError()`). Esa zona incluía `@wire(obtenerCampanas) campanas;`, la línea que pide las campañas al servidor, y se borró sin que nadie lo notara: no hubo error de compilación (el despliegue salió bien) ni mensaje en la consola. Resultado: la lista se quedaba en «Cargando campañas…» para siempre y el sitio publicado no mostraba ninguna campaña. Esa versión llegó a subirse al PR #43. Un segundo error en cadena: al restaurar los datos, el desplazamiento automático dejó de funcionar, porque la IA guardaba el elemento de la lista y, al llegar los datos, la lista se vuelve a pintar y el elemento guardado quedaba desconectado.
- **Cómo se detectó:** al verificar la portada compacta como visitante, `li.campana` daba 0 tarjetas después de 20 segundos con «Cargando campañas…» en pantalla. La consulta a Apex como administrador devolvía las 5 campañas, así que el problema no era el servidor ni los datos. Se desplegó temporalmente la versión anterior de `mesaCampanas` (cargaba las 5 campañas al instante) y la comparación con `git diff` mostró la línea faltante.
- **Qué se cambió:** se restauró la línea `@wire(obtenerCampanas)`; el archivo quedó con solo líneas agregadas respecto a `entrega-1` (se comprobó con `git diff --stat`, sin eliminaciones). El desplazamiento ahora busca la lista de nuevo en el momento de bajar.
- **Qué se verificó y cómo:** como visitante con el tamaño de un teléfono, las 5 campañas cargan, la portada mide 249 px y `?pestana=activas` baja solo hasta las pestañas, que quedan debajo del encabezado fijo.
- **Lección para el proceso:** no editar archivos con reemplazos por posición sin revisar el `git diff` después, y verificar que la lista **cargue datos**, no solo que la página abra: este error pasó el despliegue y no deja rastro en la consola.
- **Aceleración estimada:** no aplica (tiempo perdido: ~30 min).

### 48. ⚠ Error de la IA — el muro en la barra general y dos enlaces para la misma lista (SCRUM-152)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** observaciones de Daniel en el chat sobre el encabezado nuevo — SCRUM-152
- **Qué se pidió:** revisar lo que dijo Daniel de la barra de navegación: que debía decir solo «Campañas» (con el filtro «Activas / Pasadas» dentro de la página) y que «Quién ya se sumó» no iba en la pantalla general.
- **Qué falló (error de la IA):** (1) la IA puso en la barra «Campañas activas» y «Campañas pasadas» como dos enlaces a la misma página, copiando el estilo del Equipo 4, sin ver que el panel había señalado justo lo contrario: no llamar «Campañas» a una lista que solo trae las activas, y que un solo «Campañas» con un filtro adentro lo resuelve. (2) Puso «Quién ya se sumó» en la barra y en el pie del sitio general, aunque el muro es de **cada campaña** y esa decisión ya estaba tomada: en SCRUM-135 se había quitado el botón del muro del inicio. Sin una campaña en la dirección, ese enlace no lleva a ningún muro concreto. Daniel lo vio al revisar capturas; la IA no lo contrastó con la decisión anterior.
- **Qué se cambió:** la barra tiene un solo «Campañas»; el filtro queda dentro de la página como «Activas» y «Pasadas» (la dirección `?pestana=` sigue funcionando). El enlace al muro aparece solo cuando hay una campaña en la dirección y se llama «Muro de esta campaña», con el Id de esa campaña, tanto en la barra como en el pie.
- **Qué se verificó y cómo:** como visitante en UADY: en el inicio la barra es «Campañas, Facturas, Ayuda, Donar», el pie no trae el muro y las pestañas dicen «Activas» y «Pasadas»; en la página de una campaña la barra y el pie traen «Muro de esta campaña» con el enlace `/muro?campana=<Id>`. No se probó el flujo de pago.
- **Un hallazgo de paso:** la lista pública muestra ahora una campaña de prueba, «Prueba Campaign Desde Admin Panel», que Daniel creó desde el panel de administración. Confirma que el panel crea campañas con el tipo `Donacion` y salen en el sitio; hay que desactivarla antes de presentar.
- **Aceleración estimada:** ~30 min.

### 49. Diagrama de arquitectura y actualización de los documentos de la Entrega 2 (SCRUM-153)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** retroalimentación del panel (el diagrama de arquitectura del Equipo 5 fue lo más elogiado) y cierre de la Entrega 2 — SCRUM-153
- **Qué se pidió:** un diagrama de arquitectura para la presentación y actualizar backlog, seguridad y contribución con lo de hoy.
- **Qué se obtuvo:** `docs/arquitectura.md` con un diagrama de las piezas (navegador, Stripe y Salesforce), un diagrama de secuencia de un pago, una tabla de quién corre cada cosa (guest, webhook, usuario interno, personal), las decisiones que conviene saber explicar, dónde queda cada dato y un guion de demo de cinco minutos. El backlog se recalculó con los estados de Jira del día: la Entrega 1 baja de 8 a **6 de 15 (40 %)** porque US-02 y US-10 volvieron a *En curso* en Jira (las movió el equipo), y la Entrega 2 queda en 1 de 6 (17 %). Se agregó la evidencia de los PRs #33 a #44, los PRs a la tabla de contribución y un riesgo nuevo en `seguridad.md`: el código desplegado en UADY es distinto del repo (el filtro por tipo de registro de campaña no está en ningún PR).
- **Qué se verificó y cómo:** lo que afirma el diagrama se contrastó con el código (la ruta `/stripe/webhook`, la tolerancia de 300 s de la firma, el id de pago de Stripe único en la Opportunity, el evento `Comprobante_Pago__e` con publicación después del commit y la clase que lo atiende). El avance se calculó con la consulta a Jira del 17 de noviembre, no con el documento anterior. Los diagramas se revisaron renderizados en GitHub.
- **Una decisión que la IA habría tomado en silencio:** bajar el porcentaje de la Entrega 1 en lugar de dejar el anterior. Se hizo porque el documento dice que sigue lo que marque Jira; si el equipo prefiere otro criterio, se cambia con la nota que explica el cálculo.
- **Aceleración estimada:** ~1 h.

### 50. Etiquetas de cierre y meta en las tarjetas, y preguntas frecuentes (SCRUM-154)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** retroalimentación del panel (confianza y urgencia para el donante) — SCRUM-154
- **Qué se pidió:** etiquetas «Cierra en N días» y «Meta superada» en las tarjetas de campaña, y una sección corta de preguntas frecuentes en el inicio.
- **Qué se obtuvo:** una etiqueta en `mesaCampanas` (solo campañas activas; «Cierra en N días» cuando faltan 7 o menos, «Cierra hoy», «Cierra mañana» y «Meta superada» cuando lo recaudado alcanza la meta) y seis preguntas en `mesaInicio` con `<details>` nativo, accesible con teclado.
- **Qué se verificó y cómo:** como visitante en UADY, las 5 campañas cargan (se comprobó que `li.campana` > 0, por la lección de la entrada 47), 2 tienen la etiqueta «Cierra en 3 días» y las 6 preguntas se muestran. Las respuestas se contrastaron con el comportamiento real: pago pendiente que no suma al avance, «Anónimo» con monto en el muro, correo solo para el comprobante.
- **Una decisión que la IA tomó en silencio:** mostrar la etiqueta solo en los últimos 7 días, para que no aparezca en todas las campañas. Se quitó además la leyenda «Faltan N días» cuando ya hay etiqueta, porque repetía lo mismo.
- **Aceleración estimada:** ~40 min.

### 51. ⚠ Error de la IA — el botón «Quiero donar» del pie llevaba a la primera campaña (SCRUM-155)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** reporte de Daniel en el chat del equipo — SCRUM-155
- **Qué se pidió:** revisar lo que dijo Daniel: el botón «Quiero donar» del pie no llevaba a la sección de campañas.
- **Qué falló (error de la IA):** al construir el pie, la IA dejó la página de donación por defecto en `registro`, que dona a la primera campaña, sin comprobar a dónde llevaba el enlace. En la portada el mismo botón sí baja a la lista; el pie no coincidía. Pasó las verificaciones anteriores porque solo se revisó que el pie se viera, no el destino de sus enlaces.
- **Cómo se detectó:** lo vio una persona del equipo al usar el sitio, no la IA.
- **Qué se cambió:** `mesaPie.js` lleva «Quiero donar» y el enlace «Donar» a Inicio con `?pestana=activas`, que baja a la lista de campañas activas.
- **Qué se verificó y cómo:** como visitante en UADY, ambos enlaces apuntan a `/mesaregalos/s/?pestana=activas` y las 5 tarjetas siguen cargando.
- **Lección para el proceso:** al terminar un componente, comprobar el destino de cada enlace y botón, no solo que se vea.
- **Aceleración estimada:** no aplica (arreglo de ~10 min).

### 52. Vista de escritorio: tres campañas por fila, portada más vistosa y marca «Comunidad Salesforce» (SCRUM-156)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-156 — pulido para la presentación
- **Qué se pidió:** tres campañas a la vez en escritorio, una portada más amigable y vistosa, y en el encabezado «Comunidad Salesforce» con «Facultad de Matemáticas» debajo y un ícono relacionado con Salesforce en lugar del corazón.
- **Qué se hizo:** `mesaEncabezado` (marca, lema y un ícono de nube; valores por defecto también en el `.js-meta.xml`), `mesaCampanas.css` (3 columnas desde 1100 px, 2 entre 900 y 1099 px, tarjetas blancas con elevación y zoom suave de la imagen al pasar el cursor) y `mesaInicio.css` (portada más grande en escritorio y burbujas que flotan despacio). Todo el movimiento se apaga con «reducir movimiento».
- **Decisión de la IA que conviene saber:** se usó una nube genérica, no el logotipo de Salesforce, que es marca registrada.
- **Qué se verificó y cómo:** como visitante en UADY (1440 px): marca y lema nuevos, 5 tarjetas en 3 columnas (378 px cada una). En 390 px sigue una sola columna y no hay desborde horizontal.
- **Qué no se verificó:** pantallas entre 900 y 1099 px (2 columnas) ni otros navegadores; las propiedades del encabezado guardadas en Experience Builder podrían pisar los valores por defecto (aquí se vieron los nuevos).
- **Aceleración estimada:** no aplica (cambio visual de ~30 min).

### 53. Preguntas frecuentes: centradas, en dos columnas y con flecha (SCRUM-157)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-157 — pulido para la presentación
- **Qué se pidió:** acomodar mejor las preguntas frecuentes, con una flecha que indique que se abren, aprovechando el espacio y centradas.
- **Qué se hizo:** solo CSS de `mesaInicio`. La sección queda centrada (máx. 62 rem), en dos columnas desde 900 px y una en celular; cada pregunta lleva una flecha dibujada con bordes que gira al abrir, y el marcador nativo del navegador se oculta. Se conserva `<details>`/`<summary>`: abre con teclado y el alto táctil sigue siendo de 44 px.
- **Qué se verificó y cómo:** como visitante en UADY a 1440 px: sección centrada (224 px a cada lado), 2 columnas de 486 px, flecha presente y apuntando hacia arriba con la primera pregunta abierta (captura). A 390 px: una columna y sin desborde horizontal.
- **Qué no se verificó:** otros navegadores (el ocultar el marcador usa `list-style: none` y `::-webkit-details-marker`) ni lectores de pantalla.
- **Aceleración estimada:** no aplica (cambio visual de ~15 min).

### 54. «Donar» y «Campañas» bajan a la lista sin recargar la página (SCRUM-158)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-158 — observación de José al probar el encabezado
- **Qué se pidió:** al dar clic en «Donar» de la barra superior, la página cargaba (parecía ir a otra página) y hasta después bajaba; que no fuera así.
- **Causa:** los enlaces eran simples direcciones al inicio con `?pestana=activas`: aun estando en el inicio, el navegador recargaba la página y la lista esperaba 1.3 s antes de bajar. Era una decisión de la IA de una entrega anterior que no se probó haciendo clic estando ya en el inicio.
- **Qué se cambió:** estando en el inicio, el clic en «Donar» o «Campañas» (encabezado y pie, también en el menú móvil) avisa a `mesaCampanas` con un evento de la ventana; esa lista abre la pestaña y baja suavemente de inmediato. Si nadie atiende el aviso, o se está en otra página, el enlace navega como antes. Archivos: `mesaUtil`, `mesaEncabezado`, `mesaPie`, `mesaCampanas`.
- **Qué se verificó y cómo:** como visitante en UADY: tras el clic la dirección no cambia, una marca puesta en la ventana antes del clic sigue ahí (no hubo recarga) y la lista queda justo bajo la barra (100 px).
- **Qué no se verificó:** el menú móvil y el pie con clic real; desde otra página (campaña, facturas) sigue habiendo un cambio de página con la espera de 1.3 s al llegar, porque ahí navegar es inevitable. El panel del navegador estaba oculto, así que el tiempo de la animación (1.4 s) no es representativo.
- **Lección para el proceso:** probar un enlace estando en la misma página de destino, no solo viniendo de otra.
- **Aceleración estimada:** no aplica (arreglo de ~20 min).

### 55. Campañas: activas primero y pasadas plegadas al final, sin pestañas (SCRUM-159)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-159 — pulido para la presentación
- **Qué se pidió:** que Activas/Pasadas no fueran lo primero que se ve; una propuesta de cómo mejorarlo.
- **Qué se propuso y se eligió:** quitar las pestañas; título «Campañas activas» con la cuadrícula, y al final una sección plegable «Campañas pasadas (N)» con la misma flecha de las preguntas frecuentes. Se descartaron un interruptor «Activas · Todas» y mezclar todas con las cerradas atenuadas.
- **Qué se hizo:** solo `mesaCampanas` (HTML, CSS y JS). Las pasadas salen en filas compactas (nombre, fecha de cierre, «Cerrada» y lo recaudado), sin barra ni botón; si no hay pasadas la sección no aparece. `?pestana=pasadas` abre la sección y baja a ella; `?pestana=activas` y los clics de «Donar»/«Campañas» siguen bajando al título. Sin cambios de Apex.
- **Qué se verificó y cómo:** como visitante en UADY: sin pestañas, título «Campañas activas», 5 tarjetas con botón y sin sección de pasadas (hoy ninguna campaña ha cerrado); el aviso de «Campañas» baja y deja el título a 100 px de la barra.
- **Qué no se verificó:** el aspecto de la sección de pasadas desplegada, porque en el sandbox no hay campañas cerradas (no se alteraron datos de otros); tampoco la bajada al llegar desde otra página con `?pestana=` (el panel del navegador estaba oculto y el desplazamiento no se completó en la prueba).
- **Aceleración estimada:** no aplica (cambio visual de ~30 min).

### 56. Panel interno: Resumen, Campañas, Moderar muro y Donativos con el diseño del sitio (SCRUM-160)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-160 — pulido para la presentación
- **Qué se pidió:** que la app interna de Salesforce se vea como el panel de otro equipo (barra lateral y páginas propias), pero con nuestro estilo, para trabajar más práctico. En una segunda pasada, José señaló que faltaban las demás secciones.
- **Qué se hizo:** componente `mesaPanelAdmin` (barra lateral azul, tarjetas redondeadas, mismos colores que el sitio) en una pestaña `Panel_Admin` y una app nueva `Mesa_Panel`, con cuatro secciones: **Resumen** (recaudado, activas, muro visible/oculto, avance, últimos reconocimientos), **Campañas** (tarjetas con avance, filtros, Nueva, Editar y Pausar/Reactivar), **Moderar muro** (filtros, Editar nombre y Ocultar/Mostrar) y **Donativos** (filtros pagados/pendientes y Ver). Datos: `MesaPanelController` (`with sharing`, `WITH USER_MODE`) con su prueba; las escrituras usan `updateRecord`, que respeta los permisos de cada persona.
- **Decisiones que tomó la IA y quedan a la vista:** (1) la primera entrega solo hizo Resumen y dejó las demás secciones como atajos a las listas estándar; José lo notó, no la IA; (2) app nueva en vez de editar `Gestion_Donation_Campanas`, porque el PR #48 de Daniel la modifica; (3) no se tocaron permission sets: la app y la pestaña se activaron a mano en el perfil Administrador del sistema (lo hizo José); (4) el recaudado cuenta solo `Closed Won`, igual que el sitio; (5) «ocultar» cambia `Mostrar_En_Muro__c`, no borra, como pidió Daniel.
- **Qué se verificó y cómo:** despliegue a UADY sin errores; prueba Apex pasa (2/2); en Chrome, con sesión de José, las cuatro secciones cargan con datos reales (13 donativos en México Dreamin, 5 campañas activas y 1 pausada, reconocimientos «Anónimo» sin campaña visibles).
- **Qué no se verificó:** los botones que escriben (Pausar, Reactivar, Ocultar, Mostrar), para no alterar datos de demostración; el acceso de los roles Gestor, Moderador y Tesorería; pantallas chicas; la sección Donativos solo en su primera pantalla.
- **Tercera pasada (paginación):** José advirtió que las listas de muro y donativos traían todo y que con millones de filas se saturarían. La IA había puesto `LIMIT 200` sin paginar: un tope que oculta filas, no una solución. Ahora muro y donativos se leen de a **20 filas** con **paginación por cursor** en el servidor (`CreatedDate` + `Id`, no `OFFSET`, que se topa en 2,000 filas), con total, «Página N de M», Anterior/Siguiente, filtros y buscador por nombre aplicados en la consulta. Campañas sigue cargando todas (son pocas).
- **Verificación de la paginación:** prueba Apex (2/2); en Chrome, donativos: 51 en total, páginas de 20 + 20 + 11 sin repetir filas, «Siguiente» se desactiva en la última, filtros (15 pendientes, 36 pagados) y búsqueda («Charritos» → 1); muro: 39 reconocimientos en 2 páginas.
- **No se verificó con millones de filas:** solo con 51 donativos y 39 reconocimientos. El conteo total (`COUNT()`) y la búsqueda con `LIKE '%…%'` pueden volverse lentos con millones; habría que revisar índices o usar búsqueda SOSL.
- **Cuarta pasada (revisión de las demás pestañas):** José pidió revisar que todo funcione. Hallazgos: (1) las pestañas estándar de la app (Campañas, Reconocimientos públicos, Oportunidades) abren «Vistos recientemente», que sale vacía mientras nadie haya abierto registros; no es un fallo de datos (la vista «Donación - Todas» de Daniel muestra las 6 campañas) pero se ve como si no hubiera nada; (2) Reportes y Tableros solo traen los de NPSP, no hay reportes ni tableros del proyecto; (3) **error de la IA:** «+ Nueva campaña» del panel abría el formulario viejo de NPSP (Tipo, Estado, «Student Registration Form») sin los campos del sitio, y una campaña creada así quedaría sin el tipo «Campaña de donación» que el #48 exige para publicarse. Corregido: el botón ahora busca el tipo de registro «Campaña de donación» y abre ese formulario; si no existe, abre el normal. Verificado en Chrome (cancelando sin guardar).
- **Decisión de José:** quitar de la app `Mesa_Panel` las pestañas que el panel ya cubre (Campañas, Reconocimientos públicos, Oportunidades); quedan Panel, Reportes y Tableros. Es solo la app nueva: `Gestion_Donation_Campanas` de Daniel no se tocó. Una persona que ya personalizó su barra de navegación seguirá viendo las pestañas viejas hasta restablecerla.
- **Reporte y tablero propios:** carpeta «Mesa de regalos» con el reporte «Recaudado por campaña» (oportunidades `Closed Won` con campaña, agrupadas por campaña) y el tablero del mismo nombre (total recaudado y barras por campaña). Tres errores de la IA al armarlos, corregidos tras probar en la org: (1) agrupó por `CAMPAIGN_NAME`, que no existe en el tipo de reporte Oportunidad (el campo es `CAMPAIGN_SOURCE`; se averiguó consultando los campos del tipo de reporte); (2) el reporte no sumaba el importe (faltaba `aggregateTypes` Sum) y los dos componentes del tablero salían con «uno o más campos ya no está disponible»; (3) el primer total daba $130 K contra los $124,411 del panel porque incluía donativos sin campaña; se agregó el filtro de campaña no vacía y ahora coincide: $124,411, 36 donativos, 5 campañas.
- **Qué no se verificó del reporte y el tablero:** el acceso de otros usuarios (la carpeta es pública de solo lectura, pero no se probó con otro perfil) ni el tablero con la actualización automática: se actualiza al abrirlo o con «Actualizar».
- **Aceleración estimada:** no aplica (~3.5 h entre las pasadas).

### 57. ⚠ Panel interno por permisos: cada persona ve solo lo que puede usar (SCRUM-161)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-161 — mientras el PR #48 de Daniel se corrige, adelantar el panel por roles sin tocar sus permission sets
- **Qué se hizo:** el menú del panel muestra Campañas, Moderar muro y Donativos solo si la persona puede leer Campaign, Reconocimiento_Publico__c u Opportunity; los botones de escribir (Nueva campaña, Editar, Pausar, Ocultar…) solo si puede crear/editar, y el Resumen oculta las tarjetas de lo que no puede ver. En Apex, `obtenerResumen` calcula cada parte solo si el objeto es legible (y con `WITH USER_MODE`), para que un moderador o tesorería no reciba errores. Los permisos se leen con la API de información de objetos de Salesforce, no con nombres de rol.
- **Error de la IA (⚠):** al pasar la lista de objetos a `getObjectInfos` usó un parámetro con nombre equivocado (`objectApis`, no `objectApiNames`). No dio error: no llegó ningún dato de permisos y el menú se quedó solo con «Resumen», es decir, un fallo silencioso que habría dejado a todos sin las secciones. Se detectó probando en Chrome; además se añadió un respaldo: si no se pueden leer los permisos, no se esconde nada (el servidor igual los aplica).
- **Qué se verificó y cómo:** despliegue sin errores; prueba Apex pasa; en Chrome con el usuario de José (todos los permisos) siguen apareciendo las 4 secciones, las 4 cifras, las 2 tarjetas, «Nueva campaña» y los botones de las campañas.
- **Qué no se verificó:** el panel con un usuario de permisos reducidos (moderador, gestor o tesorería): no se inicia sesión como otras personas ni se asignan permisos de prueba. Queda como prueba pendiente para quien tenga esos usuarios.
- **Aceleración estimada:** no aplica (~30 min).

### 58. ⚠ La tarjeta de pago y el resumen fijos quedaban bajo la barra de navegación (SCRUM-162)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-162 — observación de José al revisar la página de campaña (captura): la tarjeta de «Donar» se pegaba arriba y la barra le tapaba la cifra
- **Qué se pidió:** que lo que se queda fijo al bajar cuente la altura de la barra de navegación.
- **Causa (error de la IA, ⚠):** al agregar la barra de navegación fija (4 rem) en una entrega anterior no se revisaron los elementos que ya eran `position: sticky`; seguían con `top: 1.5rem` y `top: 1rem`, pensados para cuando arriba no había nada. Lo mismo para cualquier elemento fijo nuevo: hay que sumar la barra.
- **Qué se cambió:** `mesaCampanaDetalle` (tarjeta lateral): `top: calc(4rem + 1.5rem)`; `mesaRegistro` (resumen del formulario de pago): `top: calc(4rem + 1rem)`.
- **Qué se verificó y cómo:** como visitante en UADY a 1440 px, en la página de México Dreamin la tarjeta lateral queda a 88 px del borde al bajar a 600, 1100 y 1600 px de scroll, con la barra terminando en 65 px (antes quedaba a 24 px, bajo la barra).
- **Qué no se verificó:** el resumen de `mesaRegistro` con la misma medición ni los anchos de celular y tablet (a menos de 900 px la tarjeta lateral no es fija).
- **Aceleración estimada:** no aplica (cambio de ~10 min).

### 59. Datos de demostración del sandbox: nombres creíbles y reconocimientos huérfanos ocultos (sin ticket, datos de UADY)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Qué se pidió:** que los datos del sandbox se vean reales para el video y la demo (opción 1: renombrar, no borrar).
- **Qué se hizo (solo en el sandbox UADY, nada en el repo):** con un script de Apex anónimo, las 30 oportunidades «DEMO CAMPAÑAS | …» y «DEMO MURO | …» se renombraron al formato de las reales: «Donativo - {nombre público} - dd/mm/aaaa» (anónimas: «Donativo - Anónimo - …»). La donación pendiente «Donación pendiente (no debe verse)» de 99,000 pasó a «Rafael Ortiz» con 1,200 y sigue en etapa pendiente (no suma al recaudado). Los dos reconocimientos «Anónimo» sin campaña ($500 y $5,000, de pagos de prueba del 17 de nov.) se ocultaron del muro con `Mostrar_En_Muro__c = false`, sin borrarlos.
- **Qué se verificó y cómo:** 0 oportunidades «DEMO» restantes; el recaudado sigue en $124,411 (36 pagados con campaña); reconocimientos visibles 37 y ocultos 2 (antes 39 y 0).
- **Qué no se tocó:** los 30 contactos «Demo 01-alicia-publica…» y su cuenta (no se ven en el sitio ni en el panel; con NPSP además generan cuentas de hogar); dos oportunidades pendientes «Ana Demostración» de pruebas anteriores. Los nombres públicos de los reconocimientos ya eran personas y organizaciones ficticias creíbles.
- **Advertencia:** todos son datos de demostración ficticios. Si se vuelve a correr `scripts/apex/campanas-demostracion.apex` regresan los nombres «DEMO …». Cuando se cuente en la defensa, decir que son datos de prueba.
- **Aceleración estimada:** no aplica (~15 min).

### 60. Documento de arquitectura: el panel interno, el reporte y el tablero (SCRUM-163)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-163 — preparar el video de la defensa; el documento original (bitácora 49) salió de la retroalimentación del panel y solo cubría el sitio público
- **Qué se pidió:** actualizar la arquitectura con lo construido hoy.
- **Qué se hizo:** `docs/arquitectura.md` pasa de 6 a 7 secciones. Nueva sección 3 «El panel interno» con un diagrama (componente, `MesaPanelController`, API de registros, API de información de objetos, reporte y tablero) y una tabla de qué hace y cómo lo hace cada sección; una fila del panel en «Quién corre cada cosa»; cinco decisiones nuevas (solo se publican campañas del tipo «Campaña de donación», una campaña con pagos no se elimina, moderar es ocultar y no borrar, paginación por cursor, permisos por objeto y no por rol); y la demo de cinco minutos ahora incluye el panel y el tablero.
- **Qué se verificó y cómo:** cada afirmación nueva se contrastó con el código ya mergeado en `entrega-1` (`MesaPanelController`, `mesaPanelAdmin`, `MesaCampanaGuardia`, filtro de tipo de registro en `MesaRegalosController`).
- **Qué no se verificó:** que el diagrama nuevo se dibuje (Mermaid) en GitHub; se escribió con la misma sintaxis del existente. Tampoco se actualizaron backlog, seguridad ni contribución con los PRs #49 a #56.
- **Aceleración estimada:** no aplica (~20 min).

### 61. ⚠ El pie mostraba el enlace «Reencuentro» a una página que ya no existe (SCRUM-164)
- **Fecha:** 2026-11-17
- **Autor:** José Carlos Leo Fernández
- **Herramienta:** Claude Code (Anthropic)
- **Historia:** SCRUM-164 — revisión del funcionamiento del sitio pedida por José, antes de grabar el video
- **Cómo se encontró:** un script con un navegador sin login (Playwright con Chrome) recorrió inicio, campaña, muro y facturas y anotó respuestas 4xx y errores de consola. El pie del inicio traía «Reencuentro» → `/s/reencuentro`, que responde **404**. La página se eliminó cuando se quitó el flujo de token (bitácora 275 de la entrega anterior) pero el pie conservaba el enlace.
- **Error de la IA (⚠):** el primer arreglo cambió solo el valor predeterminado de la propiedad `paginaReencuentro` a vacío, dando por hecho que el sitio usaba el predeterminado. Se desplegó, se publicó y se volvió a probar: el enlace seguía, porque el sitio tiene guardado el valor `reencuentro` en su configuración. El arreglo que funcionó fue quitar la entrada del código del pie; la propiedad queda marcada como obsoleta para no romper la configuración guardada.
- **Qué se verificó y cómo:** como visitante en UADY, el pie ya no trae el enlace (comprobado con el mismo script). `/ayuda` también da 404, pero no es un fallo: «Ayuda» es un panel que se abre dentro de la página, no una página.
- **Qué no se verificó:** el pie en otras páginas (campaña, muro, facturas) con la misma comprobación ni en celular.
- **Aceleración estimada:** no aplica (~15 min).
## Pendiente por integrante

| Integrante | Entradas | Errores de la IA marcados |
|---|---|---|
| José Carlos Leo Fernández | 43 (1–9, 23–26 y 32–61) | 18 (entradas 1, 4, 5, 8, 9, 23, 24, 34, 37, 38, 46, 47, 48, 51, 56, 57, 58 y 61) |
| Fernando Joachín | 11 (entradas 10–15 y 27–31) | 5 (entradas 11, 13, 28, 29 y 30) |
| Daniel Amaya | 7 (16-22) | (16, 17, 19, 20, 21, 22) |

Requisito de la rúbrica: mínimo 3 entradas con error de la IA, incluyendo a los tres integrantes.
