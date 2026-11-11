# Contribución del equipo

Qué hizo cada integrante, ligado a tickets de Jira y con evidencia (commits y PR). Una tabla por hito.
Estado a **10 de noviembre de 2026**. Los hashes son de commits del repositorio; los PR están en el fork de entrega.

> **Cómo leer esto:** solo se anota lo que se puede comprobar en el historial o en Jira. Lo que cada integrante hizo fuera
> de Git (reuniones, pruebas, decisiones, Jira) lo completa y confirma esa persona; no se redacta por ella.
> Parte del código de José se hizo con asistencia de IA (ver `docs/bitacora_ia.md`); todo se revisó y puede explicarse en la defensa.

## Entrega 1 (martes 10 de noviembre)

### José Carlos Leo Fernández

| Qué | Ticket | Evidencia |
|---|---|---|
| Lista de pendientes contra la rúbrica | — | `95f29d9`, [PR en el repo original](https://github.com/amaya7398/donaciones_mexico_dreaming/pull/1) |
| Backlog y respuestas del cliente (Discovery Day) | — | `02bb840` |
| Endpoint `obtenerCampanas` y componente `mesaCampanas` (sitio central con todas las campañas) | SCRUM-5 (US-01) | `b60fa2b`, `fde0f95` |
| Campo de imagen por campaña y mejora de la lista (imagen, descripción, dos columnas) | SCRUM-5 | `04ebadf`, `ac78317` |
| Pie de página `mesaPie` | SCRUM-86 (US-20) | `59028e3` |
| Página de detalle de campaña, endpoint `obtenerCampana` y 4 pruebas nuevas | SCRUM-8 (US-02) | `47917b9`, [PR #3](https://github.com/FernandoJoachin/donaciones_mexico_dreaming/pull/3) |
| Landing del inicio y título del sitio | SCRUM-5, SCRUM-86 | `7168371`, PR #3 |
| Página de facturas y enlace en el pie | SCRUM-86, SCRUM-128 | `6314b9f` (rama `SCRUM-128-US-20-Pagina-de-facturas`, sin PR todavía) |
| `docs/bitacora_ia.md` | SCRUM-87 | `d749a85`, [PR #4](https://github.com/FernandoJoachin/donaciones_mexico_dreaming/pull/4) |
| `docs/seguridad.md` y ejecución de la prueba del visitante | SCRUM-90, SCRUM-82 | `1764a13`, [PR #5](https://github.com/FernandoJoachin/donaciones_mexico_dreaming/pull/5) |
| README: backlog y cálculo del avance | SCRUM-91 | `ec18d74`, [PR #6](https://github.com/FernandoJoachin/donaciones_mexico_dreaming/pull/6) |
| Transcripción de la reunión del 7 de noviembre y conciliación de las historias en Jira | SCRUM-86, SCRUM-77, SCRUM-62, SCRUM-7 y otras | Historial de cambios de cada historia en Jira |
| Este documento | SCRUM-88 | PR de `docs/contribucion.md` |

### Daniel Amaya

| Qué | Ticket | Evidencia |
|---|---|---|
| Base del proyecto: objetos, Apex, componentes y README | — | `bb0e7d6` |
| Pantallas de inicio, registro, reencuentro, donación y muro | — | `3628d4e`, `fa30d36`, `e811b70`, `42980cc`, `b205cda` |
| Estilos compartidos (`mesaEstilos`) | — | `4905233` |
| Aviso de privacidad: enlace, ajustes y versión | — | `6bf0b40`, `5769218`, `f90064c`, `c75953c`, `0cdae1b` |
| Línea base de la versión 2 | — | `009c18a` |
| Backend sin token y con campos nuevos (cambios aditivos) | — | `b3e4b5d` |
| Formulario unificado (registro y donación) sin token | — | `c18e868` |
| Enlaces de pago de Stripe | — | `03788be` |
| Limpieza de campos, pruebas, componentes y metadatos de la versión 1 | — | `9ff15f9` |

*Daniel: completa la columna de tickets y agrega lo que hiciste fuera de Git.*

### Fernando Joachín

| Qué | Ticket | Evidencia |
|---|---|---|
| Proyecto de Jira y repositorio de entrega (fork) | — | Proyecto SCRUM en Jira y el fork `FernandoJoachin/donaciones_mexico_dreaming` |
| Pruebas del flujo de trabajo (rama, PR y Jira) | SCRUM-13, SCRUM-15 | PR 1 y PR 2 del fork (cerrados) |
| Redacción de las historias de usuario del proyecto () | Historias de usuario del proyecto | Trabajo en Jira, US-01 al US-10 |
| Creación de la historia de usuario del Muro de agradecimiento | SCRUM-49 (US-09) | [Ticket SCRUM-49](https://fernandojoachinp.atlassian.net/browse/SCRUM-49); confirmado por Fernando |
| Rama para implementar el Muro de agradecimiento y sus criterios | SCRUM-49 (US-09) | `feature/SCRUM-49-US-09-Muro-de-agradecimiento-de-la-campaña`; commits `b6ba03d`, `5884a25` |
| Automatizaciones de Jira para avanzar historias de usuario en el flujo del tablero | SCRUM-49 (US-09) | Configuración del proyecto Jira, confirmada por Fernando; no hay cambios de esa configuración en Git |
| Implementación del muro, datos de prueba y ajuste del CA8 | SCRUM-49 (US-09) | `b6ba03d`, `5884a25` |
| Aportación de Fernando a `docs/bitacora_ia.md` | SCRUM-87 | Entradas 10–14 y actualización de la fila de Fernando en la tabla |

*La redacción de las historias, las automatizaciones de Jira y la creación del ticket se documentan con base en la confirmación de Fernando; estos cambios de Jira no quedan registrados en commits del repositorio.*

## Entrega 2 (martes 17 de noviembre)

Se llena al cierre de la Entrega 2, con la misma estructura.
