import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import obtenerMuro from '@salesforce/apex/MesaRegalosController.obtenerMuro';
import obtenerAvance from '@salesforce/apex/MesaRegalosController.obtenerAvance';
import obtenerCampana from '@salesforce/apex/MesaRegalosController.obtenerCampana';
import estadoPago from '@salesforce/apex/MesaRegalosController.estadoPago';
import { leerRetornoPago, formatearMonto } from 'c/mesaUtil';

const OPCIONES_ORDEN = [
    { label: 'Mayor monto', value: 'monto' },
    { label: 'Más reciente', value: 'fecha' }
];
const INTERVALO_DESPLAZAMIENTO_MS = 80;
const PAUSA_POR_INTERACCION_MS = 3000;
const TIEMPO_LIMITE_CARGA_MS = 30000;
const TAMANO_PODIO = 3;
const SIN_CAMPANA = 'No se configuró el Id de campaña para este componente.';
// Stripe suele regresar al sitio cuando ya entregó el aviso de pago; si aún no llega, se reintenta unos segundos.
const INTENTOS_ESTADO_PAGO = 5;
const ESPERA_ESTADO_PAGO_MS = 3000;

/**
 * Ordena donantes por el criterio elegido ('monto' o 'fecha'). Los empates se resuelven
 * siempre igual (más reciente y luego por nombre) para que la lista no "salte" entre cargas.
 */
function compararDonantes(a, b, criterio) {
    const diferencia = criterio === 'fecha'
        ? (b.fecha || '').localeCompare(a.fecha || '')
        : Number(b.monto) - Number(a.monto);
    return diferencia ||
        (b.fecha || '').localeCompare(a.fecha || '') ||
        (a.nombre || '').localeCompare(b.nombre || '', 'es-MX');
}

/** Hasta dos iniciales del nombre, para el avatar del podio. */
function iniciales(nombre) {
    return (nombre || '')
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((parte) => parte[0])
        .join('')
        .toUpperCase();
}

export default class MesaMuro extends LightningElement {
    @api mostrarAvance;
    @api metaCampana = 50000;

    muro;
    avance;
    isLoading = false;
    errorCarga = SIN_CAMPANA;
    errorAvance;
    orden = 'monto';
    opcionesOrden = OPCIONES_ORDEN;
    /** Solo es verdadero si la persona llega desde el flujo de pago; abrir el muro directo no muestra nada (SCRUM-99). */
    mostrarGracias = false;
    /** Verdadero solo cuando Salesforce ya recibió el aviso firmado de Stripe (CA7). */
    pagoConfirmado = false;
    _donativoRetorno;
    _estadoTimeout;

    _campaignId;
    _loadTimeout;
    _needsScrollSetup = false;
    _scrollInterval;
    _scrollPaused = false;
    _resizeObserver;
    _resizeHandler;
    _scrollContainer;
    _scrollResumeTimeout;

    /** Campaña que se muestra: la de la dirección (?campana=) si está publicada; si no, la configurada. */
    campanaEfectiva;
    /** Nombre de la campaña mostrada, para la banda y el mensaje de gracias. */
    nombreCampana;
    _campanaUrl;

    @api
    get campaignId() {
        return this._campaignId;
    }

    set campaignId(value) {
        this._campaignId = typeof value === 'string' ? value.trim() : value;
        if (!this._campanaUrl) {
            this.usarCampana(this._campaignId);
        }
    }

    /**
     * Después de donar, el flujo llega con ?campana=<Id> para mostrar el muro de esa campaña.
     * Solo se usa si la campaña está publicada (obtenerCampana devuelve nulo si no); si no,
     * se queda la configurada en Experience Builder.
     */
    @wire(CurrentPageReference)
    leerCampanaDeLaDireccion(ref) {
        const id = ref && ref.state && ref.state.campana ? ref.state.campana : undefined;
        if (!id || id === this._campanaUrl) {
            return;
        }
        this._campanaUrl = id;
        obtenerCampana({ campaignId: id })
            .then((c) => {
                if (c && this._campanaUrl === id) {
                    this.usarCampana(c.id);
                    this.nombreCampana = c.nombre;
                }
            })
            .catch(() => {
                // Si falla, se queda la campaña configurada.
            });
    }

