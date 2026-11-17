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

#### Datos de demostración del muro y repetición de la prueba (11 de noviembre de 2026)

- **Qué hay en la sandbox UADY:** 12 donativos de demostración (10 con nombre ficticio y 2 anónimos, $37,300 en total) más una donación
  pendiente de $99,000 ("Donación pendiente (no debe verse)"). Los cargó el script `scripts/apex/datos-prueba-muro.apex`: son nombres
  inventados (Alicia Torres, Bruno Vega…), correos `@example.com` y el nombre `DEMO MURO | …`. Aclaración sobre el hallazgo 2: el
  reconocimiento de $99,000 venía de ese script, no de una carga a mano sin origen.
- **Por qué se dejan:** para que el muro y el avance se vean con contenido en la demostración. No son personas reales.
- **Cómo se quitan:** `scripts/apex/limpiar-datos-prueba-muro.apex`. Antes de usar el sitio con donantes reales hay que ejecutarlo.
- **Prueba repetida como visitante, con el controlador nuevo del muro (SCRUM-49):** el muro carga sin login, el total sigue en $37,300 y la
  donación pendiente de $99,000 **no aparece**, porque el muro solo muestra donaciones en `Closed Won`. Un donativo nuevo de $1,000 enviado
  por el formulario quedó `Prospecting` y tampoco apareció en el muro ni en el total.
- **No repetido todavía:** la prueba por REST y SOQL como visitante en la sandbox UADY.

## 2. Permisos del usuario visitante (guest) y por qué

| Elemento | Permiso | Por qué |
|---|---|---|
| Clase `MesaRegalosController` | Acceso habilitado | Es el único canal del sitio. Los métodos que el visitante puede llamar son `obtenerMuro`, `obtenerAvance`, `obtenerCampanas`, `obtenerCampana`, `guardarDonativo`, `darseDeBaja`, `estadoPago`, `iniciarPago` y `enviarAyuda` |
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

**Formulario de ayuda (SCRUM-141, 16 de noviembre de 2026).** El visitante tampoco recibe permisos nuevos: `enviarAyuda` es otro
método de `MesaRegalosController` (clase a la que ya tiene acceso, en modo sistema), así que no hace falta darle permisos sobre
`Case`. Valida nombre, correo, referencia (solo letras y números) y mensaje (10 a 2000 caracteres), tiene campo trampa
(`sitioWeb`) y un tope de 20 solicitudes por hora, y solo devuelve el número del Case. El Case no lleva origen «Web» porque la
sandbox trae un proceso antiguo ajeno que se dispara con ese origen y falla; se reconoce por el asunto «Ayuda desde el sitio».

**Comprobante por correo (SCRUM-137, 16 de noviembre de 2026).** El usuario guest **no** tiene el permiso «Send Email» y no se
le dio. `confirmarPago` (que corre como guest) solo publica un evento de plataforma `Comprobante_Pago__e` con el Id del
donativo, sin datos personales; el trigger `ComprobantePagoTrigger` lo atiende como usuario interno (Automated Process) y manda
el correo. Se comprobó con un pago real de prueba que el guest puede publicar el evento sin permiso adicional sobre el objeto.
El resultado queda en `Opportunity.Comprobante_Estado__c` («Enviado» o el código de error, sin correos ni nombres) y evita un
segundo envío si Stripe repite el aviso.

**Historia de cada campaña (US-22, 15 de noviembre de 2026).** El visitante no recibe permisos nuevos: la historia, los
niveles de impacto y el número de donantes salen por los mismos métodos de `MesaRegalosController` (`obtenerCampanas` y
`obtenerCampana`), que solo devuelven el DTO público. El texto se muestra como texto (las plantillas de LWC no interpretan
HTML). Editar la historia y los niveles es del permission set `Gestor_Campanas` (y de `Mesa_Regalos_Admin`).

## 3. Claves y datos de la pasarela

- **No hay claves en el proyecto.** Se revisó el historial de commits completo buscando `sk_live`, `sk_test`, `pk_live`,
  `pk_test`, `whsec_`, `client_secret` y `api_key`. Las únicas coincidencias son líneas de documentación que describen esta misma
  búsqueda; no hay claves.
- **Stripe Checkout (US-05):** la sesión de pago la crea Apex (`MesaPagosStripe`) con el monto **guardado** en la Opportunity; el
  navegador solo envía el Id del donativo y nombres de página que el servidor valida. La dirección base de regreso sale de la
  configuración, no del navegador.
