import { LightningElement, api } from 'lwc';
import { resolverUrl } from 'c/mesaUtil';

/**
 * Página informativa de facturas (US-20). No hay formulario ni se guardan datos fiscales:
 * solo explica cómo pedir la factura por correo. Todos los textos se editan en Experience
 * Builder. El correo por defecto es de ejemplo: hay que cambiarlo por el real.
 */
export default class MesaFacturas extends LightningElement {
    @api titulo = 'Facturas';
    @api introduccion =
        'Si necesitas factura de tu donativo, pídela por correo. No te pedimos datos fiscales en el formulario de donación ni los guardamos en este sitio.';
    @api correoFacturas = 'facturas@ejemplo.org';
    @api textoVolver = 'Volver al inicio';
    @api notaFinal =
        'Responderemos al mismo correo desde el que escribas. Si tienes dudas, puedes escribirnos a esa misma dirección.';

    get hrefCorreo() {
        return `mailto:${this.correoFacturas}?subject=${encodeURIComponent('Solicitud de factura')}`;
    }

    get urlVolver() {
        return resolverUrl('', null, false);
    }

    get pasos() {
        return [
            {
                numero: '1',
                titulo: 'Reúne tus datos fiscales',
                texto: 'Ten a la mano tu Constancia de Situación Fiscal del SAT vigente. De ahí tomamos tu RFC, nombre o razón social, régimen fiscal y código postal.'
            },
            {
                numero: '2',
                titulo: 'Ubica tu referencia de donación',
                texto: 'Viene en el correo de confirmación que recibiste al pagar. Con ella encontramos tu donativo, aunque lo hayas hecho de forma anónima.'
            },
            {
                numero: '3',
                titulo: 'Escríbenos',
                texto: 'Envía un correo con tu Constancia de Situación Fiscal, la referencia de tu donación y el uso de CFDI que necesitas.'
            }
        ];
    }
}