    usarCampana(valor) {
        const id = typeof valor === 'string' ? valor.trim() : valor;
        if (id && id === this.campanaEfectiva) {
            return;
        }
        this.campanaEfectiva = id;
        this.nombreCampana = undefined;
        if (id) {
            obtenerCampana({ campaignId: id })
                .then((c) => {
                    if (c && this.campanaEfectiva === id) {
                        this.nombreCampana = c.nombre;
                    }
                })
                .catch(() => {
                    this.nombreCampana = undefined;
                });
        }
        this.limpiarTiempoLimite();
        this.muro = undefined;

        if (!this.campanaEfectiva) {
            this.isLoading = false;
            this.errorCarga = SIN_CAMPANA;
            return;
        }

        this.errorCarga = undefined;
        this.isLoading = true;
        this._loadTimeout = setTimeout(() => {
            if (this.isLoading) {
                this.isLoading = false;
                this.errorCarga =
                    'Salesforce no respondió a tiempo. En Live Preview, verifica la conexión con la org; ' +
                    'también puedes probar el componente en una página del sandbox.';
                console.error('Tiempo de espera agotado al cargar el muro.', {
                    campaignId: this.campanaEfectiva,
                    timeoutMs: TIEMPO_LIMITE_CARGA_MS
                });
            }
        }, TIEMPO_LIMITE_CARGA_MS);
    }

    @wire(obtenerAvance, { campaignId: '$campanaEfectiva' })
    recibirAvance(valor) {
        this.avance = valor;
        if (valor.error) {
            this.errorAvance = 'No se pudo cargar el avance de la campaña.';
            console.error('Error de obtenerAvance en MesaRegalosController.', valor.error);
        } else if (valor.data !== undefined) {
            this.errorAvance = undefined;
        }
    }

    @wire(obtenerMuro, { campaignId: '$campanaEfectiva' })
    recibirMuro(valor) {
        this.muro = valor;
        if (valor.data !== undefined) {
            this.limpiarTiempoLimite();
            this.isLoading = false;
            this.errorCarga = undefined;
            this._needsScrollSetup = true;
        } else if (valor.error) {
            this.limpiarTiempoLimite();
            this.isLoading = false;
            this.errorCarga = 'No pudimos cargar los agradecimientos. Intenta de nuevo más tarde.';
            console.error('Error de obtenerMuro en MesaRegalosController.', valor.error);
        }
    }

    // ---------- Avance de la meta ----------

    get mostrarAvanceActivo() {
        return this.mostrarAvance !== false;
    }

    get mostrarPanelAvance() {
        return this.mostrarAvanceActivo && !!(this.avance && this.avance.data);
    }

    get metaObjetivo() {
        const meta = Number(this.metaCampana);
        return Number.isFinite(meta) && meta > 0 ? meta : 0;
    }

    get hayMeta() {
        return this.mostrarPanelAvance && this.metaObjetivo > 0;
    }

    get metaSinConfigurar() {
        return this.mostrarPanelAvance && this.metaObjetivo === 0;
    }

    get totalRecaudado() {
        const total = this.avance && this.avance.data ? Number(this.avance.data.total) : 0;
        return Number.isFinite(total) && total > 0 ? total : 0;
    }

    get porcentaje() {
        if (this.metaObjetivo === 0) {
            return 0;
        }
        return Math.min(Math.round((this.totalRecaudado / this.metaObjetivo) * 100), 100);
    }

    get totalFormateado() {
        return formatearMonto(this.totalRecaudado);
    }

