# Mesa de regalos · México Dreamin V2

Proyecto base para que las personas se registren en un solo formulario y hagan un donativo en dinero, identificándose solo con su correo (sin token), con control de qué se hace público.

**Estado:** los componentes validan con `--dry-run` sin errores. Las pruebas Apex (16) se validan en una Developer Edition limpia. El pago con Stripe Checkout y su webhook de confirmación están implementados (US-05); falta configurarlos y probarlos de punta a punta en la org (ver [docs/guia_pruebas_stripe.md](docs/guia_pruebas_stripe.md)). Falta también una pantalla para que los admins puedan gestionar las campañas (CRUD).

## Video demo (Entrega 1)

- **Video de 3 min 25 s** (subtítulos, sin voz): [demo-video/entrega-1-demo.mp4](demo-video/entrega-1-demo.mp4). Recorre como visitante sin login el sitio central, la campaña, el formulario, la maqueta del pago de prueba, el muro, la factura por correo, la seguridad y el backlog con su avance.
- En el video el pago con Stripe era todavía una maqueta; hoy se usa Stripe Checkout en modo de prueba (sin cobros). Todos los datos son ficticios.

## Backlog y avance (Entrega 1)

- **Backlog en el repo:** [docs/backlog.md](docs/backlog.md) (ID, RF que cubre, hito, historia, criterios, estado y evidencia).
- **Tablero (Jira):** [backlog del proyecto](https://fernandojoachinp.atlassian.net/issues?jql=project%20%3D%20SCRUM%20ORDER%20BY%20key%20ASC).
  Cada historia (`US-xx`) tiene su descripción, sus criterios de aceptación (CA) y su estado; las historias de la entrega llevan la etiqueta `entrega-1`.
- **Estados:** *Por hacer*, *En curso*, *En revisión* y *Finalizado*. Una historia está **cumplida** solo cuando está en *Finalizado*, es decir,
  cuando **todos** sus criterios de aceptación se demostraron con evidencia (demo, video o captura) en el escenario de prueba y sin romper ninguno.
  Una historia a medias cuenta como no cumplida.
- **Cómo se calcula el avance:** `historias en Finalizado ÷ historias del backlog que cubren requisitos de la Entrega 1 × 100`.
  Las historias descartadas (etiqueta `descartada`) no cuentan.
- **Avance al 11 de noviembre de 2026:** **27 %** (4 de 15 historias de la Entrega 1 en *Finalizado*: US-01, US-02, US-09 y US-20; el cálculo está en `docs/backlog.md`).
  Es provisional hasta reunir las capturas de evidencia. Este número se actualiza antes de la entrega con el conteo del día.
- **Documentos de la entrega** (en `docs/`): `seguridad.md` (prueba del visitante, permisos, datos personales y riesgos) y `bitacora_ia.md`
  (bitácora de uso de IA). Las pestañas de contribución y de preguntas y reportes se agregan en `docs/` con su ticket.

## Qué incluye

| Pieza | Para qué |
|---|---|
| Campos en **Contact** | `Consentimiento_Avisos__c` (Sí/No para recibir avisos de próximos eventos y donaciones), `Fecha_Consentimiento__c` y `Version_Aviso_Privacidad__c`. La baja usa además el campo estándar *Email Opt Out*. |
| **CampaignMember** | Sin campos propios. Su estado lleva el embudo de cada persona. |
| Campos en **Opportunity** (donativo) | `Visibilidad__c` (Pública o Anónima), `Nombre_Visible__c`, `Donacion_Empresa__c`, `LinkedIn_URL__c`, `Consentimiento_Publicacion__c`, `Stripe_Pago_Id__c` (único), `Version_Aviso_Privacidad__c` y `Contacto_Donador__c`. |
| Objeto **Reconocimiento público** | Es lo **único** que se muestra en el sitio: nombre (o «Anónimo»), monto, si es empresa y LinkedIn. Se crea solo cuando el donativo está pagado. `Mostrar_En_Muro__c` sirve de interruptor de moderación. |
| Objeto **Ofrecimiento en especie** | Seguimiento de apoyos no monetarios (boletos, hospedaje, etc.). Solo captura interna por ahora. |
| `MesaRegalosController` | Lo que usa el sitio: `guardarDonativo` (registro y donación), `darseDeBaja`, `obtenerMuro` y `obtenerAvance`. |
| `MesaRegalosService` | Avanza el embudo y confirma pagos (`confirmarPago`, también invocable desde un Flow). |
| `MesaRegalosDonativoTest` | 16 pruebas Apex del flujo. |
| LWC `mesaInicio`, `mesaRegistro`, `mesaBaja`, `mesaAviso`, `mesaMuro` | Páginas del sitio de Experience Cloud (inicio, registro y donación en un solo formulario, baja de avisos, aviso de privacidad, muro). |
| LWC `mesaUtil` y `mesaEstilos` | Funciones y estilos compartidos (no son visuales). |
| LWC `mesaTotalAnonimo` | Tarjeta «Aportaciones anónimas» que usan `mesaCampanaDetalle` y `mesaMuro` (no se arrastra en Builder). |
| Permission set `Mesa_Regalos_Admin` | Permisos para el equipo que administra. |

## Cómo funciona

1. Cualquier persona entra al sitio (por ejemplo, desde el enlace a `/registro` de un correo de campaña). **No hay token ni invitaciones**: se identifica con su correo.
2. El formulario único pide: monto (paquete de $1,000, $3,000 o $5,000, u otro monto desde $100), si la donación es **Pública** o **Anónima**, nombre y apellidos (o el nombre de la empresa), LinkedIn (opcional, solo en Pública), correo, si quiere recibir avisos (Sí/No), la autorización de publicación y la aceptación del aviso de privacidad. El botón dice «Donarás: $X MXN».
3. El servidor valida todo y:
   - busca el **Contact** por correo y lo reutiliza sin modificar sus datos; si no existe, lo crea. El consentimiento de avisos solo se guarda si estaba vacío, así que un «No» anterior nunca se cambia;
   - crea o reutiliza el **CampaignMember** en estado `Registrado`;
   - crea la **promesa** de donativo (Opportunity en *Prospecting*) y pasa el miembro a `Redirigido a donar`;
   - con el donativo ya guardado, `iniciarPago` crea una sesión de **Stripe Checkout** con el monto de la Opportunity (no el del navegador) y el sitio redirige ahí.
4. Stripe avisa el pago al **webhook** (`MesaStripeWebhook`); con la firma, la referencia y el monto verificados, `MesaRegalosService.confirmarPago` marca *Closed Won*, el estado `Donó` y crea el **Reconocimiento público**. Si la persona cancela o la tarjeta se rechaza, el donativo sigue pendiente (ver *Pagos con Stripe*).
5. El muro del sitio lee únicamente Reconocimientos públicos. Las donaciones **Públicas** aparecen con nombre y monto; las **Anónimas** no aparecen como renglón: debajo de la lista, la tarjeta «Aportaciones anónimas» (componente `mesaTotalAnonimo`) muestra solo la suma de las anónimas pagadas de la campaña y qué porcentaje representa del total recaudado, y solo aparece si la suma es mayor que cero. Las empresas se marcan como tales.
6. LinkedIn: al final de la campaña se hará una sola publicación de agradecimiento con las personas que dejaron su enlace.
7. Quien quiera dejar de recibir avisos usa `/baja`, que escribe su correo. La respuesta es la misma exista o no el correo, para no revelar quién está registrado.

Reglas de identidad del formulario:
* **Anónima:** el servidor ignora nombre, empresa y LinkedIn; el Contacto se crea como «Anónimo».
* **Empresa:** el nombre de la empresa se guarda en nombre y apellidos del Contacto. No se crean ni se buscan Accounts; el checkbox se guarda en `Donacion_Empresa__c` y `Es_Empresa__c`.

Etapas del donativo:
* **Prospecting** = promesa registrada
* **Closed Won** = pago confirmado.

Embudo de la persona (`CampaignMember`): `Identificado` y `Contactado` (a mano, en campañas de correo) → `Registrado` → `Redirigido a donar` → `Donó`. Solo avanza, nunca retrocede.

## Pagos con Stripe

Se usa **Stripe Checkout** creado desde Apex (US-05). Guía paso a paso para configurarlo y probarlo: [docs/guia_pruebas_stripe.md](docs/guia_pruebas_stripe.md).

1. `guardarDonativo` registra la Opportunity en *Prospecting* (igual que antes).
2. `MesaRegalosController.iniciarPago` (llamada aparte, porque Apex no permite un callout después de un DML) lee el `Amount` guardado y `MesaPagosStripe.crearSesion` crea la sesión con ese monto en centavos MXN, `client_reference_id` y `metadata.donativo_id` = Id de la Opportunity, y la descripción `Donativo REF XXXXXXXX`. El encabezado `Idempotency-Key` hace que reintentar devuelva la misma sesión.
3. Stripe envía `checkout.session.completed` a `https://[SITIO]/services/apexrest/stripe/webhook`. `MesaStripeWebhook` valida la firma (HMAC-SHA256, tolerancia de 5 min) y `MesaPagosStripe.procesarEvento` comprueba referencia, monto, moneda y que el pago no confirme otro donativo; luego guarda `Stripe_Pago_Id__c` y llama a `confirmarPago`. Un aviso repetido no hace nada.
4. Al volver: el muro consulta `estadoPago` y dice «Tu pago se confirmó» o «Confirmando tu pago»; si se cancela, la página de registro muestra «Pago no completado» con *Intentar de nuevo* (mismo donativo).

**Dónde están los secretos:** la clave secreta en la External Credential `Stripe` (principal `Clave`, parámetro `SecretKey`); el secreto `whsec_` y la dirección del sitio en la configuración protegida **Configuración de Stripe** (`Stripe_Config__c`). Nada de eso está en el repositorio. El usuario guest necesita el permission set `Mesa_Sitio_Pagos`.

**Conciliación manual** (si el webhook fallara). Con el pago confirmado en Stripe, buscar la Opportunity por el `donativo_id` de la metadata del pago, verificar el monto y ejecutar en Apex anónimo:

```apex
Opportunity o = [SELECT Id FROM Opportunity WHERE Id = '006XXXXXXXXXXXXXXX'];
o.Stripe_Pago_Id__c = 'pi_XXXXXXXX';
update o;
MesaRegalosService.confirmarPago(new List<Id>{ o.Id });
```

`Stripe_Pago_Id__c` es único, así que un mismo pago no se registra dos veces, y `confirmarPago` es idempotente.

## Qué probar?

1. **Monto:** elige «Otro monto» y escribe `1,500`; debe aceptarlo. Prueba `99` (debe rechazar) y cada paquete (por ejemplo, P3000 deja el donativo en $3,000).
2. **Pública con persona:** nombre, apellidos y correo nuevo. Se crea el Contacto, el miembro en `Registrado` y la Opportunity en *Prospecting* con `Nombre_Visible__c`.
3. **Pública como empresa:** marca «Dono en nombre de una empresa». Los campos nombre y apellidos del Contacto llevan el nombre de la empresa y no se crea ninguna Account.
4. **Anónima:** el Contacto se crea como «Anónimo», sin LinkedIn, no aparece como renglón en el muro y su monto se suma a «Donaciones anónimas».
5. **Correo repetido:** vuelve a donar con el mismo correo. Se reutiliza el Contacto sin cambiar sus datos y un «No» previo de avisos no se modifica.
6. **Pago:** sigue [docs/guia_pruebas_stripe.md](docs/guia_pruebas_stripe.md): pago exitoso (`4242…`), rechazado (`4000 0000 0000 0002`) y cancelado; comprueba el estado, el monto y la referencia en Salesforce y en Stripe.
7. **Baja:** en `/baja` escribe un correo registrado y uno inexistente; el mensaje debe ser el mismo. El primero queda con *Email Opt Out* y `Consentimiento_Avisos__c = No`.
8. **Pruebas Apex:** `sf apex run test --test-level RunLocalTests --wait 10 --target-org donation-UADY-lab`.

## Despliegue (Developer Edition)

Se estará desplegando con el CLI, Salesforce CLI

```bash
# LOGIN
sf org login web --alias donation-UADY-lab
sf org login web --alias donation-UADY-lab --instance-url [URL de la sandbox]

# DEPLOY:
sf project deploy start --dry-run --source-dir force-app --target-org donation-UADY-lab # Try, without tests
sf project deploy start --dry-run --source-dir force-app --test-level RunSpecifiedTests --tests MesaRegalosDonativoTest --target-org donation-UADY-lab # Try, with especific tests
sf project deploy start --dry-run --source-dir force-app --test-level RunLocalTests --target-org donation-UADY-lab # Try, with tests, local
sf project deploy start --source-dir force-app --test-level RunLocalTests --target-org donation-UADY-lab # Deploy with tests
sf project deploy start --source-dir force-app --test-level NoTestRun --target-org donation-UADY-lab # Deploy without tests

# Assignation of PermissionSet
sf org assign permset --name Mesa_Regalos_Admin --target-org donation-UADY-lab

# Optional, just 1st time
sf apex run --file scripts/apex/crear-campana.apex --target-org donation-UADY-lab
sf apex run test --test-level RunLocalTests --wait 10 --target-org donation-UADY-lab
```

Para re-desplegar y que no haya fallos:
``` bash
sf project deploy start --dry-run --source-dir force-app --target-org donation-UADY-lab --test-level RunLocalTests --wait 15
sf project deploy start --source-dir force-app --target-org donation-UADY-lab
sf apex run test --test-level RunLocalTests --wait 10 --target-org donation-UADY-lab
```

Para asignar permisos
``` bash
sf org assign permset --name Moderador_Muro --on-behalf-of correo@usuario.com
sf org assign permset --name Gestor_Campanas --on-behalf-of correo@usuario.com
sf org assign permset --name Tesoreria --on-behalf-of correo@usuario.com
```

Scripts de apoyo (`scripts/apex/`, no se despliegan):
* `crear-campana.apex`: crea la campaña con los estados del embudo (incluye `Registrado`). **El usuario que lo ejecute necesita la casilla *Marketing User***. Imprime el Id de la campaña que se pega en el sitio.
* `simulador-donativo.apex`: simula un donativo completo (registro y pago) para pruebas.
* `limpiar-pruebas.apex`: borra los donativos y reconocimientos de un contacto de prueba para repetir la simulación.

## Sitio de Experience Cloud

1. *Setup → Digital Experiences → Settings*: activar Digital Experiences.
2. *All Sites → New*: crear un sitio. URL sugerida: `mexico-dreamin`. URL usada para despliegue prueba: `mexicodreamintest`.
3. En *Builder*, crear páginas y arrastrar con su respectivo componente:
   - Inicio → **Mesa - Inicio** (páginas de destino: `registro` y `muro`)
   - `/registro` → **Mesa - Registro y donación** (pegar el Id de la campaña, la URL del aviso, la versión del aviso `v2` y las 4 URLs de pago)
   - `/baja` → **Mesa - Baja de avisos**
   - `/aviso` → **Mesa - Aviso de privacidad** (responsable, domicilio, correo de contacto, plazo de conservación, versión `v2`, fecha y página de baja)
   - `/muro` → **Mesa - Muro y avance** (pegar el Id de la campaña)  
   {El Id de la campaña se tendrá que generar cada año, se creó un script `crear-campana.apex` }
4. *Workspaces → Administration → Pages → Go to Force.com* (o *Settings → Public Access Settings*) → perfil del guest → **Enabled Apex Class Access** → agregar `MesaRegalosController`. (Para que no se tengan que loguear)
5. **No** des al perfil guest permisos sobre Contact, CampaignMember ni Opportunity. Todo pasa por la clase Apex.
6. Activar una **regla de duplicados** de Contact por correo (el código reutiliza el Contacto existente, pero la org debe evitar duplicados por otras vías).
7. Publicar el sitio.

## Antes de usarlo con personas reales

- **Aviso de privacidad:** el texto v2 está en `mesaAviso`; debe revisarlo quien responda por los datos personales antes de publicarlo. El sitio guarda la versión aceptada en cada donativo.
- **Meta:** captura el monto en el campo *Ingreso esperado* de la campaña; de ahí sale el porcentaje de avance. Si no se quiere mostrar públicamente, desmarca «Mostrar avance» en el componente.
- **Correos de campaña (Flows, hoy en pausa):** el enlace al formulario es `https://[SITIO]/registro` y debe incluir un enlace de baja a `https://[SITIO]/baja`. Ya no hay enlaces personales ni token.
- **LinkedIn:** se hará una sola publicación al final de la campaña con quienes dejaron su enlace (`LinkedIn_URL__c` en el Reconocimiento). Publicar automáticamente requiere una app aprobada por LinkedIn; por ahora lo hace una persona.
- **Nombre público:** el nombre lo escribe la propia persona. `Mostrar_En_Muro__c` permite ocultar un reconocimiento inapropiado.
- **Correo ajeno:** como no se verifica el correo, alguien podría registrarse con el correo de otra persona. La verificación por correo (doble autenticación) queda para después.
- **Pagos:** pasar a las claves *live* de Stripe (nueva clave, nuevo destino de webhook y su `whsec_`) y activar los recibos por correo en Stripe.

## Pendiente (por decidir)

* Pagos diferidos (OXXO, SPEI): los métodos de pago se eligen en el Dashboard de Stripe (Settings → Payment methods); por ahora deja activas solo las tarjetas, porque el webhook aún no procesa `checkout.session.async_payment_succeeded`.
* Verificación del correo (doble autenticación).
* Captura de ofrecimientos en especie desde el sitio (hoy es interna).
* Moderación del nombre público.
* Centralizar los montos de los paquetes (hoy están en `MesaRegalosController`, `mesaRegistro` y `mesaInicio`).
* Retomar los Flows de correo con el nuevo flujo (sin token ni Reencuentro).  
  
---
---

# V2. DESPUÉS DE LLAMADA
(Cambios hechos para obtener el V2-baseline)  
(Arriba información completa actualizada)

# Donaciones para Campañas — México Dreaming

Campaña de donativos tipo "mesa de regalos" (Ohana) para la comunidad de Salesforce.
Cualquier persona se registra y dona desde un solo formulario, sin cuenta ni enlace personal.
Construida con Experience Cloud (LWR), Lightning Web Components y Apex.

## Flujo
1. La persona entra al sitio y elige un monto (paquetes de $1,000, $3,000 y $5,000, o monto
   abierto desde $100 MXN) (cantidades de ejemplo).
2. Elige cómo aparecerá en el muro: **Pública** (nombre y, si quiere, enlace de LinkedIn) o
   **Anónima** (no aparece en la lista; su monto se suma al total de donaciones anónimas).
3. Escribe nombre y apellido, o marca "Donar en nombre de una empresa" y escribe solo el
   nombre de la empresa. Escribe su correo y responde si quiere recibir avisos de futuros
   eventos y donaciones. Acepta el aviso de privacidad.
4. El botón dice "Donarás: $X MXN". Al enviarlo se registra la promesa y se redirige al
   Payment Link de Stripe con el correo pre-rellenado.
5. Al confirmarse el pago, la donación pasa a Closed Won y aparece en el muro.
   Hoy se confirma a mano con `confirmarPago`; el webhook de Stripe automatiza este paso.

## Pantallas (LWC)
`mesaInicio`, `mesaRegistro` (registro + donación), `mesaBaja`, `mesaMuro`, `mesaAviso`.
Compartidos: `mesaUtil` (JS) y `mesaEstilos` (CSS).

## Modelo de datos
| Objeto | Campos propios |
|---|---|
| Contact | `Consentimiento_Avisos__c` (Sí/No; vacío = sin respuesta), `Fecha_Consentimiento__c`, `Version_Aviso_Privacidad__c` |
| Opportunity | `Visibilidad__c` (Pública/Anónima), `Nombre_Visible__c`, `Donacion_Empresa__c`, `Consentimiento_Publicacion__c`, `LinkedIn_URL__c`, `Contacto_Donador__c`, `Stripe_Pago_Id__c` (único), `Version_Aviso_Privacidad__c` |
| Reconocimiento_Publico__c | `Campana__c`, `Donativo__c`, `Monto__c`, `Es_Empresa__c`, `LinkedIn_URL__c`, `Mostrar_En_Muro__c` (moderación) |
| Ofrecimiento_Especie__c | Ofrecimientos en especie, de uso interno |

Sin Accounts: todas las personas y empresas son Contactos. El correo identifica al Contacto
y no hay contactos duplicados por correo (regla de duplicados). Un Contacto existente se reutiliza
sin modificarlo, salvo el consentimiento de avisos, y solo si estaba vacío.

## Embudo (CampaignMember)
Registrado → Redirigido a donar → Donó. "Identificado" y "Contactado" se usan solo cuando el
equipo carga personas antes de una campaña por correo.

## Backend (Apex)
- `MesaRegalosController`: `guardarDonativo`, `darseDeBaja`, `obtenerMuro`, `obtenerAvance`.
- `MesaRegalosService`: `confirmarPago` (invocable e idempotente), `avanzarEstado`, `estadoSiExiste`.

## Privacidad y seguridad
- El usuario guest solo accede a `MesaRegalosController`, que corre `without sharing`.
- Nada del sistema se devuelve al navegador al escribir un correo.
- Anónima fuerza nombre "Anónimo" y descarta empresa y LinkedIn en el servidor.
- El precio de los paquetes lo fija el servidor.
- Campo trampa y tope de registros y bajas por hora.
- Un "No" de consentimiento no se cambia con un registro nuevo; la baja es explícita en `/baja`.
- LinkedIn es opcional, solo en Pública, y si viene se valida.

## Pruebas
`MesaRegalosTest` y `MesaRegalosDonativoTest`: validaciones, montos, correo existente,
empresa, anónimo, baja, confirmación de pago e idempotencia, y datos del muro.

## Pendientes y mejoras marcadas
- Correos automáticos con Flow (campaña, agradecimiento).
- Webhook de Stripe con validación de firma, incluyendo pagos diferidos (OXXO, SPEI).
- Verificación del correo con doble autenticación.
- El nombre público lo escribe quien dona: definir moderación.
- Cuidado del consentimiento ante registros con correo ajeno.

Espero seguir un flujo como el siguiente:
- [✅] 1 Backend nuevo
- [✅] 2 Interfaz
- [✅] 3 Pago
- [✅] 4 Aviso de privacidad
- [✅] 5 Limpieza

1. Asignar el permission set Mesa_Regalos_Admin a tu usuario.
2. Crear la campaña y agregar el estado Registrado en Campaign Member Statuses. Los demás estados del embudo son Redirigido a donar y Donó, más Identificado y Contactado si los usas a mano.
3. Crear el sitio de Experience Cloud con las páginas registro, muro, aviso y baja, y configurar las propiedades de los componentes (campaignId, avisoUrl). Stripe se configura como dice docs/guia_pruebas_stripe.md.
4. En el perfil del usuario invitado (guest) del sitio, dar acceso a la clase Apex MesaRegalosController.
5. Regla de duplicados de Contact por correo.
6. Los Flows de correo...
