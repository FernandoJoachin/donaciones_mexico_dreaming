# Guía de pruebas: pago con Stripe (US-05)

Esta guía sirve para probar, en **modo de prueba**, la integración que ya está en el código: el sitio registra el donativo pendiente, Salesforce abre una sesión de **Stripe Checkout** con el monto guardado y el **webhook** confirma el pago. No uses tarjetas reales: en modo de prueba no se cobra nada.

**Qué ya resuelve el código:** crear la sesión de pago, fijar el monto desde la Opportunity, la referencia, la validación de la firma del webhook, la confirmación idempotente, el aviso en el sitio y el reintento tras cancelar.
**Qué haces tú a mano (una vez por org):** pasos 1 a 6.

Nombres usados abajo (cámbialos por los tuyos):

| Dato | Ejemplo |
|---|---|
| Alias de la org | `donation-UADY-lab` |
| Dirección del sitio | `https://midominio.my.site.com/donaciones` (este proyecto usa LWR: sin `/s`; en un sitio Aura sería `.../donaciones/s`) |
| Webhook | `https://midominio.my.site.com/donaciones/services/apexrest/stripe/webhook` |

---

## 1. Cuenta de Stripe y modo de prueba

1. Entra a <https://dashboard.stripe.com/register> (o inicia sesión si el equipo ya tiene cuenta).
2. Una cuenta nueva empieza en un **sandbox** (entorno de prueba). Arriba a la izquierda, en el selector de cuenta, verás el nombre del sandbox; mientras estés ahí, la interfaz muestra que estás en pruebas y nada mueve dinero real.
3. No hace falta activar la cuenta (datos bancarios) para probar.