    get metaFormateada() {
        return formatearMonto(this.metaObjetivo);
    }

    // ---------- Donantes ----------

    /** Datos del muro solo cuando ya cargaron sin error; antes de eso no se muestra nada. */
    get datosMuro() {
        return !this.isLoading && !this.errorCarga && this.muro ? this.muro.data : undefined;
    }

    get donantes() {
        return this.datosMuro && Array.isArray(this.datosMuro.donantes) ? this.datosMuro.donantes : [];
    }

    get totalAnonimo() {
        const total = this.datosMuro ? Number(this.datosMuro.totalAnonimo) : 0;
        return Number.isFinite(total) && total > 0 ? total : 0;
    }

    get items() {
        return [...this.donantes]
            .sort((a, b) => compararDonantes(a, b, this.orden))
            .map((donante, index) => ({
                clave: `${index}-${donante.nombre}-${donante.fecha || ''}`,
                nombre: donante.nombre,
                monto: formatearMonto(donante.monto || 0)
            }));
    }

    get podio() {
        const primeros = [...this.donantes]
            .sort((a, b) => compararDonantes(a, b, 'monto'))
            .slice(0, TAMANO_PODIO);
        // En pantalla el primer lugar va al centro: 2.º, 1.º, 3.º.
        const ordenPodio = primeros.length === TAMANO_PODIO
            ? [primeros[1], primeros[0], primeros[2]]
            : primeros;
        return ordenPodio.map((donante) => {
            const posicion = primeros.indexOf(donante) + 1;
            return {
                clave: `${posicion}-${donante.nombre}-${donante.fecha || ''}`,
                nombre: donante.nombre,
                inicial: iniciales(donante.nombre),
                posicion,
                posicionLabel: `Lugar ${posicion}`,
                clase: `podio-item podio-item-${posicion}`,
                monto: formatearMonto(donante.monto || 0)
            };
        });
    }

    get hayDatos() {
        return this.donantes.length > 0;
    }

    get hayTotalAnonimo() {
        return this.totalAnonimo > 0;
    }

    get sinItems() {
        return !!this.datosMuro && !this.hayDatos && !this.hayTotalAnonimo;
    }

    // ---------- Ciclo de vida ----------

    get etiquetaBanda() {
        return this.nombreCampana || 'Gracias';
    }

    get textoGracias() {
        if (this.pagoConfirmado) {
            return this.nombreCampana
                ? `Tu pago se confirmó. Tu aportación a ${this.nombreCampana} ya aparece en el muro, como la elegiste.`
                : 'Tu pago se confirmó. Tu aportación ya aparece en el muro, como la elegiste.';
        }
        return this.nombreCampana
            ? `Confirmando tu pago. Tu aportación a ${this.nombreCampana} aparecerá en el muro en cuanto se confirme, como la elegiste.`
            : 'Confirmando tu pago. En cuanto se confirme, tu aportación aparecerá en el muro como la elegiste.';
    }

    connectedCallback() {
        // La marca la deja mesaRegistro al abrir la pasarela: es el Id del donativo que se está pagando.
        this._donativoRetorno = leerRetornoPago();
        this.mostrarGracias = !!this._donativoRetorno;
        if (this.mostrarGracias) {
            this.consultarPago(1);
        }
    }

    /** CA7: el aviso dice el estado real (lo marca el webhook de Stripe), no la dirección de regreso. */
    consultarPago(intento) {
        estadoPago({ donativoId: this._donativoRetorno })
            .then((estado) => {
                if (estado === 'pagado') {
                    this.pagoConfirmado = true;
                    if (this.muro) {
                        refreshApex(this.muro);
                    }
                    if (this.avance) {
                        refreshApex(this.avance);
                    }
                } else if (estado === 'pendiente' && intento < INTENTOS_ESTADO_PAGO) {
                    this._estadoTimeout = setTimeout(() => this.consultarPago(intento + 1), ESPERA_ESTADO_PAGO_MS);
                } else if (!estado) {
                    this.mostrarGracias = false;
                }
            })
            .catch(() => {
                // Si falla la consulta se queda "Confirmando tu pago", que nunca afirma un pago.
            });
    }

