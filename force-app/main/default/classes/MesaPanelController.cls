/**
 * Datos del panel interno (componente mesaPanelAdmin). Solo lectura.
 * Va "with sharing": cada persona ve lo que su perfil o permisos le dejan ver; no se salta la seguridad.
 * El recaudado cuenta solo donativos pagados (Closed Won), igual que el sitio público.
 */
public with sharing class MesaPanelController {

    public class ResumenDTO {
        @AuraEnabled public Decimal totalRecaudado;
        @AuraEnabled public Integer donativosPagados;
        @AuraEnabled public Integer campanasActivas;
        @AuraEnabled public Integer visiblesEnMuro;
        @AuraEnabled public Integer ocultosDelMuro;
        @AuraEnabled public List<CampanaResumenDTO> campanas = new List<CampanaResumenDTO>();
        @AuraEnabled public List<RecienteDTO> recientes = new List<RecienteDTO>();
    }

    public class CampanaResumenDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String nombre;
        @AuraEnabled public Decimal total;
        @AuraEnabled public Decimal meta;
        @AuraEnabled public Integer porcentaje;
        @AuraEnabled public Boolean activa;
    }

    public class RecienteDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String nombre;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public String campana;
        @AuraEnabled public Datetime fecha;
        @AuraEnabled public Boolean visible;
    }

    @AuraEnabled(cacheable=true)
    public static ResumenDTO obtenerResumen() {
        ResumenDTO r = new ResumenDTO();
        r.totalRecaudado = 0;
        r.donativosPagados = 0;

        Map<Id, Decimal> totalPorCampana = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT CampaignId cid, SUM(Amount) total, COUNT(Id) n
            FROM Opportunity
            WHERE StageName = 'Closed Won' AND CampaignId != null
            GROUP BY CampaignId
        ]) {
            Decimal t = (Decimal) ar.get('total');
            t = t == null ? 0 : t;
            totalPorCampana.put((Id) ar.get('cid'), t);
            r.totalRecaudado += t;
            r.donativosPagados += (Integer) ar.get('n');
        }

        Date hoy = Date.today();
        r.campanasActivas = 0;
        for (Campaign c : [
            SELECT Id, Name, ExpectedRevenue, EndDate, IsActive
            FROM Campaign
            WHERE IsActive = true
            ORDER BY StartDate DESC NULLS LAST, Name
            LIMIT 50
        ]) {
            Boolean activa = c.EndDate == null || c.EndDate >= hoy;
            if (activa) {
                r.campanasActivas++;
            }
            CampanaResumenDTO d = new CampanaResumenDTO();
            d.id = c.Id;
            d.nombre = c.Name;
            d.total = totalPorCampana.containsKey(c.Id) ? totalPorCampana.get(c.Id) : 0;
            d.meta = c.ExpectedRevenue == null ? 0 : c.ExpectedRevenue;
            Decimal pct = d.meta > 0 ? (d.total * 100 / d.meta) : 0;
            d.porcentaje = Math.min(100, pct.intValue());
            d.activa = activa;
            r.campanas.add(d);
        }

        r.visiblesEnMuro = [SELECT COUNT() FROM Reconocimiento_Publico__c WHERE Mostrar_En_Muro__c = true];
        r.ocultosDelMuro = [SELECT COUNT() FROM Reconocimiento_Publico__c WHERE Mostrar_En_Muro__c = false];

        for (Reconocimiento_Publico__c x : [
            SELECT Id, Name, Monto__c, Campana__r.Name, CreatedDate, Mostrar_En_Muro__c
            FROM Reconocimiento_Publico__c
            ORDER BY CreatedDate DESC
            LIMIT 6
        ]) {
            RecienteDTO d = new RecienteDTO();
            d.id = x.Id;
            d.nombre = x.Name;
            d.monto = x.Monto__c;
            d.campana = x.Campana__r == null ? '' : x.Campana__r.Name;
            d.fecha = x.CreatedDate;
            d.visible = x.Mostrar_En_Muro__c;
            r.recientes.add(d);
        }
        return r;
    }
}
