// Crea o actualiza donaciones de demostración en la campaña México Dreamin.
// Ejecutar: sf apex run --file scripts/apex/datos-prueba-muro.apex --target-org donation-UADY-lab
// Usa el Id de campaña que aparece en el log en la propiedad campaignId de mesaMuro.
// Los donativos usan nombres/correos identificables como demostración.

List<Campaign> campanas = [SELECT Id FROM Campaign WHERE Name = 'México Dreamin' AND IsActive = true LIMIT 1];
if (campanas.isEmpty()) {
    throw new IllegalArgumentException('No existe una campaña activa llamada México Dreamin.');
}
Campaign campana = campanas[0];

List<Map<String, Object>> donativos = new List<Map<String, Object>>{
    new Map<String, Object>{'clave' => '01-alicia-publica', 'correo' => 'muro.demo.alicia@example.com', 'nombre' => 'Alicia Torres', 'monto' => 7000, 'visibilidad' => 'Publica', 'dias' => 12, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '02-bruno-publico', 'correo' => 'muro.demo.bruno@example.com', 'nombre' => 'Bruno Vega', 'monto' => 6000, 'visibilidad' => 'Publica', 'dias' => 2, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '03-fundacion-publica', 'correo' => 'muro.demo.fundacion@example.com', 'nombre' => 'Fundación Amanecer', 'monto' => 5500, 'visibilidad' => 'Publica', 'dias' => 5, 'empresa' => true, 'pagado' => true},
    new Map<String, Object>{'clave' => '04-diego-publico', 'correo' => 'muro.demo.diego@example.com', 'nombre' => 'Diego Luna', 'monto' => 4000, 'visibilidad' => 'Publica', 'dias' => 1, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '05-elena-publica', 'correo' => 'muro.demo.elena@example.com', 'nombre' => 'Elena Solís', 'monto' => 3500, 'visibilidad' => 'Publica', 'dias' => 8, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '06-fabio-publico', 'correo' => 'muro.demo.fabio@example.com', 'nombre' => 'Fabio Cruz', 'monto' => 3000, 'visibilidad' => 'Publica', 'dias' => 4, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '07-gabriela-publica', 'correo' => 'muro.demo.gabriela@example.com', 'nombre' => 'Gabriela Ríos', 'monto' => 2500, 'visibilidad' => 'Publica', 'dias' => 10, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '08-hugo-publico', 'correo' => 'muro.demo.hugo@example.com', 'nombre' => 'Hugo Mora', 'monto' => 2000, 'visibilidad' => 'Publica', 'dias' => 6, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '09-ines-publica', 'correo' => 'muro.demo.ines@example.com', 'nombre' => 'Inés Pardo', 'monto' => 1500, 'visibilidad' => 'Publica', 'dias' => 3, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '10-jorge-publico', 'correo' => 'muro.demo.jorge@example.com', 'nombre' => 'Jorge Rey', 'monto' => 1000, 'visibilidad' => 'Publica', 'dias' => 9, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '11-karla-anonima', 'correo' => 'muro.demo.karla@example.com', 'nombre' => 'Karla Díaz', 'monto' => 800, 'visibilidad' => 'Anonima', 'dias' => 7, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '12-alicia-anonima', 'correo' => 'muro.demo.alicia@example.com', 'nombre' => 'Alicia Torres', 'monto' => 500, 'visibilidad' => 'Anonima', 'dias' => 0, 'empresa' => false, 'pagado' => true},
    new Map<String, Object>{'clave' => '13-pendiente', 'correo' => 'muro.demo.pendiente@example.com', 'nombre' => 'Donación pendiente (no debe verse)', 'monto' => 99000, 'visibilidad' => 'Publica', 'dias' => 0, 'empresa' => false, 'pagado' => false}
};

Set<String> correos = new Set<String>();
Set<String> nombresDonativos = new Set<String>();
for (Map<String, Object> dato : donativos) {
    correos.add((String) dato.get('correo'));
    nombresDonativos.add('DEMO MURO | ' + (String) dato.get('clave'));
}

Map<String, Contact> contactosPorCorreo = new Map<String, Contact>();
for (Contact contacto : [
    SELECT Id, Email FROM Contact WHERE Email IN :correos
]) {
    contactosPorCorreo.put(contacto.Email, contacto);
}
List<Contact> contactosNuevos = new List<Contact>();
for (Map<String, Object> dato : donativos) {
    String correo = (String) dato.get('correo');
    if (!contactosPorCorreo.containsKey(correo)) {
        Contact contacto = new Contact(
            FirstName = 'Demo',
            LastName = (String) dato.get('clave'),
            Email = correo
        );
        contactosNuevos.add(contacto);
        contactosPorCorreo.put(correo, contacto);
    }
}
if (!contactosNuevos.isEmpty()) {
    insert contactosNuevos;
}

