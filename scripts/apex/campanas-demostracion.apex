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

// US-22: historia, a quién ayuda, quién organiza y niveles de impacto de cada campaña.
Map<String, List<String>> textos = new Map<String, List<String>>();
textos.put('México Dreamin', new List<String>{ 'Llevemos a 20 estudiantes de la UADY a México Dreamin 2026.', 'México Dreamin reúne a la comunidad Salesforce de todo el país. Este año es el 20 de noviembre en la Ciudad de México y, para muchos estudiantes de Yucatán, es la primera oportunidad de conocer en persona a quienes trabajan con la plataforma todos los días.\n\nIr cuesta: el boleto del evento, el autobús de Mérida a la Ciudad de México y el hospedaje. Para la mayoría de quienes terminaron el bootcamp, ese gasto decide si van o se quedan.\n\nCon tu aportación cubrimos el viaje de 20 estudiantes. A su regreso compartirán lo que aprendieron en una sesión abierta para toda la facultad.', '20 estudiantes de la Facultad de Matemáticas que terminaron el bootcamp de Salesforce.', 'Comunidad Salesforce FMAT-UADY' });
textos.put('Mérida Dreamin', new List<String>{ 'Un día de comunidad Salesforce en Mérida, gratis para estudiantes.', 'No todos pueden viajar a la Ciudad de México. Mérida Dreamin trae la experiencia a casa: un día de charlas, talleres prácticos y encuentros con profesionales de Salesforce de la región.\n\nQueremos que la entrada sea gratuita para estudiantes. Para lograrlo hay que cubrir la sede, los alimentos y los materiales de los talleres para unas 80 personas.\n\nCada aportación hace que un estudiante asista sin pagar y se lleve algo concreto: un taller hecho con sus manos y contactos para su primer empleo.', 'Unas 80 personas, sobre todo estudiantes de la península de Yucatán.', 'Comunidad Salesforce Yucatán' });
textos.put('Becas de conectividad', new List<String>{ 'Internet en casa para que nadie deje sus clases por falta de conexión.', 'Varios estudiantes de la facultad hacen sus prácticas y proyectos desde un celular con datos limitados. Cuando se acaban los datos, se acaba la clase.\n\nEsta campaña financia becas de conectividad: un plan de internet en casa o un módem portátil durante un semestre, para quienes más lo necesitan.\n\nCada beca significa entregar tareas a tiempo, entrar a las clases en línea y practicar Salesforce sin cortes.', 'Estudiantes de la Facultad de Matemáticas sin internet estable en casa.', 'Comunidad Salesforce FMAT-UADY' });
textos.put('Laboratorio de cómputo', new List<String>{ 'Renovemos el laboratorio donde se aprende a programar.', 'El laboratorio de cómputo es donde muchos estudiantes escriben su primera línea de código y donde practican Salesforce. Varios equipos ya no soportan las herramientas actuales.\n\nCon esta campaña renovamos computadoras y monitores, y mejoramos la conexión del laboratorio para las prácticas de programación y de Salesforce.\n\nUn laboratorio que funciona bien sirve a cientos de estudiantes cada semestre.', 'Los estudiantes que usan el laboratorio de la facultad cada semestre.', 'Comunidad Salesforce FMAT-UADY' });
textos.put('Donación general', new List<String>{ 'Tu aportación va a donde más se necesite.', 'Si no sabes qué campaña elegir, esta es para ti. Repartimos las aportaciones entre las campañas que más lo necesitan y las que están más lejos de su meta.\n\nEsta campaña siempre está abierta y no tiene fecha de cierre.', 'Las campañas activas de la comunidad.', 'Comunidad Salesforce FMAT-UADY' });
Map<String, List<List<Object>>> niveles = new Map<String, List<List<Object>>>();
niveles.put('México Dreamin', new List<List<Object>>{ new List<Object>{ 250, 'Una comida para un estudiante durante el viaje' }, new List<Object>{ 1000, 'Una noche de hospedaje compartido' }, new List<Object>{ 2500, 'Un boleto de autobús Mérida–CDMX, ida y vuelta' } });
niveles.put('Mérida Dreamin', new List<List<Object>>{ new List<Object>{ 150, 'El refrigerio de un asistente' }, new List<Object>{ 500, 'Materiales de taller para cinco personas' }, new List<Object>{ 3000, 'Una sala para un taller de medio día' } });
niveles.put('Becas de conectividad', new List<List<Object>>{ new List<Object>{ 250, 'Un mes de internet para un estudiante' }, new List<Object>{ 1500, 'Un semestre de datos para un estudiante' }, new List<Object>{ 4000, 'Un módem portátil con un semestre de servicio' } });
niveles.put('Laboratorio de cómputo', new List<List<Object>>{ new List<Object>{ 500, 'Un teclado y un ratón nuevos' }, new List<Object>{ 3500, 'Un monitor' }, new List<Object>{ 12000, 'Una computadora completa' } });
niveles.put('Donación general', new List<List<Object>>{ new List<Object>{ 100, 'Suma al fondo común de la comunidad' }, new List<Object>{ 500, 'Cubre lo más urgente de una campaña' }, new List<Object>{ 1000, 'Ayuda a que una campaña llegue a su meta' } });
List<Campaign> conHistoria = new List<Campaign>();
for (Campaign c : guardar) {
    List<String> t = textos.get(c.Name);
    if (t == null) { continue; }
    c.put('Resumen__c', t[0]);
    c.put('Historia__c', t[1]);
    c.put('Para_Quien__c', t[2]);
    c.put('Organiza__c', t[3]);
    conHistoria.add(c);
}
update conHistoria;
Set<Id> idsCampanas = new Set<Id>();
for (Campaign c : guardar) { idsCampanas.add(c.Id); }
delete [SELECT Id FROM Nivel_Impacto__c WHERE Campana__c IN :idsCampanas];
List<Nivel_Impacto__c> nuevosNiveles = new List<Nivel_Impacto__c>();
for (Campaign c : guardar) {
    List<List<Object>> lista = niveles.get(c.Name);
    if (lista == null) { continue; }
    for (Integer i = 0; i < lista.size(); i++) {
        // Campos por nombre: el usuario que corre el script puede no tener permiso de campo sobre Orden__c.
        Nivel_Impacto__c n = new Nivel_Impacto__c(Campana__c = c.Id, Monto__c = Decimal.valueOf(String.valueOf(lista[i][0])),
            Descripcion__c = (String) lista[i][1]);
        n.put('Orden__c', i + 1);
        nuevosNiveles.add(n);
    }
}
insert nuevosNiveles;

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
