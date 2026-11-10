# Seguridad y datos personales

Estado a **9 de noviembre de 2026** (Entrega 1). Todo lo que se ejecutó se corrió contra el sitio publicado
`https://orgfarm-ac7f623ac9-dev-ed.develop.my.site.com/mexicodreamingtest/` (Developer Edition, modo de prueba, datos ficticios).
La pasarela de pago aún no está integrada; se documenta en la Entrega 2 (sección 7).

## 1. Prueba del visitante sin login (M2)

**Objetivo:** un visitante sin sesión no puede leer ni modificar datos de otras personas; solo ve lo público.
Se probó con las campañas de prueba (sufijo "(prueba)") y sin sesión de Salesforce en ningún caso.

### Preparación
1. Abrir una ventana de incógnito o usar `curl` sin cookies ni encabezados de autorización.
2. Definir `B=https://orgfarm-ac7f623ac9-dev-ed.develop.my.site.com/mexicodreamingtest`.

### Pasos, resultado esperado y obtenido

| # | Paso | Esperado | Obtenido (9 nov 2026) |
|---|---|---|---|
| 1 | `curl -s -o /dev/null -w "%{http_code}" $B/s/` | Responde 200 sin pedir login | 200 |
| 2 | Abrir `$B/s/` en incógnito y recorrer inicio, campaña y facturas | Solo campañas, avance, muro (nombre y monto, o "Anónimo") y los formularios | Se ven campañas, avance, pasos informativos y la página de facturas; sin datos de donantes |
| 3 | **Leer por REST:** `curl -i $B/services/data/v62.0/sobjects/Opportunity` | Rechazado | 401 `INVALID_SESSION_ID` |
| 4 | **Leer por SOQL:** `curl -i "$B/services/data/v62.0/query?q=SELECT+Id+FROM+Opportunity"` (repetir con `Contact`) | Rechazado | 401 en ambos |
| 5 | **Apex REST:** `curl -i $B/services/apexrest/MesaRegalos` | No existe | 404 `NOT_FOUND` |
| 6 | **Modificar por REST:** `curl -i -X PATCH -H "Content-Type: application/json" -d '{"Amount":1}' $B/services/data/v62.0/sobjects/Opportunity/<Id>` | Rechazado | 401 |
| 7 | **Borrar por REST:** `curl -i -X DELETE $B/services/data/v62.0/sobjects/Opportunity/<Id>` | Rechazado | 401 |
| 8 | **Llamada directa a una clase Apex no expuesta** (`MesaRegalosService.confirmarPago`, por el canal Aura del sitio; ver abajo) | No disponible para el visitante | `No apex action available for MesaRegalosService.confirmarPago` |
| 9 | **Llamada directa a un método con token falso** (`obtenerInvitacion` con 64 caracteres inventados) | Rechaza sin revelar datos | Error: "Este enlace no es válido…" |
| 10 | **Campaña pausada** (`obtenerCampana` con su Id) | No devuelve datos | Resultado nulo |
| 11 | **Muro** (`obtenerMuro` con el Id de cada campaña de prueba) | Solo nombre, generación y monto de quien autorizó el reconocimiento | Listas vacías (ver "Límites de la prueba") |

**Cómo repetir los pasos 8 a 11 (llamadas directas a Apex).** En la consola del navegador, con el sitio abierto en incógnito,
leer el `fwuid` del código fuente de la página y enviar un POST a
`/mexicodreamingtest/s/sfsites/aura?r=1&aura.ApexAction.execute=1` con `credentials: 'omit'` y un mensaje de acción
`aura://ApexActionController/ACTION$execute` cuyo `classname` y `method` sean los de la tabla. El visitante usa el mismo canal
que el sitio, así que lo que no devuelve este canal no puede leerlo desde fuera.

### Evidencia
Salidas de `curl` y de la consola del navegador del 9 de noviembre de 2026 (códigos y mensajes de la tabla).
**Pendiente:** adjuntar capturas de pantalla en `docs/evidencia/` antes de la entrega.

### Límites de la prueba (lo que no se demostró)
- La org de prueba **no tenía donantes con reconocimiento**, por lo que el paso 11 devuelve listas vacías. Falta repetirlo con
  una donación privada y una anónima para comprobar que **no aparecen** en el muro. La consulta solo lee
  `Reconocimiento_Publico__c` con `Mostrar_En_Muro__c = true`, así que debería cumplirse, pero no está demostrado.
- No se probó el envío del formulario público (registro) con abuso real; el freno existente se describe en la sección 5.

## 2. Permisos del usuario visitante (guest) y por qué