    renderedCallback() {
        if (!this._needsScrollSetup || !this.hayDatos) {
            return;
        }
        this._needsScrollSetup = false;
        this.configurarDesplazamiento();
    }

    disconnectedCallback() {
        clearTimeout(this._estadoTimeout);
        this.limpiarTiempoLimite();
        this.detenerDesplazamiento();
        this.limpiarReanudacionDesplazamiento();
        this.desconectarObservadorTamano();
    }

    limpiarTiempoLimite() {
        if (this._loadTimeout !== undefined) {
            clearTimeout(this._loadTimeout);
            this._loadTimeout = undefined;
        }
    }

    // ---------- Orden y desplazamiento automático ----------

    cambiarOrden(event) {
        this.orden = event.detail.value;
        const contenedor = this.template.querySelector('.lista-ventana');
        this.detenerDesplazamiento();
        if (contenedor) {
            contenedor.scrollTop = 0;
        }
        this._scrollPaused = false;
        this.limpiarReanudacionDesplazamiento();
        this._needsScrollSetup = true;
    }

    pausarPorInteraccion() {
        this._scrollPaused = true;
        this.detenerDesplazamiento();
        this.limpiarReanudacionDesplazamiento();
        this._scrollResumeTimeout = setTimeout(() => {
            this._scrollResumeTimeout = null;
            this._scrollPaused = false;
            this.iniciarDesplazamiento();
        }, PAUSA_POR_INTERACCION_MS);
    }

    configurarDesplazamiento() {
        const contenedor = this.template.querySelector('.lista-ventana');
        if (!contenedor) {
            return;
        }
        this.desconectarObservadorTamano();
        this._scrollContainer = contenedor;
        if (typeof ResizeObserver === 'function') {
            this._resizeObserver = new ResizeObserver(() => this.iniciarDesplazamiento());
            this._resizeObserver.observe(contenedor);
        } else {
            this._resizeHandler = () => this.iniciarDesplazamiento();
            window.addEventListener('resize', this._resizeHandler);
        }
        this.iniciarDesplazamiento();
    }

    desconectarObservadorTamano() {
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
        if (this._resizeHandler) {
            window.removeEventListener('resize', this._resizeHandler);
            this._resizeHandler = null;
        }
    }

    /** Verdadero si el contenedor ya llegó al final o no tiene nada que desplazar. */
    llegoAlFinal(contenedor) {
        return contenedor.scrollTop + contenedor.clientHeight >= contenedor.scrollHeight - 1;
    }

    iniciarDesplazamiento() {
        this.detenerDesplazamiento();
        const contenedor = this._scrollContainer;
        if (this._scrollPaused || !contenedor || this.llegoAlFinal(contenedor)) {
            return;
        }
        this._scrollInterval = setInterval(() => this.desplazar(), INTERVALO_DESPLAZAMIENTO_MS);
    }

    desplazar() {
        const contenedor = this._scrollContainer;
        if (!contenedor || this.llegoAlFinal(contenedor)) {
            this.detenerDesplazamiento();
            return;
        }
        const prefiereMovimientoReducido = typeof window.matchMedia === 'function' &&
            window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        contenedor.scrollTop += prefiereMovimientoReducido ? 1 : 2;
    }

    limpiarReanudacionDesplazamiento() {
        if (this._scrollResumeTimeout != null) {
            clearTimeout(this._scrollResumeTimeout);
            this._scrollResumeTimeout = null;
        }
    }

    detenerDesplazamiento() {
        if (this._scrollInterval != null) {
            clearInterval(this._scrollInterval);
            this._scrollInterval = null;
        }
    }
}
