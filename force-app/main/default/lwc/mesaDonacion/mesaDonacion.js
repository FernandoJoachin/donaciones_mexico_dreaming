import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import obtenerInvitacion from '@salesforce/apex/MesaRegalosController.obtenerInvitacion';
import guardarPromesa from '@salesforce/apex/MesaRegalosController.guardarPromesa';
import { parseMonto, formatearMonto, mensajeError } from 'c/mesaUtil';

// Deben coincidir con MesaRegalosController (el servidor es quien manda).
const MONTO_MINIMO = 100;
const PAQUETES = { P1000: 1000, P3000: 3000, P5000: 5000 };

export default class MesaDonacion extends LightningElement {
    /** Dirección de tu aviso de privacidad (se configura en Experience Builder). */
    @api avisoUrl;
    @api versionAviso = 'v1';
    /**
     * Opcional. Enlace de pago (por ejemplo, un Payment Link de Stripe). Si se llena, al registrar
     * la promesa se redirige ahí, agregando el Id del donativo como client_reference_id para
     * poder conciliar el pago. Si queda vacío, solo se muestra el mensaje de confirmación.
     */
    @api urlPago;

    token;
    invitacion;
    cargando = true;
    registrado = false;
    error;

    paquete = '';
    montoTexto = '';
    visibilidad = 'Privada';
    linkedinUrl = '';
    consentimientoPublicacion = false;
    mostrarMonto = false;
    aceptaAviso = false;

    opcionesPaquete = [
        { label: 'Paquete $1,000', value: 'P1000' },
        { label: 'Paquete $3,000', value: 'P3000' },
        { label: 'Paquete $5,000', value: 'P5000' },
        { label: 'Otro monto', value: 'Abierto' }
    ];

    opcionesVisibilidad = [
        { label: 'Privado: solo lo vemos quienes organizamos', value: 'Privada' },
        { label: 'Público: aparecer en el muro de agradecimiento', value: 'Publica' }
    ];

    @wire(CurrentPageReference)
    resolverPagina(ref) {
        if (!ref) {
            return;
        }
        const token = ref.state && ref.state.token;
        if (!token) {
            this.cargando = false;
            this.error = 'Este enlace no es válido. Usa el enlace personal que te enviamos.';
            return;
        }
        if (token !== this.token) {
            this.token = token;
            this.cargar();
        }
    }

    async cargar() {
        this.cargando = true;
        this.error = undefined;
        try {
            this.invitacion = await obtenerInvitacion({ token: this.token });
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.cargando = false;
        }
    }

    get mostrarFormulario() {
        return this.invitacion && !this.registrado;
    }

    get esPublico() {
        return this.visibilidad === 'Publica';
    }

    get esAbierto() {
        return this.paquete === 'Abierto';
    }

    get montoFinal() {
        if (PAQUETES[this.paquete]) {
            return PAQUETES[this.paquete];
        }
        return this.esAbierto ? parseMonto(this.montoTexto) : null;
    }

    get resumenMonto() {
        const monto = this.montoFinal;
        return monto ? `Aportarás ${formatearMonto(monto)} MXN` : '';
    }

    get ayudaMonto() {
        return `Monto mínimo: ${formatearMonto(MONTO_MINIMO)} MXN`;
    }

    get avisoHref(){
        return this.avisoUrl ? resolverUrl(this.avisoUrl) : undefined;
    }

    cambioPaquete(evento) {
        this.paquete = evento.detail.value;
    }

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        if (evento.target.type === 'checkbox') {
            this[campo] = evento.target.checked;
        } else {
            this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
        }
    }

    async enviar() {
        this.error = undefined;
        if (!this.paquete) {
            this.error = 'Elige un paquete o la opción de otro monto.';
            return;
        }
        const monto = this.montoFinal;
        if (this.esAbierto && (monto === null || monto < MONTO_MINIMO)) {
            this.error = `Escribe un monto de ${formatearMonto(MONTO_MINIMO)} o más.`;
            return;
        }

        this.cargando = true;
        try {
            const donativoId = await guardarPromesa({
                token: this.token,
                datosJson: JSON.stringify({
                    paquete: this.paquete,
                    monto: this.esAbierto ? monto : null,
                    visibilidad: this.visibilidad,
                    linkedinUrl: this.esPublico ? this.linkedinUrl : null,
                    consentimientoPublicacion: this.esPublico && this.consentimientoPublicacion,
                    mostrarMonto: this.esPublico && this.mostrarMonto,
                    aceptaAviso: this.aceptaAviso,
                    versionAviso: this.versionAviso
                })
            });
            this.registrado = true;
            if (this.urlPago) {
                const separador = this.urlPago.includes('?') ? '&' : '?';
                window.location.href = `${this.urlPago}${separador}client_reference_id=${encodeURIComponent(donativoId)}`;
            }
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.cargando = false;
        }
    }
}