Map<String, Opportunity> oportunidadesPorNombre = new Map<String, Opportunity>();
for (Opportunity oportunidad : [
    SELECT Id, Name FROM Opportunity
    WHERE CampaignId = :campana.Id AND Name IN :nombresDonativos
]) {
    oportunidadesPorNombre.put(oportunidad.Name, oportunidad);
}
List<Opportunity> oportunidadesGuardar = new List<Opportunity>();
for (Map<String, Object> dato : donativos) {
    String nombreOportunidad = 'DEMO MURO | ' + (String) dato.get('clave');
    Opportunity oportunidad = oportunidadesPorNombre.get(nombreOportunidad);
    if (oportunidad == null) {
        oportunidad = new Opportunity(Name = nombreOportunidad);
    }
    oportunidad.StageName = (Boolean) dato.get('pagado') ? 'Closed Won' : 'Prospecting';
    oportunidad.CloseDate = Date.today().addDays(-((Integer) dato.get('dias')));
    oportunidad.Amount = (Decimal) dato.get('monto');
    oportunidad.CampaignId = campana.Id;
    oportunidad.put('Contacto_Donador__c', contactosPorCorreo.get((String) dato.get('correo')).Id);
    oportunidad.put('Visibilidad__c', (String) dato.get('visibilidad'));
    oportunidad.put('Nombre_Visible__c', (String) dato.get('nombre'));
    oportunidad.put('Donacion_Empresa__c', (Boolean) dato.get('empresa'));
    oportunidad.put('Consentimiento_Publicacion__c', true);
    oportunidadesGuardar.add(oportunidad);
}
upsert oportunidadesGuardar;

Set<Id> idsDonativos = new Set<Id>();
for (Opportunity oportunidad : oportunidadesGuardar) {
    idsDonativos.add(oportunidad.Id);
}
Map<Id, Reconocimiento_Publico__c> reconocimientosPorDonativo = new Map<Id, Reconocimiento_Publico__c>();
String consultaReconocimientos =
    'SELECT Id, Donativo__c FROM Reconocimiento_Publico__c WHERE Donativo__c IN :idsDonativos';
for (SObject registro : Database.query(consultaReconocimientos)) {
    Reconocimiento_Publico__c reconocimiento = (Reconocimiento_Publico__c) registro;
    reconocimientosPorDonativo.put((Id) registro.get('Donativo__c'), reconocimiento);
}
List<Reconocimiento_Publico__c> reconocimientosGuardar = new List<Reconocimiento_Publico__c>();
for (Integer i = 0; i < donativos.size(); i++) {
    Map<String, Object> dato = donativos[i];
    Opportunity oportunidad = oportunidadesGuardar[i];
    Boolean anonimo = (String) dato.get('visibilidad') == 'Anonima';
    Reconocimiento_Publico__c reconocimiento = reconocimientosPorDonativo.get(oportunidad.Id);
    if (reconocimiento == null) {
        reconocimiento = new Reconocimiento_Publico__c();
    }
    reconocimiento.put('Name', anonimo ? 'Anónimo' : (String) dato.get('nombre'));
    reconocimiento.put('Monto__c', (Decimal) dato.get('monto'));
    reconocimiento.put('Mostrar_En_Muro__c', true);
    reconocimiento.put('Es_Empresa__c', !anonimo && (Boolean) dato.get('empresa'));
    reconocimiento.put('Donativo__c', oportunidad.Id);
    reconocimiento.put('Campana__c', campana.Id);
    reconocimientosGuardar.add(reconocimiento);
}
upsert reconocimientosGuardar;

System.debug(LoggingLevel.ERROR, 'CAMPAIGN_ID=' + campana.Id);
System.debug(LoggingLevel.ERROR, 'Donaciones pagadas: 12; pendientes: 1; reconocimientos: ' + reconocimientosGuardar.size());
System.debug(LoggingLevel.ERROR, 'La donante de Alicia incluye una aportación anónima: el muro debe consolidarla como Anónimo por $7,500.');
System.debug(LoggingLevel.ERROR, 'MURO_RESULTADO=' + JSON.serialize(MesaRegalosController.obtenerMuro(campana.Id)));
