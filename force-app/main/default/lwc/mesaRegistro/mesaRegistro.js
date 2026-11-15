import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import guardarDonativo from '@salesforce/apex/MesaRegalosController.guardarDonativo';
import { parseMonto, formatearMonto, mensajeError, resolverUrl, irA, guardarRetornoPago } from 'c/mesaUtil';

// Deben coincidir con MesaRegalosController (el servidor es quien manda).
const MONTO_MINIMO = 100;
const PAQUETES = { P1000: 1000, P3000: 3000, P5000: 5000 };
const LINKEDIN = /^https:\/\/([a-z]{2,3}\.)?linkedin\.com\/(in|company)\/\S+$/i;
const CORREO = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

/**
 * Registro y donación en un solo formulario, sin token: la persona se identifica con su correo.
 * Anónima oculta nombre, empresa y LinkedIn (el servidor igual los ignora).
 */
export default class MesaRegistro extends LightningElement {
    /** Id de la campaña (se configura en Experience Builder). */
    @api campaignId;
    @api avisoUrl;
    @api versionAviso = 'v1';
    /**
     * Opcional. Enlace de pago (Payment Link de Stripe). Si se llena, al registrar el donativo
     * se redirige ahí con el Id del donativo (client_reference_id) y el correo pre-rellenado.
     */
    @api urlPago;
    @api urlPagoP1000;
    @api urlPagoP3000;
    @api urlPagoP5000;
    /** Página del muro (donde se muestra el agradecimiento al terminar de pagar). */
    @api paginaMuro = 'muro';

    /** Campaña que viene en la dirección (?campana=<Id>), por ejemplo desde el botón Donar de su página. */
    campanaUrl;

    @wire(CurrentPageReference)
    leerCampanaDeLaDireccion(ref) {
        this.campanaUrl = ref && ref.state && ref.state.campana ? ref.state.campana : undefined;
    }

    /** La campaña de la dirección manda; si no viene, la que se configuró en Experience Builder. */
    get idCampana() {
        return this.campanaUrl || this.campaignId;
    }

    paquete = '';
    montoTexto = '';
    visibilidad = '';
    esEmpresa = false;
    nombreEmpresa = '';
    nombre = '';
    apellidos = '';
    linkedinUrl = '';
    correo = '';
    consentimientoAvisos = '';
    consentimientoPublicacion = false;
    aceptaAviso = false;
    sitioWeb = '';

    enviando = false;
    registrado = false;
    /** Maqueta de la pasarela: se usa mientras no haya Payment Link configurado. */
    pagoSimulado = false;
    pagoCancelado = false;
    donativoId;
    error;

    opcionesPaquete = [
        { label: 'Paquete $1,000', value: 'P1000' },
        { label: 'Paquete $3,000', value: 'P3000' },
        { label: 'Paquete $5,000', value: 'P5000' },
        { label: 'Otro monto', value: 'Abierto' }
    ];

    opcionesVisibilidad = [
        { label: 'Pública: mi nombre (o el de mi empresa) y el monto', value: 'Publica' },
        { label: 'Anónima: «Anónimo» y el monto', value: 'Anonima' }
    ];

    opcionesConsentimiento = [
        { label: 'Sí, avísenme', value: 'Si' },
        { label: 'No, gracias', value: 'No' }
    ];

    get mostrarFormulario() {
        return !this.registrado && !this.pagoSimulado && !this.pagoCancelado;
    }

    get totalPago() {
        return this.montoValido ? formatearMonto(this.montoFinal) : '';
    }

    get correoPago() {
        return this.correo.trim();
    }

    get referenciaPago() {
        return this.donativoId ? String(this.donativoId).slice(-8).toUpperCase() : '';
    }

    get esPublico() {
        return this.visibilidad === 'Publica';
    }

