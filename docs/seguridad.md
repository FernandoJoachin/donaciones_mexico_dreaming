# Seguridad y datos personales

Estado a **10 de noviembre de 2026** (Entrega 1), sobre el código **sin token** de `entrega-1` (formulario único de registro y
donación, enlaces de pago de Stripe) más las páginas de campañas de la rama de SCRUM-8. Lo que se ejecutó se corrió contra el sitio
publicado `https://orgfarm-ac7f623ac9-dev-ed.develop.my.site.com/mexicodreamingtest/` (Developer Edition, modo de prueba, datos
ficticios). El recorrido del visitante también se probó en la sandbox UADY (sección 1). El aviso automático de la pasarela (webhook)
aún no existe; se documenta en la Entrega 2 (sección 8).

## 1. Prueba del visitante sin login (M2)

**Objetivo:** un visitante sin sesión no puede leer ni modificar datos de otras personas; solo ve lo público.
Se probó sin sesión de Salesforce en ningún caso.

### Preparación
1. Abrir una ventana de incógnito o usar `curl` sin cookies ni encabezados de autorización.
2. Definir `B=https://orgfarm-ac7f623ac9-dev-ed.develop.my.site.com/mexicodreamingtest`.

### Pasos, resultado esperado y obtenido

| # | Paso | Esperado | Obtenido (10 nov 2026) |
|---|---|---|---|
| 1 | `curl -s -o /dev/null -w "%{http_code}" $B/s/` | Responde 200 sin pedir login | 200 |
| 2 | Abrir `$B/s/` en incógnito y recorrer inicio, campaña y facturas | Solo campañas, avance, información y formularios | Se ve lo esperado; sin datos de donantes |
| 3 | **Leer por REST:** `curl -i $B/services/data/v62.0/sobjects/Opportunity` | Rechazado | 401 `INVALID_SESSION_ID` |
| 4 | **Leer por SOQL:** `curl -i "$B/services/data/v62.0/query?q=SELECT+Id+FROM+Contact"` (repetir con `Opportunity`) | Rechazado | 401 |
| 5 | **Apex REST:** `curl -i $B/services/apexrest/MesaRegalos` | No existe | 404 `NOT_FOUND` |
| 6 | **Modificar por REST:** `curl -i -X PATCH -H "Content-Type: application/json" -d '{"Amount":1}' $B/services/data/v62.0/sobjects/Opportunity/<Id>` | Rechazado | 401 |
| 7 | **Borrar por REST:** `curl -i -X DELETE $B/services/data/v62.0/sobjects/Opportunity/<Id>` | Rechazado | 401 |
| 8 | **Clase interna:** llamar `MesaRegalosService.confirmarPago` por el canal Aura del sitio (ver abajo) | No disponible para el visitante | `No apex action available for MesaRegalosService.confirmarPago` |
| 9 | **Método retirado:** llamar `MesaRegalosController.obtenerInvitacion` (existía con el token) | No existe | `No apex action available for MesaRegalosController.obtenerInvitacion` |
| 10 | **Campo trampa:** `guardarDonativo` con `sitioWeb` lleno | Responde "Listo" sin guardar nada | `exito: true, mensaje: "Listo."`; no se creó ningún registro |
| 11 | **Campaña falsa:** `guardarDonativo` con el Id de una campaña inexistente | Rechaza | Error (estado `ERROR`) |
| 12 | **Lista de campañas:** `obtenerCampanas` | Solo nombre, descripción, meta, avance, fecha e imagen | Esos campos y nada más |
| 13 | **Muro:** `obtenerMuro` con el Id de una campaña de prueba | Solo nombre, monto y si es empresa | Lista vacía (ver "Límites de la prueba") |

**Cómo repetir los pasos 8 a 13 (llamadas directas a Apex).** En la consola del navegador, con el sitio abierto en incógnito,
leer el `fwuid` del código fuente de la página y enviar un POST a
`/mexicodreamingtest/s/sfsites/aura?r=1&aura.ApexAction.execute=1` con `credentials: 'omit'` y un mensaje de acción
`aura://ApexActionController/ACTION$execute` cuyo `classname`, `method` y `params` sean los de la tabla. El visitante usa el mismo
canal que el sitio, así que lo que este canal no devuelve no puede leerlo desde fuera.