Documentación: [Sandboxes](https://docs.stripe.com/sandboxes) · [Pruebas](https://docs.stripe.com/testing).

## 2. Claves de prueba

1. En el Dashboard, dentro del sandbox: **Developers → API keys** (o en la página de inicio, sección *API keys*).
2. Copia la **Secret key**, que empieza con `sk_test_`. La *Publishable key* (`pk_test_`) **no se usa** en esta integración.
3. Trátala como contraseña: no la pegues en el código, en el repositorio, en Slack ni en capturas.

Documentación: [API keys](https://docs.stripe.com/keys).

## 3. Configurar Salesforce (equivale a las "variables de entorno")

Este proyecto no usa archivos `.env`: los secretos viven en la org.

1. **Despliega** el código:
   ```bash
   sf project deploy start --source-dir force-app --target-org donation-UADY-lab
   ```
2. **Clave secreta → External Credential.** Setup → busca *Named Credentials* → pestaña **External Credentials** → **Stripe** → sección *Principals* → en **Clave**, menú ▼ → **Edit** → *Add* un parámetro de autenticación:
   - Name: `SecretKey` (exactamente así)
   - Value: tu `sk_test_...`
   - Save. Salesforce la guarda cifrada; nadie (ni Apex) puede volver a leerla.
3. **Dirección del sitio → Custom Setting.** Setup → *Custom Settings* → **Configuración de Stripe** → **Manage** → **New** (en *Default Organization Level Value*):
   - *Dirección del sitio*: `https://midominio.my.site.com/donaciones` (con https, sin diagonal final; la misma base que ves en el navegador antes de `/registro`).
   - *Secreto de firma del webhook*: déjalo vacío por ahora (paso 5).
4. **Permisos del usuario guest del sitio.** Setup → *Digital Experiences* → *All Sites* → **Builder** de tu sitio → ⚙ **Settings** → **General** → clic en el perfil del *Guest User* → abre el usuario guest → **Permission Set Assignments** → **Edit Assignments** → agrega **Mesa - Pagos del sitio (guest)** (`Mesa_Sitio_Pagos`). Da acceso a la clase del webhook y a la credencial de Stripe; no da acceso a objetos.
5. En Builder, **publica** el sitio (botón *Publish*). Las propiedades *(Ya no se usa) Payment Link* del componente *Mesa - Registro y donación* ya no se leen; no hay que configurar enlaces.

## 4. Registrar el webhook en Stripe

El webhook vive en la nube de Salesforce (es una dirección pública del sitio), así que **no necesitas `stripe listen` ni túneles**: Stripe le habla directamente.

1. Dashboard → **Developers → Webhooks** → **Add destination** (o *Add endpoint*, según la versión del Dashboard).
2. Eventos: selecciona **solo** `checkout.session.completed`.
3. Tipo de destino: *Webhook endpoint*. URL: `https://midominio.my.site.com/donaciones/services/apexrest/stripe/webhook`
   - Sitio Aura: quita el `/s`. Ejemplo: si el sitio es `.../donaciones/s/registro`, el webhook es `.../donaciones/services/apexrest/stripe/webhook`.
4. Guarda.

Documentación: [Webhooks](https://docs.stripe.com/webhooks).

## 5. Secreto de firma del webhook

1. En el destino que creaste, busca **Signing secret** → *Reveal*. Empieza con `whsec_`.
2. Pégalo en Salesforce: Setup → Custom Settings → Configuración de Stripe → Manage → **Edit** → *Secreto de firma del webhook*.
3. Es distinto en sandbox y en producción; al salir a producción hay que repetir los pasos 2 a 5 con las claves *live*.

**Comprobación rápida** (opcional, desde una terminal):
```bash
curl -i -X POST "https://midominio.my.site.com/donaciones/services/apexrest/stripe/webhook" -d "{}"
```
- `400` = correcto: el endpoint existe, tiene secreto y rechazó la petición sin firma.
- `500` = falta el secreto del paso 5.
- `404` / `401` / `403` = URL equivocada o falta el permission set del paso 3.4.

## 6. Iniciar el sitio

No hay servidor local: backend y frontend corren en Salesforce. Abre el sitio publicado en una **ventana de incógnito** (para probar como visitante) y entra a la página de registro de una campaña activa.

Para ver lo que hace el webhook, activa registros de depuración del usuario guest: Setup → *Debug Logs* → **New** → *Traced Entity Type*: User → busca el usuario guest del sitio → fecha de vencimiento de hoy.

## 7. Pago exitoso

1. Llena el formulario (por ejemplo, *Paquete $3,000*, Pública) y envía.
2. Te lleva a Stripe Checkout; verás el monto y la descripción "Donativo a <campaña>".
3. Tarjeta **`4242 4242 4242 4242`**, cualquier fecha futura (ej. `12/34`), cualquier CVC (ej. `123`), cualquier nombre.
4. Paga. Stripe regresa al **muro** con "¡Gracias por tu donación!":
   - "Tu pago se confirmó…" cuando el webhook ya llegó (lo normal);
   - "Confirmando tu pago…" si tardó; la página reintenta unos segundos.

## 8. Pago rechazado

1. Registra otro donativo y, en Checkout, usa **`4000 0000 0000 0002`** (rechazo genérico) o **`4000 0000 0000 9995`** (fondos insuficientes).
2. Checkout muestra el error al instante y te deja probar otra tarjeta. **En Salesforce no cambia nada**: el donativo sigue *Prospecting*.
3. Si después pagas con `4242…` en la misma pantalla, se confirma ese mismo donativo.

Tarjetas oficiales: [docs.stripe.com/testing#cards](https://docs.stripe.com/testing#cards) y rechazos: [#declined-payments](https://docs.stripe.com/testing#declined-payments).

## 9. Cancelación

1. Registra un donativo y, en Checkout, usa la flecha **←** (arriba a la izquierda, junto al nombre del negocio) para volver.
2. Llegas a la página de registro con "Pago no completado", la **referencia** del donativo y **Intentar de nuevo**.
3. *Intentar de nuevo* abre **la misma** sesión de pago (no crea otro donativo ni otro cobro).
4. El donativo sigue *Prospecting* y no suma al avance de la campaña.

## 10. Revisar el pago en el Dashboard

Dashboard → **Transactions / Payments** → abre el pago:
- **Monto**: MXN $3,000.00 (o el que elegiste).
- **Description**: `Donativo REF XXXXXXXX` (los últimos 8 caracteres del Id de la Opportunity; la misma referencia que ve el donante).
- **Metadata**: `donativo_id = 006...` (Id completo de la Opportunity).
- En la sesión de Checkout (Developers → *Events* → el evento `checkout.session.completed`): `client_reference_id = 006...`.
- **Webhooks → tu destino → Event deliveries**: debe aparecer el evento con respuesta **200**.

## 11. Revisar en la base de datos (Salesforce)

Developer Console → *Query Editor* (o `sf data query --target-org donation-UADY-lab -q "..."`):

```sql
SELECT Id, Name, StageName, Amount, Stripe_Pago_Id__c, CreatedDate, LastModifiedDate, CloseDate
FROM Opportunity ORDER BY CreatedDate DESC LIMIT 5
```

- **Antes de pagar** (con Checkout abierto): ya existe la Opportunity en `Prospecting`, sin `Stripe_Pago_Id__c`. Eso prueba que se registró antes del pago (CA1).
- **Después del pago exitoso**: `Closed Won`, `Stripe_Pago_Id__c = pi_...` (el mismo Id que ves en el Dashboard), y existe su reconocimiento:
  ```sql
  SELECT Name, Monto__c, Donativo__c FROM Reconocimiento_Publico__c ORDER BY CreatedDate DESC LIMIT 5
  ```
- **Rechazado o cancelado**: sigue `Prospecting`, sin `Stripe_Pago_Id__c`.
- Para ir del pago a la donación (CA2): copia el `donativo_id` de la metadata del pago en Stripe y búscalo: `SELECT Id, StageName, Amount FROM Opportunity WHERE Id = '006...'`, o pégalo en la barra de dirección de Salesforce (`/lightning/r/Opportunity/006.../view`).

## 12. Comparar montos

`Amount` de la Opportunity × 100 = monto en centavos que Stripe muestra en el evento (`amount_total`). Ejemplo: `Amount = 1500.50` → Stripe `MXN $1,500.50` (`amount_total: 150050`). Prueba al menos:
- un paquete (`$1,000`, `$3,000`, `$5,000`);
- un monto libre con centavos, por ejemplo `1,500.50`;
- `$100` (mínimo permitido).

Si los montos no coincidieran, el webhook **no** confirma y deja en el log `aviso no aplicado (monto o moneda no coinciden)`.

## 13. Notificaciones (CA7)

| Resultado | Dónde se avisa | Qué debes ver |
|---|---|---|
| Éxito | Muro (al volver de Stripe) | "¡Gracias por tu donación! Tu pago se confirmó…" |
| Rechazo | Checkout (al instante) | Mensaje de tarjeta rechazada de Stripe |
| Cancelación | Página de registro | "Pago no completado", referencia y *Intentar de nuevo* |

Correo: en modo de prueba Stripe **no** envía recibos automáticos. Para ver cómo se vería: Dashboard → el pago → *Receipt history* → ⋯ → **Send receipt**. En producción se envía solo si activas Settings → *Customer emails* → *Successful payments* (el código ya manda `receipt_email`). El correo propio de Salesforce queda para US-07. [Recibos](https://docs.stripe.com/receipts).

## 14. Pruebas automáticas (Apex)

```bash
sf apex run test --class-names MesaPagosStripeTest --class-names MesaRegalosDonativoTest --class-names MesaCampanasTest --result-format human --code-coverage --wait 10 --target-org donation-UADY-lab
```

`MesaPagosStripeTest` cubre: monto desde lo guardado (paquete y libre), referencia, idempotencia, firma válida/inválida/vencida, aviso repetido, monto o moneda distintos, pago asociado a otro donativo, cancelación y fallo, y que un evento viejo no revierta un pago.

## 15. Stripe CLI (opcional)

No es necesario para esta integración, pero ayuda a reenviar eventos. Como ya usas Scoop en Windows:
```powershell
scoop bucket add stripe https://github.com/stripe/scoop-stripe-cli.git
scoop install stripe
stripe login
```
- Reenviar un evento real a tu webhook (por ejemplo, para comprobar que un duplicado no hace nada): `stripe events resend evt_XXXX --webhook-endpoint we_XXXX`
- `stripe trigger checkout.session.completed` crea un evento con datos genéricos: el webhook responde 200 pero lo **ignora** (no trae la referencia de un donativo). Sirve solo para ver que la firma pasa.

Instalación oficial: [docs.stripe.com/stripe-cli](https://docs.stripe.com/stripe-cli).

## 16. Errores frecuentes

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| "El pago en línea no está disponible por ahora" | Falta *Dirección del sitio* en Configuración de Stripe, o no empieza con `https://` | Paso 3.3 |
| "No pudimos abrir la pasarela de pago" | Clave mal capturada, falta el permission set del guest o el parámetro no se llama `SecretKey` | Pasos 3.2 y 3.4; revisa el log del guest: verás `HTTP 401` (clave) o un error de credencial |
| Al volver de Stripe aparece "página no encontrada" | La dirección del sitio no coincide con la real (por ejemplo, falta `/s`) | Corrige *Dirección del sitio* |
| El pago aparece en Stripe pero el donativo sigue `Prospecting` | El webhook no llegó o falló | Dashboard → Webhooks → *Event deliveries*: 400 = secreto `whsec_` incorrecto; 500 = falta el secreto o error (ver log); 404/401 = URL o permiso del guest |
| Webhook 400 después de cambiar de sandbox | Cada destino tiene su propio `whsec_` | Copia el secreto del destino actual |
| El muro se queda en "Confirmando tu pago" | El webhook tardó o falló (ver fila anterior) | Recarga después; si falla, concilia a mano (README) |
| Log: `aviso no aplicado (monto o moneda no coinciden)` | El monto o la moneda del pago no coinciden con la Opportunity | No se confirma por seguridad; revísalo y concilia a mano si procede |
| Las propiedades *(Ya no se usa) Payment Link* siguen en Builder | Salesforce no deja quitarlas mientras el sitio publicado las tenga guardadas | Ignóralas: el código ya no las lee. Se podrán borrar del componente cuando nadie las tenga configuradas |

**Al terminar:** borra los datos de prueba con `scripts/apex/limpiar-pruebas.apex` si aplica, y nunca subas claves al repositorio.