    get esAnonimo() {
        return this.visibilidad === 'Anonima';
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

    get montoValido() {
        const monto = this.montoFinal;
        return monto !== null && monto > 0 && (!this.esAbierto || monto >= MONTO_MINIMO);
    }

    get etiquetaBoton() {
        return this.montoValido ? `Donarás: ${formatearMonto(this.montoFinal)} MXN` : 'Elige un monto';
    }

    get botonDeshabilitado() {
        return this.enviando || !this.montoValido;
    }

    get ayudaMonto() {
        return `Monto mínimo: ${formatearMonto(MONTO_MINIMO)} MXN`;
    }

    get avisoHref() {
        return this.avisoUrl ? resolverUrl(this.avisoUrl) : undefined;
    }


    /** Payment Link que corresponde al paquete elegido. */
    get enlacePago() {
        const enlaces = {
            P1000: this.urlPagoP1000,
            P3000: this.urlPagoP3000,
            P5000: this.urlPagoP5000,
            Abierto: this.urlPago
        };
        return enlaces[this.paquete];
    }

    /** Arma la URL de pago: Id del donativo (para conciliar), correo bloqueado y, en monto libre, el monto en centavos. */
    armarUrlPago(donativoId) {
        const base = this.enlacePago;
        if (!base) {
            return null;
        }
        const separador = base.includes('?') ? '&' : '?';
        let url =
            `${base}${separador}client_reference_id=${encodeURIComponent(donativoId)}` +
            `&locked_prefilled_email=${encodeURIComponent(this.correo.trim())}`;
        if (this.esAbierto) {
            url += `&prefilled_amount=${Math.round(this.montoFinal * 100)}`;
        }
        return url;
    }

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        if (evento.target.type === 'checkbox') {
            this[campo] = evento.target.checked;
        } else {
            this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
        }
    }

    /** Revisión rápida para no hacer viajes al servidor. El servidor vuelve a validar todo. */
    validar() {
        if (!this.montoValido) {
            return this.esAbierto
                ? `Escribe un monto de ${formatearMonto(MONTO_MINIMO)} o más.`
                : 'Elige un paquete o la opción de otro monto.';
        }
        if (!this.visibilidad) {
            return 'Elige si tu donativo será público o anónimo.';
        }
        if (this.esPublico) {
            if (this.esEmpresa) {
                if (!this.nombreEmpresa.trim()) {
                    return 'Escribe el nombre de la empresa.';
                }
            } else if (!this.nombre.trim() || !this.apellidos.trim()) {
                return 'Escribe tu nombre y apellidos.';
            }
            if (this.linkedinUrl.trim() && !LINKEDIN.test(this.linkedinUrl.trim())) {
                return 'La dirección de LinkedIn no es válida (https://www.linkedin.com/in/... o /company/...).';
            }
        }
        if (!CORREO.test(this.correo.trim())) {
            return 'Escribe un correo válido.';
        }
        if (!this.consentimientoAvisos) {
            return 'Indica si quieres recibir avisos de próximos eventos y donaciones.';
        }
        if (!this.consentimientoPublicacion) {
            return 'Para continuar necesitamos tu autorización para publicar tu donativo.';
        }
        if (!this.aceptaAviso) {
            return 'Para continuar debes aceptar el aviso de privacidad.';
        }
        return undefined;
    }

    /** Maqueta: "pagar" no cobra ni confirma nada; solo lleva al muro con el mensaje "Confirmando tu pago". */
    pagarSimulado() {
        guardarRetornoPago('exito');
        irA(resolverUrl(this.paginaMuro, null, false));
    }

    /** Maqueta: cancelar deja el donativo pendiente y ofrece intentar de nuevo (sin crear otro registro). */
    cancelarSimulado() {
        this.pagoSimulado = false;
        this.pagoCancelado = true;
    }

    reintentarPago() {
        this.pagoCancelado = false;
        this.pagoSimulado = true;
    }

    async enviar() {
        this.error = this.validar();
        if (this.error) {
            return;
        }
        const comoEmpresa = this.esPublico && this.esEmpresa;
        this.enviando = true;
        try {
            const r = await guardarDonativo({
                campaignId: this.idCampana || null,
                datosJson: JSON.stringify({
                    paquete: this.paquete,
                    monto: this.esAbierto ? this.montoFinal : null,
                    visibilidad: this.visibilidad,
                    nombre: this.esPublico && !comoEmpresa ? this.nombre : null,
                    apellidos: this.esPublico && !comoEmpresa ? this.apellidos : null,
                    correo: this.correo,
                    esEmpresa: comoEmpresa,
                    nombreEmpresa: comoEmpresa ? this.nombreEmpresa : null,
                    linkedinUrl: this.esPublico ? this.linkedinUrl : null,
                    consentimientoAvisos: this.consentimientoAvisos,
                    consentimientoPublicacion: this.consentimientoPublicacion,
                    aceptaAviso: this.aceptaAviso,
                    versionAviso: this.versionAviso,
                    sitioWeb: this.sitioWeb
                })
            });

            this.donativoId = r && r.donativoId;
            const urlPago = this.donativoId ? this.armarUrlPago(this.donativoId) : null;
            if (urlPago) {
                // Con Payment Link configurado: pago real (modo de prueba de Stripe).
                this.registrado = true;
                window.location.href = urlPago;
            } else {
                // Sin Payment Link todavía: maqueta de la pasarela para no dejar al donante en una página sin salida.
                this.pagoSimulado = true;
            }
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.enviando = false;
        }
    }
}