import { LightningElement } from 'lwc';
import enviarAyuda from '@salesforce/apex/MesaRegalosController.enviarAyuda';
import { mensajeError } from 'c/mesaUtil';

// Deben coincidir con MesaRegalosController (el servidor es quien manda).
const CORREO = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const REFERENCIA = /^[A-Za-z0-9]{4,20}$/;
const MENSAJE_MINIMO = 10;

/**
 * Formulario "¿Necesitas ayuda?": crea un Case en Salesforce. Va dentro del pie del sitio, así que
 * está disponible en todas las páginas, también cuando un pago no se completa.
 */
export default class MesaAyuda extends LightningElement {
    nombre = '';
    correo = '';
    referencia = '';
    mensaje = '';
    sitioWeb = '';
    error = '';
    enviando = false;
    numeroCaso = '';

    get enviado() {
        return !!this.numeroCaso;
    }

    get mostrarFormulario() {
        return !this.enviado;
    }

    get etiquetaBoton() {
        return this.enviando ? 'Enviando…' : 'Enviar';
    }

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
    }

    validar() {
        if (!this.nombre.trim()) {
            return 'Escribe tu nombre.';
        }
        if (!CORREO.test(this.correo.trim())) {
            return 'Escribe un correo válido para poder responderte.';
        }
        if (this.referencia.trim() && !REFERENCIA.test(this.referencia.trim())) {
            return 'La referencia solo lleva letras y números, tal como aparece en tu comprobante.';
        }
        if (this.mensaje.trim().length < MENSAJE_MINIMO) {
            return 'Cuéntanos con un poco más de detalle qué necesitas.';
        }
        return '';
    }

    async enviar() {
        this.error = this.validar();
        if (this.error) {
            return;
        }
        this.enviando = true;
        try {
            const r = await enviarAyuda({
                datosJson: JSON.stringify({
                    nombre: this.nombre,
                    correo: this.correo,
                    referencia: this.referencia || null,
                    mensaje: this.mensaje,
                    sitioWeb: this.sitioWeb
                })
            });
            // Con el campo trampa lleno el servidor responde "bien" sin número: no se muestra confirmación falsa.
            this.numeroCaso = (r && r.numeroCaso) || 'recibida';
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.enviando = false;
        }
    }

    cerrar() {
        this.dispatchEvent(new CustomEvent('cerrar'));
    }
}
