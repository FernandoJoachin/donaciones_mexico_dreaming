import { LightningElement, api, wire } from 'lwc';
import obtenerMuro from '@salesforce/apex/MesaRegalosController.obtenerMuro';
import obtenerAvance from '@salesforce/apex/MesaRegalosController.obtenerAvance';

export default class MesaMuro extends LightningElement {
    @api campaignId; /** Id de la campaña (se configura en Experience Builder). */
    @api mostrarAvance = false; /** Poner en falso para ocultar el avance y mostrar solo el muro. */

    @wire(obtenerAvance, { campaignId: '$campaignId' })
    avance;

    @wire(obtenerMuro, { campaignId: '$campaignId' })
    muro;

    get hayMeta() {
        return this.mostrarAvance && this.avance && this.avance.data && this.avance.data.meta > 0;
    }

    get porcentaje() {
        return this.avance && this.avance.data ? this.avance.data.porcentaje : 0;
    }

    get items() {
        const datos = (this.muro && this.muro.data) || [];
        return datos.map((m, i) => ({
            clave: `${i}-${m.nombre}`,
            nombre: m.nombre,
            detalle: [
                m.generacion ? `Generación ${m.generacion}` : null,
                m.monto != null
                    ? new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(m.monto)
                    : null
            ]
                .filter(Boolean)
                .join(' · ')
        }));
    }

    get sinItems() {
        return this.muro && this.muro.data && this.muro.data.length === 0;
    }
}
