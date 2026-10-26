// Crea la campaña "México Dreaming" con los estados del embudo.
// Ejecutar:  sf apex run --file scripts/apex/crear-campana.apex
//
// Nota: no se define aquí la meta. Captúrala en el campo "Ingreso esperado" de la campaña
// cuando se confirme el monto objetivo (es lo que usa el avance del sitio).

Campaign c = new Campaign(Name = 'México Dreaming', IsActive = true, Status = 'Planned');
insert c;

List<String> estados = new List<String>{
    'Identificado', 'Contactado', 'Respondió', 'Interesado', 'Redirigido a donar', 'Donó'
};
List<CampaignMemberStatus> filas = new List<CampaignMemberStatus>();
Integer orden = 10;
for (String e : estados) {
    filas.add(new CampaignMemberStatus(
        CampaignId = c.Id,
        Label = e,
        SortOrder = orden++,
        HasResponded = (e != 'Identificado' && e != 'Contactado')
    ));
}
insert filas;

System.debug('Campaña creada: ' + c.Id);
System.debug('Al cargar la lista de ex-alumnos como miembros, asigna Status = Identificado.');
