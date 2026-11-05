# Pendientes vs. rúbrica

Fechas: **Entrega 1 mar 10 nov** · **Entrega 2 mar 17 nov** · **Defensa mié 18 nov** · Evento vie 20 nov. Hora límite 23:59 (Mérida).
Estado según el repo y las respuestas del cliente en #questions del 3 y 4 de nov (sin verificar contra una org).

## 0. Mínimos (pasa / no pasa, −10 pts de equipo cada uno en la Entrega 2)

- [ ] **M1** Verificar que todo corre en modo de prueba (Stripe test, tarjetas de prueba, datos ficticios).
- [ ] **M2** Prueba de seguridad del visitante, repetible por el profesor (ver §5).
- [ ] **M3** Revisar el **historial de commits** completo buscando claves (`git log -p | grep -iE "sk_|pk_|whsec_|secret"`). El repo es público.

## 1. Antes de la Entrega 1 (10 nov)

**Sitio y flujo de donación**
- [ ] Donación **sin token**: un formulario único (el cliente confirmó que cualquier visitante debe poder donar).
- [ ] Lista de campañas con meta, avance y fechas; con una sola campaña, ir directo a ella.
- [ ] Campañas con nombre, meta, inicio y fin obligatorios; activa solo dentro de su rango.
- [ ] Montos sugeridos $100, $250, $500, $1,000, $2k, $5k, $10k y $20k, más monto libre; mínimo según la pasarela; sin máximo; confirmación desde $1,000.
- [ ] Modalidades: anónima, con crédito y con factura (hoy solo existe Pública/Privada).
- [ ] Factura: nombre y RFC con validación del patrón SAT (RF-F1) y marca "solicita factura" visible para staff (RF-F2).
- [ ] Donación anónima: staff la ve como anónima; no se puede pedir factura (RF-D2).
- [ ] Registro de la donación con una **referencia** que viaje a la pasarela (RF-D3). Ver la tensión en §6.
- [ ] Página de agradecimiento que no afirma un pago no confirmado (RF-D4).
- [ ] Vista de staff: administrar campañas, listar donaciones, confirmar pago a mano (RF-S1 a S3).
- [ ] Moderación de nombres públicos (lista negra y quitar entradas) y lista con autoscroll.
- [ ] Cuenta de Stripe en modo prueba, sin activarla.

**Documentación**
- [ ] Crear `docs/` con el backlog enlazado desde el README, incluido el % de avance y cómo se calculó.
- [ ] `docs/seguridad.md`: prueba del visitante (pasos, esperado, obtenido, evidencia), permisos del guest y su porqué, dónde están las claves, clasificación de datos personales, riesgos conocidos (incl. spam).
- [ ] `docs/bitacora_ia.md`: fecha, autor, herramienta, historia, prompt, qué verificaron, qué corrigieron, aceleración estimada. **Mínimo 3 entradas con error de la IA**, de los tres integrantes.
- [ ] `docs/contribucion.md` (una tabla por hito, con evidencia).
- [ ] `docs/preguntas_y_reportes.md` (≥4 entradas por persona, en ≥2 semanas distintas, con qué pasó después).
- [ ] Etiqueta `entrega-1` y aviso en el canal de entregas con el enlace al repo.

**Limpieza técnica**
- [ ] Quitar los `System.debug('DATOS RECIBIDOS…')` de `MesaRegalosController` (datos personales en logs).
- [ ] Quitar el Id de Opportunity hard-coded del comentario de `simulador-donativo.apex`.
- [ ] Mover montos, paquetes y límites a un solo lugar (hoy están duplicados en Apex y en `mesaDonacion`).
- [ ] Ejecutar Code Analyzer y atender o justificar cada hallazgo.
- [ ] Respaldos semanales de metadata (`sf project retrieve`) subidos al repo; al menos un integrante entra a la org cada semana.

## 2. Antes de la Entrega 2 (17 nov)

- [ ] Webhook de Stripe → Salesforce que deja la donación pagada sin intervención (RF-D5, V3a).
- [ ] Comprobante: el cliente dijo que basta el recibo de la pasarela; el único correo extra es el de la factura (que Salesforce envía tras un formulario).
- [ ] Rechazar avisos falsos (firma) y deduplicar avisos repetidos (RF-V3b, segundo nivel).
- [ ] Registro de avisos rechazados y distinción automática/manual para staff (RF-S4).
- [ ] Manejo de errores demostrado en al menos un caso (pago cancelado, aviso fallido, correo no sale).
- [ ] Bulkificación: sin consultas ni escrituras en ciclos (hoy `confirmarPago` consulta `CampaignMemberStatus` por miembro).
- [ ] Actualizar `docs/seguridad.md` para el aviso de la pasarela (secretos del webhook, permisos del usuario de integración).
- [ ] Etiqueta `entrega-2` y bitácoras actualizadas con entradas de los tres.

## 3. Defensa oral (18 nov), individual

- [ ] Explicar tu parte sin leer y mostrarla funcionando.
- [ ] Justificar una decisión de diseño y la alternativa descartada.
- [ ] Contar un caso en que corregiste a la IA.
- [ ] Todo código generado por IA debe poder explicarse.

## 4. Equipo: contribución (pesa en C9 y en la defensa)

- [ ] El historial muestra un solo autor. Los otros integrantes necesitan commits propios ligados a historias, o contribución documentada en `docs/contribucion.md`.

## 5. Prueba de seguridad del visitante (M2 / RF-V2)

- [ ] Con donaciones de otras personas en la org, intentar **leer** como guest (UI, llamadas Apex directas, REST, SOQL vía `/services/data`) y **modificar**.
- [ ] Guardar pasos, resultado esperado/obtenido y evidencia, para que otra persona los repita.
- [ ] Documentar que `MesaRegalosController` es `without sharing` y por qué; revisar que `obtenerMuro` y `obtenerAvance` no devuelvan nada de donantes anónimos.

## 6. Tensiones con la guía (confirmar con el profesor)

1. **Registro antes vs. después del pago.** RF-D3 pide una donación pendiente antes de abrir la pasarela; el cliente dijo que el registro solo se crea tras un pago exitoso. Decidir cómo cumplir ambos.
2. **Meta inmutable vs. RF-S1 CA2.** El cliente no quiere cambiar la meta una vez activa; la guía pide que al cambiarla el sitio muestre la nueva. ¿Se permite editarla antes de activarse?
3. **Comprobante propio vs. recibo de la pasarela** (RF-D5, RF-S3 CA2).
4. **Factura siempre pública** (propuesta de otro equipo) vs. privacidad y modalidad anónima.

## 7. Preguntas que siguen abiertas

1. RF-S3: ¿existe el botón de confirmación manual y en qué casos se usa? (El cliente no entendió la pregunta.)
2. ¿Qué datos mínimos exige una factura? (El cliente devolvió la pregunta al equipo.)
3. Cuando una campaña llega al 100 %, ¿cómo se decide si sigue recibiendo donaciones?
4. ¿El monto mínimo de $50 queda confirmado, o es el que indique la pasarela?
5. Para el webhook de Stripe en un Developer Edition: ¿se acepta un endpoint de Apex REST con acceso de guest? ¿Y guardar el secreto de firma en Custom Metadata sin acceso para el guest?
6. ¿Cómo debemos registrar en la bitácora de IA el código que se generó antes de la guía?

Las respuestas del cliente ya recibidas (montos, campañas, factura, comprobante, roles, alcance) están resumidas en `docs/respuestas_cliente.md`.
