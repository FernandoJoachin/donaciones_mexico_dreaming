// Campañas y donativos de DEMOSTRACIÓN para la presentación en clase (datos ficticios).
// Ejecutar: sf apex run --file scripts/apex/campanas-demostracion.apex --target-org class2026E
// Idempotente: actualiza las campañas por nombre y los donativos por su clave "DEMO CAMPAÑAS | ...".
// Quitar los donativos: DELETE [SELECT Id FROM Opportunity WHERE Name LIKE 'DEMO CAMPAÑAS | %'];
// Las imágenes están en el recurso estático MesaCampanasImg (force-app/main/default/staticresources) y se sirven desde el propio sitio:
// el sitio bloquea imágenes de otros dominios (política de seguridad de contenido).
// El controlador solo acepta URL https:// (no rutas relativas): se usa la dirección completa del sitio. Cambiarla si el sitio cambia de dominio.
String IMG = 'https://uady--class2026e.sandbox.my.site.com/mesaregalos/resource/MesaCampanasImg/';
Date hoy = Date.today();

// nombre, descripción, meta (null = sin meta), inicio, fin (null = siempre abierta), imagen
List<Map<String, Object>> defs = new List<Map<String, Object>>{
    new Map<String, Object>{'nombre' => 'México Dreamin', 'meta' => 50000, 'ini' => Date.newInstance(2026, 10, 28), 'fin' => Date.newInstance(2026, 11, 20), 'img' => 'mexico-dreamin.png',
        'desc' => 'Ayúdanos a llevar a estudiantes de la UADY a México Dreamin 2026, en la Ciudad de México: boletos del evento, transporte y hospedaje. Cada aportación acerca a una persona más a la comunidad Salesforce.'},
    new Map<String, Object>{'nombre' => 'Mérida Dreamin', 'meta' => 30000, 'ini' => Date.newInstance(2026, 11, 10), 'fin' => Date.newInstance(2026, 11, 20), 'img' => 'merida-dreamin.png',
        'desc' => 'Un encuentro local para la comunidad Salesforce de Yucatán: sede, alimentos y materiales para unas 80 personas. Aporta para que la comunidad se reúna en Mérida.'},
    new Map<String, Object>{'nombre' => 'Becas de conectividad', 'meta' => 40000, 'ini' => Date.newInstance(2026, 11, 1), 'fin' => Date.newInstance(2026, 12, 15), 'img' => 'becas-conectividad.png',
        'desc' => 'Internet y equipo para que estudiantes de la Facultad de Matemáticas puedan seguir sus clases y proyectos desde casa. Cada beca cubre un plan de datos por un semestre.'},
    new Map<String, Object>{'nombre' => 'Laboratorio de cómputo', 'meta' => 80000, 'ini' => Date.newInstance(2026, 11, 5), 'fin' => Date.newInstance(2026, 12, 20), 'img' => 'laboratorio-computo.png',
        'desc' => 'Renovar equipos del laboratorio de cómputo de la facultad: computadoras, monitores y conexión para prácticas de programación y de Salesforce.'},
    new Map<String, Object>{'nombre' => 'Donación general', 'meta' => null, 'ini' => Date.newInstance(2026, 10, 28), 'fin' => null, 'img' => 'donacion-general.png',
        'desc' => 'Aporta sin elegir una campaña específica. Usamos tu donativo donde más se necesite. Esta campaña siempre está abierta.'}
};

Map<String, Campaign> porNombre = new Map<String, Campaign>();
for (Campaign c : [SELECT Id, Name FROM Campaign WHERE Name IN ('México Dreamin', 'Mérida Dreamin', 'Becas de conectividad', 'Laboratorio de cómputo', 'Donación general')]) {
    porNombre.put(c.Name, c);
}
List<Campaign> guardar = new List<Campaign>();
for (Map<String, Object> d : defs) {
    Campaign c = porNombre.get((String) d.get('nombre'));
    if (c == null) { c = new Campaign(Name = (String) d.get('nombre')); }
    c.IsActive = true;
    c.Status = 'In Progress';
    c.Description = (String) d.get('desc');
    c.ExpectedRevenue = (Decimal) d.get('meta') == null ? null : Decimal.valueOf(String.valueOf(d.get('meta')));
    c.StartDate = (Date) d.get('ini');
    c.EndDate = (Date) d.get('fin');
    c.put('Imagen_Url__c', IMG + (String) d.get('img'));
    guardar.add(c);
}
upsert guardar;
for (Campaign c : guardar) { porNombre.put(c.Name, c); }