| Elemento | Permiso | Por qué |
|---|---|---|
| Clase `MesaRegalosController` | Acceso habilitado | Es el único canal del sitio: expone solo datos públicos o con token |
| Clase `MesaRegalosService` | **Sin acceso** | Es lógica interna; el visitante no debe invocarla |
| Objetos `Contact`, `CampaignMember`, `Opportunity` | **Ningún permiso** | Contienen datos personales de donantes |
| Perfil guest `Mexico Dreaming Test Perfil` | Licencia Guest User, solo la clase anterior | Mínimo privilegio |
| Permission set `Mesa_Regalos_Admin` | Solo para el personal interno | Administra campañas, donativos y reconocimientos |

`MesaRegalosController` corre `without sharing` porque el visitante no tiene acceso a los objetos y la clase debe leer y crear
registros en su nombre. El riesgo se controla así: cada método valida el token o solo devuelve datos ya públicos (avance y muro),
y devuelve DTOs con los campos mínimos, nunca los registros completos. Cualquier método nuevo debe validar primero (está escrito
en el encabezado de la clase).

## 3. Claves de la pasarela

- **Hoy no hay claves en el proyecto:** la pasarela no está integrada.
- Se revisó el historial de commits completo buscando `sk_live`, `sk_test`, `pk_live`, `pk_test`, `whsec_`, `client_secret` y
  `api_key`. La única coincidencia es la línea de la lista de pendientes que describe esta misma búsqueda; no hay claves.
- **Plan para la Entrega 2:** las claves y el secreto de firma del aviso irán en la org (Custom Metadata o credencial con nombre),
  nunca en el código, el sitio ni el repositorio, y sin acceso para el usuario visitante.

## 4. Clasificación de datos personales

| Dato | Dónde | ¿Personal? | ¿Se guarda? | Para qué | Quién lo ve |
|---|---|---|---|---|---|
| Nombre y apellidos | `Contact` | Sí | Sí | Identificar al donante | Personal interno |
| Correo | `Contact` | Sí | Sí | Contacto y confirmación | Personal interno |
| Empresa (si dona como empresa) | `Contact` | Sí | Sí | Reconocimiento | Personal interno; público si autoriza |
| Generación, cuenta de Trailhead, certificaciones | `Contact` | Sí | Sí (opcional) | Reencuentro de la comunidad | Personal interno |
| Consentimiento de contacto, fecha y versión del aviso | `Contact` | No (registro legal) | Sí | Probar el consentimiento | Personal interno |
| Token de acceso | `CampaignMember` | Sensible (da acceso al enlace personal) | Sí | Enlace personal del donante | Solo el sistema |
| Monto, visibilidad, consentimiento de publicación | `Opportunity` | Sí (monto de una persona) | Sí | Registrar el donativo | Personal interno |
| URL de LinkedIn | `Opportunity` y `Reconocimiento_Publico__c` | Sí | Sí (opcional) | Reconocimiento | Público solo si autoriza |
| Nombre y monto del reconocimiento | `Reconocimiento_Publico__c` | Sí | Sí, solo si autoriza | Muro de donantes | Público |
| Datos fiscales (RFC, constancia) | **No se piden ni se guardan** | Sí | **No** | Factura por correo | Solo en el correo que el donante envía |

Decisión del 7 de noviembre: la factura no se pide en el formulario ni se almacenan datos fiscales; el donante escribe por
correo (ver la página de facturas).

## 5. Riesgos conocidos

| Riesgo | Estado | Mitigación o pendiente |
|---|---|---|
| **Spam en el formulario público** | Parcial | Campo trampa (`sitioWeb`): una persona nunca lo llena y, si llega con valor, no guarda nada; tope de 30 registros nuevos por hora (`maxRegistrosPorHora`). Falta validación más estricta del correo y revisión de duplicados |
| Datos personales en los registros de depuración | **Abierto** | `registrarPromesa` y `actualizarDatos` escriben `System.debug` con los datos recibidos. Debe quitarse antes de la Entrega 2 |
| Clase `without sharing` | Aceptado | Documentado en la sección 2; cualquier método nuevo debe validar primero |
| Montos y paquetes duplicados entre Apex y el componente de donación | Abierto | Centralizarlos en un solo lugar |
| Imágenes de campaña desde enlaces externos | Mitigado | Solo se aceptan enlaces `https`; si la imagen no carga se oculta |
| Ids de campaña inventados en la dirección | Mitigado | `obtenerCampana` valida el formato y el tipo, y devuelve nulo si la campaña no está publicada |
| Correo de facturas de ejemplo (`facturas@ejemplo.org`) | Abierto | Sustituirlo por el real antes de entregar |

## 6. Cómo comprobar que no hay claves en el código

Ver la sección 3 para el historial y, para el código vigente, `git grep -inE "sk_|pk_|whsec_|secret" -- force-app`
(sin resultados al 9 de noviembre).

## 7. Entrega 2 (pendiente de actualizar)

Aviso de la pasarela: dónde se guarda el secreto de firma, cómo se rechazan avisos falsos o repetidos, y los permisos del
usuario de integración que lo recibe.
