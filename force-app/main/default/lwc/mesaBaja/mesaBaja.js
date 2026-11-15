import { LightningElement } from 'lwc';
import darseDeBaja from '@salesforce/apex/MesaRegalosController.darseDeBaja';
import { mensajeError } from 'c/mesaUtil';

const CORREO = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

/**
 * Baja de avisos. Responde lo mismo exista o no el correo, para no revelar quién está registrado.
 */
export default class MesaBaja extends LightningElement {
    correo = '';
    sitioWeb = '';
    enviando = false;
    listo = false;
    error;

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
    }

    async enviar() {
        this.error = undefined;
        if (!CORREO.test(this.correo.trim())) {
            this.error = 'Escribe un correo válido.';
            return;
        }
        this.enviando = true;
        try {
            await darseDeBaja({ correo: this.correo.trim(), sitioWeb: this.sitioWeb });
            this.listo = true;
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.enviando = false;
        }
    }
}