// donativos ficticios pagados: campaña, clave, nombre, monto, visibilidad, empresa, días atrás
List<List<Object>> donativos = new List<List<Object>>{
    new List<Object>{'Becas de conectividad', 'becas-01', 'Fundación Costa Maya', 8000, 'Publica', true, 9},
    new List<Object>{'Becas de conectividad', 'becas-02', 'Sofía Herrera', 5000, 'Publica', false, 6},
    new List<Object>{'Becas de conectividad', 'becas-03', 'Taller Chaac', 5000, 'Publica', true, 4},
    new List<Object>{'Becas de conectividad', 'becas-04', 'Anónimo', 2500, 'Anonima', false, 3},
    new List<Object>{'Becas de conectividad', 'becas-05', 'Lucía Canul', 1500, 'Publica', false, 1},
    new List<Object>{'Laboratorio de cómputo', 'lab-01', 'Tecnologías Uxmal', 12000, 'Publica', true, 8},
    new List<Object>{'Laboratorio de cómputo', 'lab-02', 'Estudio Kukulkán', 7000, 'Publica', true, 5},
    new List<Object>{'Laboratorio de cómputo', 'lab-03', 'Mariana Cetina', 6000, 'Publica', false, 4},
    new List<Object>{'Laboratorio de cómputo', 'lab-04', 'Anónimo', 5000, 'Anonima', false, 2},
    new List<Object>{'Laboratorio de cómputo', 'lab-05', 'Jorge Caamal', 4000, 'Publica', false, 1},
    new List<Object>{'Donación general', 'gen-01', 'Pablo Euán', 5000, 'Publica', false, 7},
    new List<Object>{'Donación general', 'gen-02', 'Café Itzamná', 3000, 'Publica', true, 3},
    new List<Object>{'Donación general', 'gen-03', 'Ana Domínguez', 2000, 'Publica', false, 2},
    new List<Object>{'Donación general', 'gen-04', 'Anónimo', 1500, 'Anonima', false, 1},
    new List<Object>{'Mérida Dreamin', 'merida-01', 'Comunidad Salesforce Yucatán', 5000, 'Publica', true, 3},
    new List<Object>{'Mérida Dreamin', 'merida-02', 'Valeria Pool', 1500, 'Publica', false, 2},
    new List<Object>{'Mérida Dreamin', 'merida-03', 'Anónimo', 2500, 'Anonima', false, 1}
};

Set<String> correos = new Set<String>();
Set<String> nombresOpp = new Set<String>();
for (List<Object> d : donativos) { correos.add('demo.' + (String) d[1] + '@example.com'); nombresOpp.add('DEMO CAMPAÑAS | ' + (String) d[1]); }
Map<String, Contact> contactos = new Map<String, Contact>();
for (Contact k : [SELECT Id, Email FROM Contact WHERE Email IN :correos]) { contactos.put(k.Email, k); }
List<Contact> nuevos = new List<Contact>();
for (List<Object> d : donativos) {
    String correo = 'demo.' + (String) d[1] + '@example.com';
    if (!contactos.containsKey(correo)) {
        Contact k = new Contact(FirstName = 'Demo', LastName = (String) d[1], Email = correo);
        nuevos.add(k); contactos.put(correo, k);
    }
}
if (!nuevos.isEmpty()) { insert nuevos; }

Map<String, Opportunity> opps = new Map<String, Opportunity>();
for (Opportunity o : [SELECT Id, Name FROM Opportunity WHERE Name IN :nombresOpp]) { opps.put(o.Name, o); }
List<Opportunity> oppsGuardar = new List<Opportunity>();
for (List<Object> d : donativos) {
    String nombre = 'DEMO CAMPAÑAS | ' + (String) d[1];
    Opportunity o = opps.get(nombre);
    if (o == null) { o = new Opportunity(Name = nombre); }
    o.StageName = 'Closed Won';
    o.CloseDate = hoy.addDays(-((Integer) d[6]));
    o.Amount = Decimal.valueOf(String.valueOf(d[3]));
    o.CampaignId = porNombre.get((String) d[0]).Id;
    o.put('Contacto_Donador__c', contactos.get('demo.' + (String) d[1] + '@example.com').Id);
    o.put('Visibilidad__c', (String) d[4]);
    o.put('Nombre_Visible__c', (String) d[2]);
    o.put('Donacion_Empresa__c', (Boolean) d[5]);
    o.put('Consentimiento_Publicacion__c', true);
    oppsGuardar.add(o);
}
upsert oppsGuardar;

Set<Id> idsOpp = new Set<Id>();
for (Opportunity o : oppsGuardar) { idsOpp.add(o.Id); }
Map<Id, Reconocimiento_Publico__c> recs = new Map<Id, Reconocimiento_Publico__c>();
for (SObject s : Database.query('SELECT Id, Donativo__c FROM Reconocimiento_Publico__c WHERE Donativo__c IN :idsOpp')) {
    recs.put((Id) s.get('Donativo__c'), (Reconocimiento_Publico__c) s);
}
List<Reconocimiento_Publico__c> recsGuardar = new List<Reconocimiento_Publico__c>();
for (Integer i = 0; i < donativos.size(); i++) {
    List<Object> d = donativos[i];
    Boolean anonimo = (String) d[4] == 'Anonima';
    Reconocimiento_Publico__c r = recs.get(oppsGuardar[i].Id);
    if (r == null) { r = new Reconocimiento_Publico__c(); }
    r.put('Name', anonimo ? 'Anónimo' : (String) d[2]);
    r.put('Monto__c', Decimal.valueOf(String.valueOf(d[3])));
    r.put('Mostrar_En_Muro__c', true);
    r.put('Es_Empresa__c', !anonimo && (Boolean) d[5]);
    r.put('Donativo__c', oppsGuardar[i].Id);
    r.put('Campana__c', porNombre.get((String) d[0]).Id);
    recsGuardar.add(r);
}
upsert recsGuardar;
System.debug(LoggingLevel.ERROR, 'CAMPAÑAS=' + guardar.size() + ' DONATIVOS=' + oppsGuardar.size());
