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

    @AuraEnabled
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

    // ---------- Listas de las secciones del panel ----------

    public class CampanaFilaDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String nombre;
        @AuraEnabled public Boolean activa;
        @AuraEnabled public Boolean cerrada;
        @AuraEnabled public Date fechaInicio;
        @AuraEnabled public Date fechaFin;
        @AuraEnabled public Decimal meta;
        @AuraEnabled public Decimal total;
        @AuraEnabled public Integer donativos;
    }

    public class ReconocimientoFilaDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String nombre;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public String campana;
        @AuraEnabled public Datetime fecha;
        @AuraEnabled public Boolean visible;
    }

    public class DonativoFilaDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String nombre;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public String etapa;
        @AuraEnabled public Boolean pagado;
        @AuraEnabled public String campana;
        @AuraEnabled public Date fecha;
    }

    /** Todas las campañas (activas, pausadas y cerradas) con lo recaudado de cada una. */
    @AuraEnabled
    public static List<CampanaFilaDTO> listarCampanas() {
        Map<Id, Decimal> total = new Map<Id, Decimal>();
        Map<Id, Integer> cuenta = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT CampaignId cid, SUM(Amount) t, COUNT(Id) n
            FROM Opportunity
            WHERE StageName = 'Closed Won' AND CampaignId != null
            WITH USER_MODE
            GROUP BY CampaignId
        ]) {
            total.put((Id) ar.get('cid'), (Decimal) ar.get('t'));
            cuenta.put((Id) ar.get('cid'), (Integer) ar.get('n'));
        }
        Date hoy = Date.today();
        List<CampanaFilaDTO> filas = new List<CampanaFilaDTO>();
        for (Campaign c : [
            SELECT Id, Name, IsActive, StartDate, EndDate, ExpectedRevenue
            FROM Campaign
            WITH USER_MODE
            ORDER BY IsActive DESC, StartDate DESC NULLS LAST, Name
            LIMIT 200
        ]) {
            CampanaFilaDTO f = new CampanaFilaDTO();
            f.id = c.Id;
            f.nombre = c.Name;
            f.activa = c.IsActive;
            f.cerrada = c.EndDate != null && c.EndDate < hoy;
            f.fechaInicio = c.StartDate;
            f.fechaFin = c.EndDate;
            f.meta = c.ExpectedRevenue == null ? 0 : c.ExpectedRevenue;
            f.total = total.containsKey(c.Id) && total.get(c.Id) != null ? total.get(c.Id) : 0;
            f.donativos = cuenta.containsKey(c.Id) ? cuenta.get(c.Id) : 0;
            filas.add(f);
        }
        return filas;
    }

    /** Reconocimientos públicos, los más recientes primero (para moderar el muro). */
    @AuraEnabled
    public static List<ReconocimientoFilaDTO> listarReconocimientos() {
        List<ReconocimientoFilaDTO> filas = new List<ReconocimientoFilaDTO>();
        for (Reconocimiento_Publico__c x : [
            SELECT Id, Name, Monto__c, Campana__r.Name, CreatedDate, Mostrar_En_Muro__c
            FROM Reconocimiento_Publico__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            ReconocimientoFilaDTO f = new ReconocimientoFilaDTO();
            f.id = x.Id;
            f.nombre = x.Name;
            f.monto = x.Monto__c;
            f.campana = x.Campana__r == null ? '' : x.Campana__r.Name;
            f.fecha = x.CreatedDate;
            f.visible = x.Mostrar_En_Muro__c;
            filas.add(f);
        }
        return filas;
    }

    /** Donativos (oportunidades) con su estado de pago, los más recientes primero. */
    @AuraEnabled
    public static List<DonativoFilaDTO> listarDonativos() {
        List<DonativoFilaDTO> filas = new List<DonativoFilaDTO>();
        for (Opportunity o : [
            SELECT Id, Name, Amount, StageName, Campaign.Name, CloseDate
            FROM Opportunity
            WHERE CampaignId != null
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            DonativoFilaDTO f = new DonativoFilaDTO();
            f.id = o.Id;
            f.nombre = o.Name;
            f.monto = o.Amount;
            f.etapa = o.StageName;
            f.pagado = o.StageName == 'Closed Won';
            f.campana = o.Campaign == null ? '' : o.Campaign.Name;
            f.fecha = o.CloseDate;
            filas.add(f);
        }
        return filas;
    }
}