- **Clave secreta:** en la External Credential `Stripe` (cifrada, Apex no puede leerla, no aparece en registros). El usuario guest la usa
  solo a través del permission set `Mesa_Sitio_Pagos`.
- **Secreto de firma del webhook y dirección del sitio:** en la configuración protegida `Stripe_Config__c`; sus valores no son
  metadata y no llegan al repositorio.
- **Webhook (`MesaStripeWebhook`):** público para el guest, pero no lee nada sin una firma válida (HMAC-SHA256 sobre el cuerpo sin
  procesar, tolerancia de 5 minutos). Solo `checkout.session.completed` pagado cambia algo, y solo si la referencia, el monto y la
  moneda coinciden con lo guardado y el pago no confirmó otro donativo. Un aviso repetido no hace nada. La página de regreso nunca
  marca un pago.
- **Qué viaja a Stripe:** el Id del donativo (`client_reference_id` y metadata), el monto, el nombre de la campaña y el correo del
  donante (para el recibo). No se envían datos fiscales ni de LinkedIn. Los datos de tarjeta solo los ve Stripe.
- **`estadoPago`:** devuelve solo `pagado` o `pendiente` para un Id de donativo; ningún otro dato.
- **«Protected» no es un secreto (matiz):** `Stripe_Config__c` está como configuración personalizada *Protected*, pero esa visibilidad
  solo oculta el objeto a quien instala un paquete administrado. En esta org, un administrador o cualquier Apex de la org puede leer
  `Webhook_Secret__c`. Por eso el control real es: el valor no está en el repositorio, ningún componente ni método devuelve esos
  campos al navegador (se comprobó con una búsqueda en `force-app/main/default/lwc`: sin resultados) y solo lo lee
  `MesaPagosStripe`. Quien tenga acceso de administración a la org puede verlo; si se sospecha una fuga, se rota el secreto en
  Stripe y aquí.


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
| Identificador del pago | `Opportunity.Stripe_Pago_Id__c` | Sensible (vincula con la pasarela) | Sí, lo guarda el webhook | Conciliar el pago | Personal interno |
| Datos fiscales (RFC, constancia) | **No se piden ni se guardan** | Sí | **No** | Factura por correo | Solo en el correo que el donante envía |
| Nombre, correo, referencia y mensaje del formulario de ayuda (SCRUM-141) | `Case` (`SuppliedName`, `SuppliedEmail`, `Description`); se liga al `Contact` si el correo ya existe | Sí | Sí | Responder a quien pide ayuda | Personal con acceso a Case (administradores); no se publica |
| Comprobante por correo (SCRUM-136/137) | Se arma en el momento y se envía a `Contact.Email`; no se guarda como actividad (`setSaveAsActivity(false)`) | Sí (nombre, monto, campaña, id del pago) | No se guarda copia en Salesforce | Confirmar el pago | Solo quien recibe el correo; sale desde una dirección verificada de la organización |
| Estado del comprobante | `Opportunity.Comprobante_Estado__c` | No (solo «Enviado» o un código de error) | Sí | Saber si llegó y por qué falló | Personal interno (Tesorería y Administración, solo lectura) |
| Aviso interno «donativo pagado» | Evento `Comprobante_Pago__e` (solo el Id del donativo) | No | No (es transitorio) | Disparar el envío del correo | Sistema |
| Historia, resumen, a quién ayuda y quién organiza (US-22) | Campaign: `Resumen__c`, `Historia__c`, `Para_Quien__c`, `Organiza__c` | No | Sí | Contar la causa en el sitio | Público (visitante sin login) |
| Niveles de impacto (US-22) | `Nivel_Impacto__c` (monto y qué logra) | No | Sí | Montos sugeridos de cada campaña | Público |
| Número de personas que donaron (US-22) | Se calcula al vuelo con las donaciones pagadas | No (es un conteo, sin nombres) | No | Mostrar participación | Público |

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
| Correo de facturas de ejemplo (`facturas@ejemplo.org`) | Mitigado en la sandbox | El 17-nov se cambió en la sandbox UADY a la cuenta del equipo que ya envía los comprobantes: etiqueta `Mesa_Correo_Facturas` y propiedad `correoFacturas` de la página de facturas (Experience Builder). No está en el repo a propósito: el valor por defecto del repo sigue siendo de ejemplo, y en otra org hay que cambiar esos dos sitios |
| Automatizaciones de otros proyectos en la sandbox UADY | Mitigado | Un trigger y una regla ajenos impedían donar. Se desactivaron `OpportunityTrigger`, un flujo, 4 reglas de validación de Campaign y `PreApproveStudent`, con respaldo y reversibles. Si alguien las usa, hay que acordarlo con el equipo |
| Datos de demostración visibles en el muro público | Aceptado | Los donativos de demostración se dejan a propósito (nombres ficticios, `DEMO MURO | …`) para la demostración. La donación pendiente de $99,000 no se muestra porque el muro solo lista `Closed Won`. Se quitan con `limpiar-datos-prueba-muro.apex` antes de usar el sitio con donantes reales |
| **Spam en el formulario de ayuda** | Parcial | Campo trampa, validación de correo, referencia y largo, y tope global de 20 Cases por hora (`maxAyudasPorHora`). Igual que en el donativo, quien lo llene puede agotar el cupo; falta limitar por origen |
| **Proceso ajeno que se dispara con Cases de origen «Web»** | Mitigado | `NuevoCasoDesdeFormularioCommunity` (2020, de otra persona) falla al crear esos Cases. No se modificó; el Case de ayuda no usa ese origen |
| **Remitente del comprobante** | Aceptado (demo) | Sale como «Mesa de regalos · México Dreamin» desde una dirección de toda la organización verificada. Para uso real hay que usar una dirección del dominio de la organización y configurar DKIM |
| **Correo del comprobante a un contacto reutilizado** | Abierto | El saludo usa el nombre público del donativo, no el del contacto (un contacto creado en un donativo anónimo se llama «Anónimo»). El sitio no actualiza el nombre de un contacto reutilizado |
| **Consentimiento de publicación implícito** | Aceptado | Desde SCRUM-144 no hay casilla aparte: elegir «Con mi nombre» o «Anónima» autoriza lo que esa opción dice (visible en pantalla). El formulario sigue enviando y guardando `Consentimiento_Publicacion__c` y la versión del aviso. La casilla de novedades sin marcar guarda el consentimiento de avisos como «No» |
| **Código desplegado en UADY distinto del repo** | Abierto | El 17-nov se desplegó a la sandbox, desde una copia local, un filtro que publica solo las campañas del tipo de registro `Donacion` (más una clase de pruebas `MesaTestDatos`). No está en ningún PR y dejó el sitio sin campañas hasta que se asignó ese tipo a las campañas. Hay que abrirlo como PR con su ticket; mientras tanto una redistribución desde el repo quitaría el filtro. Las campañas nuevas deben nacer con ese tipo |
| Datos personales en los registros de depuración | **Cerrado** | Los `System.debug` con datos de personas ya no existen en `entrega-1` |

