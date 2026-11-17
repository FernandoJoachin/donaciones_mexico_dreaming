import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import obtenerResumen from '@salesforce/apex/MesaPanelController.obtenerResumen';

const MXN = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });
const FECHA = new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });

/** Atajos a las listas estándar de Salesforce, con la acción que cada persona hace ahí. */
const ATAJOS = [
    { clave: 'Campaign', texto: 'Campañas' },
    { clave: 'Reconocimiento_Publico__c', texto: 'Moderar muro' },
    { clave: 'Opportunity', texto: 'Donativos' }
];

/**
 * Panel interno (fase 1): navegación lateral y página de Resumen con el diseño del sitio público.
 * Solo lee datos (MesaPanelController, con sharing). Las demás secciones abren las listas estándar.
 */
export default class MesaPanelAdmin extends NavigationMixin(LightningElement) {
    atajos = ATAJOS;

    @wire(obtenerResumen)
    datos;

    get cargando() {
        return !this.datos || (!this.datos.data && !this.datos.error);
    }

    get hayError() {
        return !!(this.datos && this.datos.error);
    }

    get resumen() {
        return this.datos && this.datos.data;
    }

    get totalTexto() {
        return MXN.format(this.resumen.totalRecaudado || 0);
    }

    get donativosTexto() {
        const n = this.resumen.donativosPagados || 0;
        return n === 1 ? '1 donativo pagado' : `${n} donativos pagados`;
    }

    get campanas() {
        return this.resumen.campanas.map((c) => ({
            id: c.id,
            nombre: c.nombre,
            totalTexto: MXN.format(c.total || 0),
            metaTexto: c.meta > 0 ? `de ${MXN.format(c.meta)}` : 'Sin meta',
            conMeta: c.meta > 0,
            porcentaje: c.porcentaje,
            estiloBarra: `width: ${c.porcentaje}%`,
            estado: c.activa ? 'Activa' : 'Cerrada',
            claseEstado: c.activa ? 'etiqueta etiqueta-ok' : 'etiqueta'
        }));
    }

    get recientes() {
        return this.resumen.recientes.map((r) => ({
            id: r.id,
            nombre: r.nombre,
            detalle: [r.campana, r.fecha ? FECHA.format(new Date(r.fecha)) : ''].filter(Boolean).join(' · '),
            montoTexto: r.monto == null ? '—' : MXN.format(r.monto),
            visibleTexto: r.visible ? 'En el muro' : 'Oculto',
            claseVisible: r.visible ? 'etiqueta etiqueta-ok' : 'etiqueta'
        }));
    }

    get sinRecientes() {
        return this.resumen.recientes.length === 0;
    }

    get urlSitio() {
        return 'https://uady--class2026e.sandbox.my.site.com/mesaregalos/s/';
    }

    irA(evento) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: evento.currentTarget.dataset.clave, actionName: 'list' },
            state: { filterName: 'Recent' }
        });
    }
}
