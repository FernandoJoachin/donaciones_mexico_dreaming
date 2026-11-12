import { LightningElement, api, wire } from 'lwc';
import obtenerMuro from '@salesforce/apex/MesaRegalosController.obtenerMuro';
import obtenerAvance from '@salesforce/apex/MesaRegalosController.obtenerAvance';
import { leerRetornoPago } from 'c/mesaUtil';

const OPCIONES_ORDEN = [
    { label: 'Mayor monto', value: 'monto' },
    { label: 'Más reciente', value: 'fecha' }
];
const INTERVALO_DESPLAZAMIENTO_MS = 80;
const PAUSA_POR_INTERACCION_MS = 3000;
const TIEMPO_LIMITE_CARGA_MS = 30000;

export default class MesaMuro extends LightningElement {
    _campaignId;
    _loadTimeout;

    @api
    get campaignId() {
        return this._campaignId;
    }

    set campaignId(value) {
        this._campaignId = typeof value === 'string' ? value.trim() : value;
        this.limpiarTiempoLimite();
        this.muro = undefined;

        if (!this._campaignId) {
            this.isLoading = false;
            this.errorCarga = 'No se configuró el Id de campaña para este componente.';
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
                    campaignId: this.campaignId,
                    timeoutMs: TIEMPO_LIMITE_CARGA_MS
                });
            }
        }, TIEMPO_LIMITE_CARGA_MS);
    }

    @api mostrarAvance;
    @api metaCampana = 50000;

    muro;
    isLoading = false;
    errorCarga = 'No se configuró el Id de campaña para este componente.';
    errorAvance;

    @wire(obtenerAvance, { campaignId: '$campaignId' })
    recibirAvance(valor) {
        this.avance = valor;
        if (valor.error) {
            this.errorAvance = 'No se pudo cargar el avance de la campaña.';
            console.error('Error de obtenerAvance en MesaRegalosController.', valor.error);
        } else if (valor.data !== undefined) {
            this.errorAvance = undefined;
        }
    }

    avance;

    @wire(obtenerMuro, { campaignId: '$campaignId' })
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

    orden = 'monto';
    opcionesOrden = OPCIONES_ORDEN;
    _needsScrollSetup = false;
    _scrollInterval;
    _scrollPaused = false;
    _resizeObserver;
    _resizeHandler;
    _scrollContainer;
    _scrollResumeTimeout;

    get hayMeta() {
        return this.mostrarAvanceActivo && this.avance && this.avance.data && this.metaObjetivo > 0;
    }

    get mostrarAvanceActivo() {
        return this.mostrarAvance !== false;
    }

    get metaObjetivo() {
        const meta = Number(this.metaCampana);
        return Number.isFinite(meta) && meta > 0 ? meta : 0;
    }

    get mostrarPanelAvance() {
        return this.mostrarAvanceActivo && this.avance && this.avance.data;
    }

    get metaSinConfigurar() {
        return this.mostrarPanelAvance && this.metaObjetivo === 0;
    }

    get porcentaje() {
        if (!this.avance || !this.avance.data || this.metaObjetivo === 0) {
            return 0;
        }
        const total = Number(this.avance.data.total);
        if (!Number.isFinite(total) || total <= 0) {
            return 0;
        }
        return Math.min(Math.round((total / this.metaObjetivo) * 100), 100);
    }

    get totalFormateado() {
        const total = this.avance && this.avance.data ? this.avance.data.total : 0;
        return this.formatearMonto(total);
    }

    get metaFormateada() {
        return this.formatearMonto(this.metaObjetivo);
    }

    get ordenados() {
        const datos = this.muro && this.muro.data ? [...this.muro.data] : [];
        return datos.sort((a, b) => {
            const diferencia = this.orden === 'fecha'
                ? (b.fecha || '').localeCompare(a.fecha || '')
                : Number(b.monto) - Number(a.monto);
            return diferencia || (b.fecha || '').localeCompare(a.fecha || '') ||
                (a.nombre || '').localeCompare(b.nombre || '', 'es-MX');
        });
    }

    get items() {
        return this.ordenados.map((donante, index) => ({
            clave: `${index}-${donante.nombre}-${donante.fecha || ''}`,
            nombre: donante.nombre,
            monto: new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(donante.monto)
        }));
    }

    get podio() {
        const primeros = [...(this.muro && this.muro.data ? this.muro.data : [])]
            .sort((a, b) => Number(b.monto) - Number(a.monto) ||
                (b.fecha || '').localeCompare(a.fecha || '') ||
                (a.nombre || '').localeCompare(b.nombre || '', 'es-MX'))
            .slice(0, 3);
        const ordenPodio = primeros.length === 3
            ? [primeros[1], primeros[0], primeros[2]]
            : primeros;
        return ordenPodio.map((donante) => {
            const posicion = primeros.indexOf(donante) + 1;
            return {
                clave: `${posicion}-${donante.nombre}-${donante.fecha || ''}`,
                nombre: donante.nombre,
                inicial: donante.nombre.split(/\s+/).map((parte) => parte[0]).slice(0, 2).join('').toUpperCase(),
                posicion,
                posicionLabel: `Lugar ${posicion}`,
                clase: `podio-item podio-item-${posicion}`,
                monto: this.formatearMonto(donante.monto)
            };
        });
    }

    get sinItems() {
        return !this.isLoading && !this.errorCarga &&
            this.muro && Array.isArray(this.muro.data) && this.muro.data.length === 0;
    }

    get hayDatos() {
        return !this.isLoading && !this.errorCarga &&
            this.muro && Array.isArray(this.muro.data) && this.muro.data.length > 0;
    }

    get hayPodio() {
        return this.podio.length > 0;
    }

    formatearMonto(monto) {
        return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(monto || 0);
    }

    /** Solo es verdadero si la persona llega desde el flujo de pago; abrir el muro directo no muestra nada (SCRUM-99). */
    mostrarGracias = false;

    connectedCallback() {
        this.mostrarGracias = leerRetornoPago() === 'exito';
    }

    renderedCallback() {
        if (!this.muro || !Array.isArray(this.muro.data) || !this._needsScrollSetup) {
            return;
        }
        this._needsScrollSetup = false;
        this.configurarDesplazamiento();
    }

    disconnectedCallback() {
        this.limpiarTiempoLimite();
        this.detenerDesplazamiento();
        this.limpiarReanudacionDesplazamiento();
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
        if (this._resizeHandler) {
            window.removeEventListener('resize', this._resizeHandler);
            this._resizeHandler = null;
        }
    }

    limpiarTiempoLimite() {
        if (this._loadTimeout !== undefined) {
            clearTimeout(this._loadTimeout);
            this._loadTimeout = undefined;
        }
    }

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
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
        if (this._resizeHandler) {
            window.removeEventListener('resize', this._resizeHandler);
            this._resizeHandler = null;
        }
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

    iniciarDesplazamiento() {
        this.detenerDesplazamiento();
        const contenedor = this._scrollContainer;
        if (this._scrollPaused || !contenedor ||
            contenedor.scrollHeight <= contenedor.clientHeight + 1) {
            return;
        }
        if (contenedor.scrollTop + contenedor.clientHeight >= contenedor.scrollHeight - 1) {
            return;
        }
        this._scrollInterval = setInterval(
            () => this.desplazar(),
            INTERVALO_DESPLAZAMIENTO_MS
        );
    }

    desplazar() {
        const contenedor = this._scrollContainer;
        if (!contenedor) {
            this.detenerDesplazamiento();
            return;
        }
        if (contenedor.scrollTop + contenedor.clientHeight >= contenedor.scrollHeight - 1) {
            this.detenerDesplazamiento();
            return;
        }
        const prefiereMovimientoReducido = typeof window.matchMedia === 'function' &&
            window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        contenedor.scrollTop += prefiereMovimientoReducido ? 1 : 2;
    }

    limpiarReanudacionDesplazamiento() {
        if (this._scrollResumeTimeout !== undefined && this._scrollResumeTimeout !== null) {
            clearTimeout(this._scrollResumeTimeout);
            this._scrollResumeTimeout = null;
        }
    }

    detenerDesplazamiento() {
        if (this._scrollInterval !== undefined && this._scrollInterval !== null) {
            clearInterval(this._scrollInterval);
            this._scrollInterval = null;
        }
    }
}