### Evidencia
Salidas de `curl` y de la consola del navegador del 10 de noviembre de 2026 (códigos y mensajes de la tabla).
**Pendiente:** adjuntar capturas de pantalla en `docs/evidencia/` antes de la entrega.

### Límites de la prueba (lo que no se demostró)
- En la org de esta tabla el muro se probó **sin donantes con reconocimiento** (el paso 13 devuelve una lista vacía). Con donantes sí se
  comprobó en la sandbox UADY (ver "Prueba en la sandbox UADY" abajo), pero solo con datos de demostración.
- No se probó el tope de registros por hora ni la reutilización de un correo existente con datos reales (solo con pruebas de Apex).
- Los pasos de la tabla (REST, SOQL, PATCH, DELETE, `apexrest`) **no se repitieron** contra la sandbox UADY; allí solo se probó el
  recorrido del visitante en el navegador.

### Prueba en la sandbox UADY (10 de noviembre de 2026)
Sitio `https://uady--class2026e.sandbox.my.site.com/mesaregalos/s/`, abierto en un navegador **sin sesión** de Salesforce.

| Qué se probó | Resultado |
|---|---|
| Inicio, lista de campañas y detalle de campaña | Cargan para el visitante. Se ve el avance ($37,300 de 12 donativos pagados) y el muro |
| Formulario de donar (paquete $1,000, anónima, con consentimiento y aviso) | Registra el donativo y muestra "¡Gracias por sumarte!". Queda como `Prospecting` (pendiente) |
| Donativo pendiente en el muro y en el total | **No aparece** en ninguno; solo se publican los pagos confirmados (`confirmarPago`) |
| Envío sin autorización de publicación | El formulario lo rechaza y pide la autorización |
| Acceso del guest a Apex (consulta a `SetupEntityAccess` del perfil) | Una sola clase habilitada: `MesaRegalosController` |

Dos hallazgos de esa prueba:
1. **Un trigger ajeno impedía donar.** El visitante recibía "Ocurrió un error": el trigger `PreApproveStudent` (de otro proyecto de la
   sandbox) busca una campaña llamada `FONDOS SDU` que el usuario guest no puede ver, y al fallar cancelaba la donación. Un
   administrador no lo notaba, por eso las pruebas de Apex no lo detectaron. Se desactivó, con respaldo del trigger y su clase.
2. **Un dato de demostración se mostraba en el muro público.** Un reconocimiento de prueba de $99,000 ("Donación pendiente (no debe
   verse)") salía en la página. No lo creó el código (solo `confirmarPago` crea reconocimientos, y solo para pagos confirmados): se
   había cargado a mano. Se ocultó (`Mostrar_En_Muro__c` en falso) sin borrarlo.

El donativo de prueba (correo ficticio `prueba.visitante@example.com`, $1,000, pendiente) sigue en la sandbox.

## 2. Permisos del usuario visitante (guest) y por qué

| Elemento | Permiso | Por qué |
|---|---|---|
| Clase `MesaRegalosController` | Acceso habilitado | Es el único canal del sitio. Los métodos que el visitante puede llamar son `obtenerMuro`, `obtenerAvance`, `obtenerCampanas`, `obtenerCampana`, `guardarDonativo` y `darseDeBaja` |
| Clase `MesaRegalosService` | **Sin acceso** | Contiene `confirmarPago` y el avance de estados; solo debe usarlo el personal o un Flow |
| Objetos `Contact`, `CampaignMember`, `Opportunity` y `Reconocimiento_Publico__c` | **Ningún permiso directo** | Contienen datos personales y de pagos |
| Permission set `Mesa_Regalos_Admin` | Solo personal interno | Administra campañas, donativos y reconocimientos |