## 6. Cómo comprobar que no hay claves en el código

Ver la sección 3 para el historial y, para el código vigente, `git grep -inE "sk_|pk_|whsec_|secret" -- force-app`
(sin resultados al 10 de noviembre).

## 7. Qué cambió respecto a la versión anterior de este documento

Se retiró el **token de acceso** y las llamadas que dependían de él (`obtenerInvitacion`, `registrarPromesa`, `actualizarDatos`):
la prueba ahora verifica que ya no existen. Se agregaron el formulario único, la baja de avisos y los enlaces de pago, con sus riesgos.

## 8. Entrega 2

Los diagramas de las piezas y del flujo de pago, con quién corre cada cosa, están en [arquitectura.md](arquitectura.md).

- **Aviso de la pasarela (webhook):** el secreto de firma vive en `Stripe_Config__c` (ver el matiz sobre «Protected» en la sección 3);
  se rechazan avisos con firma inválida, fuera de la tolerancia de 5 minutos, con monto o moneda distintos, o que confirmen otro
  donativo, y un aviso repetido no cambia nada (pruebas en `MesaPagosStripeTest`). Los pagos diferidos (OXXO, SPEI) no se confirman con
  el primer aviso: solo cuenta `checkout.session.completed` ya pagado. El usuario que lo recibe es el guest, con el permission set
  `Mesa_Sitio_Pagos` (solo la clase del webhook, la credencial de Stripe y lectura de `UserExternalCredential`).
- **Comprobante por correo:** evento de plataforma atendido por un usuario interno, sin dar «Send Email» al guest (sección 2). Datos
  del correo en la sección 4.
- **Formulario de ayuda:** crea un Case sin permisos nuevos para el guest (sección 2).
- **Pendiente:** el aviso rechazado solo queda en el registro de depuración, no visible para staff (US-08 y US-17 CA1); repetir la
  prueba del visitante por REST y SOQL en UADY después de estos cambios; sustituir `facturas@ejemplo.org`; incluir el perfil guest
  y el sitio en el respaldo de metadata.
