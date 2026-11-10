# Mesa de regalos · México Dreaming

Proyecto base para que los ex-estudiantes de la materia de Salesforce actualicen sus datos (entrada) y registren un donativo en dinero, con control de qué se hace público.

**Estado:** código escrito y revisado a mano; **no se ha desplegado ni probado contra una org real**.  
Se desplegará primero en una Developer Edition y corre las pruebas antes de usarlo con datos reales.

## Backlog y avance (Entrega 1)

- **Backlog en el repo:** [docs/backlog.md](docs/backlog.md) (ID, RF que cubre, hito, historia, criterios, estado y evidencia).
- **Tablero (Jira):** [backlog del proyecto](https://fernandojoachinp.atlassian.net/issues?jql=project%20%3D%20SCRUM%20ORDER%20BY%20key%20ASC).
  Cada historia (`US-xx`) tiene su descripción, sus criterios de aceptación (CA) y su estado; las historias de la entrega llevan la etiqueta `entrega-1`.
- **Estados:** *Por hacer*, *En curso*, *En revisión* y *Finalizado*. Una historia está **cumplida** solo cuando está en *Finalizado*, es decir,
  cuando **todos** sus criterios de aceptación se demostraron con evidencia (demo, video o captura) en el escenario de prueba y sin romper ninguno.
  Una historia a medias cuenta como no cumplida.
- **Cómo se calcula el avance:** `historias en Finalizado ÷ historias del backlog que cubren requisitos de la Entrega 1 × 100`.
  Las historias descartadas (etiqueta `descartada`) no cuentan.
- **Avance al 10 de noviembre de 2026:** **20 %** (3 de 15 historias de la Entrega 1 en *Finalizado*: US-01, US-02 y US-20; el cálculo está en `docs/backlog.md`).
  Es provisional hasta reunir las capturas de evidencia. Este número se actualiza antes de la entrega con el conteo del día.
- **Documentos de la entrega** (en `docs/`): `seguridad.md` (prueba del visitante, permisos, datos personales y riesgos) y `bitacora_ia.md`
  (bitácora de uso de IA). Las pestañas de contribución y de preguntas y reportes se agregan en `docs/` con su ticket.

## Qué incluye

| Pieza | Para qué |
|---|---|
| Campos en **Contact** | Generación, cuenta de Trailhead, certificaciones, consentimiento de contacto (con fecha y versión del aviso). La baja usa el campo estándar *Email Opt Out*. |
| Campo en **CampaignMember** | `Token_Acceso__c`: token aleatorio de 64 caracteres para el enlace personal de cada persona. |
| Campos en **Opportunity** (donativo) | Visibilidad (pública/privada), LinkedIn, consentimiento de publicación, mostrar monto, versión del aviso y contacto donador. |
| Objeto **Reconocimiento público** | Es lo **único** que se muestra en el sitio. Se crea solo si el donativo es público y está pagado. Incluye estado de publicación en LinkedIn y texto sugerido. |
| Objeto **Ofrecimiento en especie** | Seguimiento de apoyos no monetarios (boletos, hospedaje, etc.). Solo captura interna por ahora. |
| `MesaRegalosController` | Lo que usa el sitio. Todo pasa por el token. |
| `MesaRegalosService` | Avanza el embudo y confirma pagos (también invocable desde un Flow). |
| Trigger `CampaignMemberToken` | Asigna el token al crear cada miembro de campaña. |
| LWC `mesaInicio`, `mesaRegistro`, `mesaReencuentro`, `mesaDonacion`, `mesaMuro` | Páginas del sitio de Experience Cloud (inicio, registro/invitación, reencuentro, donación con paquetes y monto abierto, muro). |
| LWC `mesaUtil` | Funciones compartidas (no es visual). |
| Permission set `Mesa_Regalos_Admin` | Permisos para el equipo que administra. |

## Cómo funciona

1. Cada ex-alumno es un **Contact** y un **CampaignMember** de la campaña "México Dreaming", con estado `Identificado`.
2. El correo lleva dos enlaces personales: `https://[SITIO]/reencuentro?token=XXXX` y `https://[SITIO]/donar?token=XXXX`. (Posiblemente este último desaparezca, sería uno para invitar a compañeros de trabajo y el de donar se enviaría después de tener actualizada la información y generar una promesa de donación)
3. Reencuentro guarda los datos → estado `Respondió`. Donar registra una **promesa** (Opportunity en etapa *Prospecting*) → estado `Redirigido a donar`.
4. Cuando se confirma el pago, `MesaRegalosService.confirmarPago` marca *Closed Won*, estado `Donó` y, si el donativo era público, crea el **Reconocimiento público**.
5. El muro del sitio lee únicamente Reconocimientos públicos. El monto solo se muestra si la persona lo autorizó. (De igual forma se planea generar una publicación de linkedIn, esta se espera al final de la campaña¿?)

Etapas del donativo:
* **Prospecting** = promesa registrada
* **Closed Won** = pago confirmado.


## Qué probar?

1. **Monto:** en `/donar?token=…`, elige "Otro monto" y escribe `1,500`. Debe aceptarlo. Prueba también `999` (debe rechazar) y cada paquete.
2. **Paquete:** elige "Paquete $3,000" y confirma que el donativo queda en $3,000 con `Paquete = P3000`.
3. **Registro propio:** abre `/registro` sin token con un correo nuevo. Debe dejarte continuar a donar.
4. **Empresa:** regístrate como empresa, dona con visibilidad pública y marca el pago con `confirmarPago`. El reconocimiento debe llevar el nombre de la empresa.
5. **Invitación:** abre `/registro?token=…` con el token de un ex-alumno e invita a alguien. No debe mostrar ningún enlace; revisa que el contacto exista con `Origen = Invitación`.
6. **Correo repetido:** vuelve a registrar el mismo correo. Debe mostrar el mensaje genérico y no crear nada.

## Despliegue (Developer Edition)

Se estará desplegando con el CLI, Salesforce CLI

```bash
sf org login web --alias mesa-dev
sf project deploy start --source-dir force-app --target-org mesa-dev
sf org assign permset --name Mesa_Regalos_Admin --target-org mesa-dev
sf apex run --file scripts/apex/crear-campana.apex --target-org mesa-dev
sf apex run test --test-level RunLocalTests --wait 10 --target-org mesa-dev
```

Si se llegarán a crear miembros de campaña antes de desplegar el trigger; para obtener un token, ejecutamos:  
-> `sf apex run --file scripts/apex/tokens-faltantes.apex`.  
Durante el despliegue para mockear una donación se ha usado:  
-> `sf apex run --file scripts/apex/simulador-donativo.apex`.

Para re-desplegar y que no haya fallos:
``` bash
sf project deploy start --dry-run --source-dir force-app --target-org mesa-dev --test-level RunLocalTests --wait 15
sf project deploy start --source-dir force-app --target-org mesa-dev
sf apex run test --test-level RunLocalTests --wait 10 --target-org mesa-dev
```

## Sitio de Experience Cloud

1. *Setup → Digital Experiences → Settings*: activar Digital Experiences.
2. *All Sites → New*: crear un sitio. URL sugerida: `mexico-dreaming`. URL usada para despliegue prueba: `mexicodreamingtest`.
3. En *Builder*, crear páginas y arrastrar con su respectivo componente:
   - Inicio → **Mesa - Inicio**
   - `/registro` → **Mesa - Registro e invitación** (pegar el Id de la campaña)
   - `/reencuentro` → **Mesa - Reencuentro** (Para actualizar información)
   - `/donar` → **Mesa - Donación** ()
   - `/muro` → **Mesa - Muro y avance** (pegar el Id de la campaña)  
   {El Id de la campaña se tendrá que generar cada año, se creó un script `crear-campana.apex` }
4. En las que corresponda configurar la URL del aviso de privacidad. En Donación, la URL de pago es opcional (vacía por ahora).
5. *Workspaces → Administration → Pages → Go to Force.com* (o *Settings → Public Access Settings*) → perfil del guest → **Enabled Apex Class Access** → agregar `MesaRegalosController`. (Para que no se tengan que loguear)
6. **No** des al perfil guest permisos sobre Contact, CampaignMember ni Opportunity. Todo pasa por la clase Apex.
7. Publicar el sitio.

## Antes de usarlo con personas reales

- **Aviso de privacidad:** redactarlo y publicarlo; el sitio ya guarda la versión aceptada.
- **Meta:** captura el monto en el campo *Ingreso esperado* de la campaña; de ahí sale el porcentaje de avance. Si no se quiere mostrar públicamente, desmarca "Mostrar avance" en el componente.
- **Enlaces personales:** el token es la única llave. No reenviar ni poner en listas públicas. Para armar el correo, usar una fórmula en CampaignMember que una la URL del sitio con `Token_Acceso__c` (la URL depende del sitio que crees).
- **LinkedIn:** el sistema deja una cola (*Reconocimientos públicos* con estado *Pendiente de publicar*) con texto sugerido. Publicar automáticamente requiere una app aprobada por LinkedIn; por ahora lo hace una persona.
- **Pagos:** pendiente. Cuando haya cuenta y Stripe, el webhook solo debe llamar a `MesaRegalosService.confirmarPago` con el Id del donativo (el componente ya manda ese Id como `client_reference_id` si configuras la URL de pago).

## Pendiente (por decidir)

Captura de ofrecimientos en especie desde el sitio (hoy es interna).  
  
##    
##  
##  
## V2. Registro, invitaciones y empresas

Nuevo componente **Mesa - Registro e invitación** y nuevo método `registrarDonador` en `MesaRegalosController`.

**Dos modos, según la URL:**

| URL | Qué es | Qué pasa |
|---|---|---|
| `/registro` (sin token) | La persona se registra sola | Se crea Contact (y empresa si aplica) y su lugar en la campaña con estado `Interesado`. Se le devuelve **su** token para continuar a donar. |
| `/registro?token=…` | Un ex-alumno invita a otra persona o empresa | Se crea el contacto con estado `Identificado` y se guarda quién lo invitó. **No se entrega el token del invitado al ex-alumno**: el equipo hace llegar el enlace. |

**Empresas.** Si marca "Dono en representación de una empresa", se crea (o reutiliza, si el nombre coincide exactamente) un **Account**. Entonces:
- El donativo queda ligado a ese Account.
- En la página de donación aparece "Donativo a nombre de [empresa]".
- El **reconocimiento público lleva el nombre de la empresa**, sin generación (que es un dato de la persona).

**Protecciones**, porque esta página es pública y cualquiera puede abrirla:
- **Campo trampa** invisible: si se llena, es un programa automático; se responde "listo" y no se guarda nada.
- **Tope de 30 registros por hora** en toda la org (`maxRegistrosPorHora`).
- **No se modifica ningún contacto existente.** Si el correo ya existe, se responde un mensaje genérico y no se crea nada. Así nadie puede pisar datos de otra persona.
- El formulario solo **devuelve** el token recién creado de quien se registra; no lee nada más del sistema.

**Campos nuevos** (todos opcionales, vacíos en lo ya existente):
- `Contact.Registro_Como_Empresa__c`, `Contact.Origen_Registro__c` (Interno / Sitio / Invitación), `Contact.Invitado_Por__c` (relación a otro Contact).


## Resumen de archivos

**Nuevos**
- `lwc/mesaUtil/` — funciones compartidas (monto, direcciones, errores). No es visual.
- `lwc/mesaInicio/` — página de inicio.
- `lwc/mesaRegistro/` — registro e invitación.
- `objects/Contact/fields/Registro_Como_Empresa__c`, `Origen_Registro__c`, `Invitado_Por__c`
- `scripts/apex/limpiar-pruebas.apex` — borra los donativos de un contacto de prueba para repetir la simulación.


##    
##  
##  
## V2. Después de llamada
# Donaciones para Campañas — México Dreaming

Campaña de donativos tipo "mesa de regalos" (Ohana) para la comunidad de Salesforce.
Cualquier persona se registra y dona desde un solo formulario, sin cuenta ni enlace personal.
Construida con Experience Cloud (LWR), Lightning Web Components y Apex.

## Flujo
1. La persona entra al sitio y elige un monto (paquetes de $1,000, $3,000 y $5,000, o monto
   abierto desde $100 MXN) (cantidades de ejemplo).
2. Elige cómo aparecerá en el muro: **Pública** (nombre y, si quiere, enlace de LinkedIn) o
   **Anónima** ("Anónimo"). El monto se muestra en ambos casos.
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
- [ ] 5 Limpieza