`MesaRegalosController` corre `without sharing` porque el visitante no tiene acceso a los objetos y la clase debe leer y crear
registros en su nombre. El riesgo se controla así: los métodos de lectura devuelven solo datos ya públicos y con campos mínimos
(DTO), nunca registros completos; los de escritura validan y limitan la entrada; y nada del sistema (Ids de contactos,
correos de otras personas) se devuelve al navegador. Cualquier método nuevo debe validar primero (está escrito en el encabezado de
la clase).

**En la sandbox UADY** el perfil del visitante es `Mesa de regalos Perfil`. El acceso público del sitio y el permiso sobre
`MesaRegalosController` los habilitó una persona del equipo desde la configuración de la org (no se automatizó). La consulta a
`SetupEntityAccess` confirma que la única clase habilitada es esa.

**Pendiente:** el perfil guest y el sitio (`Mexico Dreaming Test Perfil` en la org de pruebas y `Mesa de regalos Perfil` en la UADY,
con su red y sitio) no están en el repositorio; la lista de permisos de esta tabla sale de lo observado en las orgs y de la
prueba de la sección 1. Falta incluirlos en el respaldo de metadata.

## 3. Claves y datos de la pasarela

- **No hay claves en el proyecto.** Se revisó el historial de commits completo buscando `sk_live`, `sk_test`, `pk_live`,
  `pk_test`, `whsec_`, `client_secret` y `api_key`. Las únicas coincidencias son líneas de documentación que describen esta misma
  búsqueda; no hay claves.
- **Enlaces de pago de Stripe:** el componente `mesaRegistro` recibe la URL del enlace de pago como propiedad configurada en
  Experience Builder (`urlPago`, `urlPagoP1000`, `urlPagoP3000`, `urlPagoP5000`); no está escrita en el código. Un enlace de pago
  no es un secreto, pero debe ser de la cuenta en **modo de prueba** hasta la entrega final.
- **Qué viaja a Stripe en la dirección:** el Id del donativo (`client_reference_id`), el correo pre-rellenado del donante y, si
  aplica, el monto. Es lo mínimo que necesita el pago; no se envían datos fiscales ni de LinkedIn.
- **Plan para la Entrega 2:** el secreto de firma del aviso (webhook) irá en la org (Custom Metadata o credencial con nombre),
  nunca en el código ni el repositorio, y sin acceso para el usuario visitante.

## 4. Clasificación de datos personales

| Dato | Dónde | ¿Personal? | ¿Se guarda? | Para qué | Quién lo ve |
|---|---|---|---|---|---|
| Nombre y apellidos | `Contact` | Sí | Sí (en una donación anónima se ignoran los que envíe el navegador) | Identificar al donante | Personal interno |
| Correo | `Contact` | Sí | Sí | Contacto, confirmación y pago | Personal interno |
| Empresa (si dona como empresa) | `Opportunity.Nombre_Visible__c` y `Donacion_Empresa__c`; no se crean cuentas | Sí | Sí | Reconocimiento | Personal interno; público si la donación es pública |
| Nombre visible | `Opportunity.Nombre_Visible__c` | Sí | Sí | Cómo se muestra en el muro | Personal interno; público si la donación es pública |
| Visibilidad (Pública o Anónima) | `Opportunity.Visibilidad__c` | No | Sí | Decidir qué se muestra | Personal interno |
| Monto | `Opportunity.Amount` y `Reconocimiento_Publico__c.Monto__c` | Sí (monto de una persona) | Sí | Registrar el donativo y mostrarlo | Interno; **público siempre**, también en anónimo |
| URL de LinkedIn | `Opportunity.LinkedIn_URL__c` | Sí | Sí (opcional, solo en Pública) | Reconocimiento | Personal interno |
| Consentimiento de avisos, su fecha y la versión del aviso | `Contact` | No (registro legal) | Sí | Probar el consentimiento | Personal interno |
| Consentimiento de publicación y versión del aviso | `Opportunity` | No (registro legal) | Sí | Probar el consentimiento | Personal interno |
| Identificador del pago | `Opportunity.Stripe_Pago_Id__c` | Sensible (vincula con la pasarela) | Sí, cuando exista el webhook | Conciliar el pago | Personal interno |
| Datos fiscales (RFC, constancia) | **No se piden ni se guardan** | Sí | **No** | Factura por correo | Solo en el correo que el donante envía |

Decisiones del 7 de noviembre: se piden siempre nombre, apellidos y correo; "anónimo" se filtra en el servidor y el muro muestra
"Anónimo" con el monto; la factura no se pide en el formulario ni se almacenan datos fiscales.

## 5. Riesgos conocidos

| Riesgo | Estado | Mitigación o pendiente |
|---|---|---|
| **Spam en el formulario público** | Parcial | Campo trampa (`sitioWeb`), tope global de 30 donativos por hora (`maxRegistrosPorHora`) y validación de correo, monto y LinkedIn. Falta limitar por origen |
| **Agotar el tope por hora** | Abierto | Quien envíe 30 registros llena el cupo y bloquea las donaciones legítimas durante una hora. Se acepta para la Entrega 1; considerar un tope por correo |
| **Donar con el correo de otra persona** | Abierto | Se reutiliza el contacto existente sin modificar sus datos y la donación queda ligada a esa persona. Además, el consentimiento de avisos se guarda si estaba vacío, así que un tercero podría fijarlo. Mitigar solo guardando el consentimiento cuando el contacto sea nuevo |
| **Dar de baja el correo de otra persona** | Abierto | `darseDeBaja` no verifica que quien pide la baja sea el dueño del correo. Responde igual exista o no el correo, así que no revela quién está registrado, pero cualquiera puede darlo de baja. Tope de 60 bajas por hora |
| **Donar a una campaña ya cerrada** | Abierto | El sitio no ofrece donar a una campaña cerrada, pero el servidor valida solo que esté activa (`IsActive`), no su fecha de cierre. Agregar esa validación |
| **Monto público en donaciones anónimas** | Aceptado | Es decisión del equipo (el muro muestra "Anónimo" con el monto) |
| Clase `without sharing` | Aceptado | Documentado en la sección 2; cualquier método nuevo debe validar primero |
| Montos y paquetes duplicados entre Apex y componentes | Abierto | Centralizarlos en un solo lugar |
| Imágenes de campaña desde enlaces externos | Mitigado | Solo `https`; si la imagen no carga se oculta |
| Ids de campaña inventados en la dirección | Mitigado | `obtenerCampana` valida el formato y el tipo, y devuelve nulo si la campaña no está publicada |
| Correo de facturas de ejemplo (`facturas@ejemplo.org`) | Abierto | Sustituirlo por el real antes de entregar |
| Automatizaciones de otros proyectos en la sandbox UADY | Mitigado | Un trigger y una regla ajenos impedían donar. Se desactivaron `OpportunityTrigger`, un flujo, 4 reglas de validación de Campaign y `PreApproveStudent`, con respaldo y reversibles. Si alguien las usa, hay que acordarlo con el equipo |
| Datos de demostración visibles en el muro público | Cerrado | Un reconocimiento de $99,000 cargado a mano se mostraba. Se ocultó. Antes de la entrega, revisar el muro de cada campaña y quitar los datos de prueba |
| Datos personales en los registros de depuración | **Cerrado** | Los `System.debug` con datos de personas ya no existen en `entrega-1` |

## 6. Cómo comprobar que no hay claves en el código

Ver la sección 3 para el historial y, para el código vigente, `git grep -inE "sk_|pk_|whsec_|secret" -- force-app`
(sin resultados al 10 de noviembre).

## 7. Qué cambió respecto a la versión anterior de este documento

Se retiró el **token de acceso** y las llamadas que dependían de él (`obtenerInvitacion`, `registrarPromesa`, `actualizarDatos`):
la prueba ahora verifica que ya no existen. Se agregaron el formulario único, la baja de avisos y los enlaces de pago, con sus riesgos.

## 8. Entrega 2 (pendiente de actualizar)

Aviso de la pasarela: dónde se guarda el secreto de firma, cómo se rechazan avisos falsos o repetidos (incluidos los pagos
diferidos como OXXO o SPEI) y los permisos del usuario de integración que lo recibe.
