import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getObjectInfos } from 'lightning/uiObjectInfoApi';
import CAMPAIGN_OBJETO from '@salesforce/schema/Campaign';
import RECONOCIMIENTO_OBJETO from '@salesforce/schema/Reconocimiento_Publico__c';
import OPORTUNIDAD_OBJETO from '@salesforce/schema/Opportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import obtenerResumen from '@salesforce/apex/MesaPanelController.obtenerResumen';
import listarCampanas from '@salesforce/apex/MesaPanelController.listarCampanas';
import listarReconocimientos from '@salesforce/apex/MesaPanelController.listarReconocimientos';
import listarDonativos from '@salesforce/apex/MesaPanelController.listarDonativos';

const MXN = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });
const FECHA_HORA = new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
const FECHA = new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' });

/** Filas por página en las listas que pueden crecer mucho (muro y donativos). */
const TAM_PAGINA = 20;

function listaVacia() {
    return { cargado: false, filas: [], total: 0, haySiguiente: false, cursores: [null], indice: 0, buscar: '' };
}

const SECCIONES = [
    { clave: 'resumen', texto: 'Resumen' },
    { clave: 'campanas', texto: 'Campañas' },
    { clave: 'muro', texto: 'Moderar muro' },
    { clave: 'donativos', texto: 'Donativos' }
];

const TITULOS = {
    resumen: ['Resumen', 'Cómo van las campañas y los donativos de la mesa de regalos.'],
    campanas: ['Campañas', 'Crea, edita, pausa o reactiva las campañas que se publican en el sitio.'],
    muro: ['Moderar muro', 'Oculta del muro público un nombre que no deba verse. No se borra nada: puedes volver a mostrarlo.'],
    donativos: ['Donativos', 'Los donativos registrados y si ya fueron pagados.']
};

const FILTROS = {
    campanas: [
        { clave: 'todas', texto: 'Todas' },
        { clave: 'activas', texto: 'Activas' },
        { clave: 'pausadas', texto: 'Pausadas' },
        { clave: 'cerradas', texto: 'Cerradas' }
    ],
    muro: [
        { clave: 'todos', texto: 'Todos' },
        { clave: 'visibles', texto: 'En el muro' },
        { clave: 'ocultos', texto: 'Ocultos' }
    ],
    donativos: [
        { clave: 'todos', texto: 'Todos' },
        { clave: 'pagados', texto: 'Pagados' },
        { clave: 'pendientes', texto: 'Pendientes' }
    ]
};

function mensajeError(e) {
    const b = e && e.body;
    if (Array.isArray(b) && b.length) {
        return b[0].message;
    }
    return (b && b.message) || (e && e.message) || 'Error desconocido';
}

/**
 * Panel interno: barra lateral y cuatro secciones (Resumen, Campañas, Moderar muro, Donativos) con el
 * diseño del sitio público. Lee con MesaPanelController (with sharing, modo usuario) y escribe solo
 * con la API de registros de Salesforce (updateRecord), que respeta los permisos de cada persona.
 */
export default class MesaPanelAdmin extends NavigationMixin(LightningElement) {
    secciones = SECCIONES;
    seccion = 'resumen';
    filtros = { campanas: 'todas', muro: 'todos', donativos: 'todos' };

    resumen;
    campanasLista;
    /** Muro y donativos se leen de a una página (paginación por cursor en el servidor). */
    listas = { muro: listaVacia(), donativos: listaVacia() };
    error;
    ocupado = false;
    _peticion = 0;
    _temporizador;

    connectedCallback() {
        this.cargar('resumen');
    }

    // ---------- Carga ----------

    async cargar(clave) {
        this.error = undefined;
        try {
            if (clave === 'resumen') {
                this.resumen = await obtenerResumen();
            } else if (clave === 'campanas') {
                this.campanasLista = await listarCampanas();
            } else if (clave === 'muro' || clave === 'donativos') {
                await this.cargarPagina(clave);
            }
        } catch (e) {
            this.error = mensajeError(e);
        }
    }

    /** Lee la página actual de una lista paginada (con el filtro y la búsqueda vigentes). */
    async cargarPagina(clave) {
        const e = this.listas[clave];
        const cursor = e.cursores[e.indice];
        const peticion = ++this._peticion;
        const parametros = {
            filtro: this.filtros[clave],
            buscar: e.buscar || null,
            tamano: TAM_PAGINA,
            cursorFecha: cursor ? cursor.fecha : null,
            cursorId: cursor ? cursor.id : null
        };
        const r = clave === 'muro' ? await listarReconocimientos(parametros) : await listarDonativos(parametros);
        if (peticion !== this._peticion) {
            return; // llegó una respuesta más nueva (otro filtro o búsqueda)
        }
        this.listas = {
            ...this.listas,
            [clave]: { ...this.listas[clave], cargado: true, filas: r.filas, total: r.total, haySiguiente: r.haySiguiente }
        };
    }

    reiniciarLista(clave) {
        this.listas = { ...this.listas, [clave]: { ...listaVacia(), buscar: this.listas[clave].buscar } };
    }

    // ---------- Permisos: cada persona ve solo lo que puede usar ----------

    @wire(getObjectInfos, { objectApiNames: [CAMPAIGN_OBJETO, RECONOCIMIENTO_OBJETO, OPORTUNIDAD_OBJETO] })
    infos;

    permisos(objeto) {
        const lista = (this.infos && this.infos.data && this.infos.data.results) || [];
        const r = lista.find((x) => x.result && x.result.apiName === objeto.objectApiName);
        return r ? r.result : undefined;
    }

    puede(objeto, accion) {
        if (this.infos && this.infos.error) {
            return true; // si no se pueden leer los permisos no se esconde nada: el servidor igual los aplica
        }
        const info = this.permisos(objeto);
        return !!info && !!info[accion];
    }

    get verCampanas() {
        return this.puede(CAMPAIGN_OBJETO, 'queryable');
    }
    get verMuro() {
        return this.puede(RECONOCIMIENTO_OBJETO, 'queryable');
    }
    get verDonativos() {
        return this.puede(OPORTUNIDAD_OBJETO, 'queryable');
    }
    get puedeCrearCampana() {
        return this.puede(CAMPAIGN_OBJETO, 'createable');
    }
    get puedeEditarCampana() {
        return this.puede(CAMPAIGN_OBJETO, 'updateable');
    }
    get puedeEditarMuro() {
        return this.puede(RECONOCIMIENTO_OBJETO, 'updateable');
    }
    /** Mientras no se sepan los permisos no se muestra nada de más. */
    get sinPermisosSeccion() {
        const necesita = { campanas: this.verCampanas, muro: this.verMuro, donativos: this.verDonativos };
        return this.seccion in necesita && !!this.infos && !!this.infos.data && !necesita[this.seccion];
    }

    get menu() {
        const visibles = { resumen: true, campanas: this.verCampanas, muro: this.verMuro, donativos: this.verDonativos };
        return this.secciones.filter((s) => visibles[s.clave]).map((s) => ({
            ...s,
            clase: s.clave === this.seccion ? 'menu-item menu-activo' : 'menu-item',
            actual: s.clave === this.seccion ? 'page' : 'false'
        }));
    }

    irASeccion(evento) {
        this.seccion = evento.currentTarget.dataset.clave;
        if (this.seccion === 'muro' || this.seccion === 'donativos') {
            this.reiniciarLista(this.seccion);
        }
        this.cargar(this.seccion);
    }

    get titulo() {
        return TITULOS[this.seccion][0];
    }

    get subtitulo() {
        return TITULOS[this.seccion][1];
    }

    get esResumen() {
        return this.seccion === 'resumen';
    }
    get mostrarNueva() {
        return this.seccion === 'campanas' && this.puedeCrearCampana;
    }
    get esCampanas() {
        return this.seccion === 'campanas';
    }
    get esMuro() {
        return this.seccion === 'muro';
    }
    get esDonativos() {
        return this.seccion === 'donativos';
    }

    get cargando() {
        if (this.error) {
            return false;
        }
        if (this.paginada) {
            return !this.listas[this.seccion].cargado;
        }
        return !(this.seccion === 'resumen' ? this.resumen : this.campanasLista);
    }

    get hayError() {
        return !!this.error;
    }

    get urlSitio() {
        return 'https://uady--class2026e.sandbox.my.site.com/mesaregalos/s/';
    }

    // ---------- Filtros ----------

    get chips() {
        const actual = this.filtros[this.seccion];
        return (FILTROS[this.seccion] || []).map((f) => ({
            ...f,
            clase: f.clave === actual ? 'chip chip-activo' : 'chip',
            pulsado: f.clave === actual ? 'true' : 'false'
        }));
    }

    get conFiltros() {
        return !!FILTROS[this.seccion];
    }

    cambiarFiltro(evento) {
        this.filtros = { ...this.filtros, [this.seccion]: evento.currentTarget.dataset.clave };
        if (this.paginada) {
            this.reiniciarLista(this.seccion);
            this.cargar(this.seccion);
        }
    }

    // ---------- Páginas y búsqueda (muro y donativos) ----------

    get paginada() {
        return this.seccion === 'muro' || this.seccion === 'donativos';
    }

    get lista() {
        return this.listas[this.seccion];
    }

    get totalPaginas() {
        return Math.max(1, Math.ceil(this.lista.total / TAM_PAGINA));
    }

    get textoPagina() {
        return `Página ${this.lista.indice + 1} de ${this.totalPaginas}`;
    }

    get textoTotal() {
        const n = this.lista.total;
        const nombre = this.seccion === 'muro' ? 'reconocimiento' : 'donativo';
        return `${new Intl.NumberFormat('es-MX').format(n)} ${nombre}${n === 1 ? '' : 's'}`;
    }

    get sinAnterior() {
        return this.lista.indice === 0 || this.ocupado;
    }

    get sinSiguiente() {
        return !this.lista.haySiguiente || this.ocupado;
    }

    get marcadorBusqueda() {
        return this.seccion === 'muro' ? 'Buscar por nombre…' : 'Buscar donativo…';
    }

    escribirBusqueda(evento) {
        const texto = evento.target.value;
        const clave = this.seccion;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        clearTimeout(this._temporizador);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._temporizador = setTimeout(() => {
            this.listas = { ...this.listas, [clave]: { ...listaVacia(), buscar: texto.trim() } };
            this.cargar(clave);
        }, 350);
    }

    async irAPagina(evento) {
        const delta = Number(evento.currentTarget.dataset.delta);
        const clave = this.seccion;
        const e = this.listas[clave];
        const cursores = e.cursores.slice();
        if (delta > 0) {
            const ultima = e.filas[e.filas.length - 1];
            cursores[e.indice + 1] = { fecha: ultima.creado, id: ultima.id };
        }
        this.listas = { ...this.listas, [clave]: { ...e, cursores, indice: e.indice + delta } };
        this.ocupado = true;
        try {
            await this.cargarPagina(clave);
        } catch (err) {
            this.error = mensajeError(err);
        } finally {
            this.ocupado = false;
        }
    }

    // ---------- Resumen ----------

    get totalTexto() {
        return MXN.format(this.resumen.totalRecaudado || 0);
    }

    get donativosTexto() {
        const n = this.resumen.donativosPagados || 0;
        return n === 1 ? '1 donativo pagado' : `${n} donativos pagados`;
    }

    get resumenCampanas() {
        return this.resumen.campanas.map((c) => this.armarAvance(c));
    }

    get resumenRecientes() {
        return this.resumen.recientes.map((r) => this.armarReconocimiento(r));
    }

    get sinRecientes() {
        return this.resumen.recientes.length === 0;
    }

    armarAvance(c) {
        return {
            id: c.id,
            nombre: c.nombre,
            totalTexto: MXN.format(c.total || 0),
            metaTexto: c.meta > 0 ? `de ${MXN.format(c.meta)}` : 'Sin meta',
            conMeta: c.meta > 0,
            porcentaje: c.porcentaje,
            estiloBarra: `width: ${c.porcentaje}%`,
            estado: c.activa ? 'Activa' : 'Cerrada',
            claseEstado: c.activa ? 'etiqueta etiqueta-ok' : 'etiqueta'
        };
    }

    armarReconocimiento(r) {
        return {
            id: r.id,
            nombre: r.nombre,
            detalle: [r.campana || 'Sin campaña', r.fecha ? FECHA_HORA.format(new Date(r.fecha)) : ''].filter(Boolean).join(' · '),
            montoTexto: r.monto == null ? '—' : MXN.format(r.monto),
            visible: r.visible,
            visibleTexto: r.visible ? 'En el muro' : 'Oculto',
            claseVisible: r.visible ? 'etiqueta etiqueta-ok' : 'etiqueta etiqueta-gris',
            textoAccion: r.visible ? 'Ocultar' : 'Mostrar'
        };
    }

    // ---------- Campañas ----------

    estadoCampana(c) {
        if (c.cerrada) {
            return { texto: 'Cerrada', clave: 'cerradas', clase: 'etiqueta etiqueta-gris' };
        }
        if (!c.activa) {
            return { texto: 'Pausada', clave: 'pausadas', clase: 'etiqueta etiqueta-aviso' };
        }
        return { texto: 'Activa', clave: 'activas', clase: 'etiqueta etiqueta-ok' };
    }

    get campanas() {
        const filtro = this.filtros.campanas;
        return (this.campanasLista || [])
            .map((c) => {
                const e = this.estadoCampana(c);
                const pct = c.meta > 0 ? Math.min(100, Math.round((c.total * 100) / c.meta)) : 0;
                const fechas = [c.fechaInicio, c.fechaFin].map((f) => (f ? FECHA.format(new Date(`${f}T00:00:00`)) : '—'));
                return {
                    id: c.id,
                    nombre: c.nombre,
                    estado: e.texto,
                    claveEstado: e.clave,
                    claseEstado: e.clase,
                    totalTexto: MXN.format(c.total || 0),
                    metaTexto: c.meta > 0 ? `de ${MXN.format(c.meta)}` : 'Sin meta',
                    conMeta: c.meta > 0,
                    estiloBarra: `width: ${pct}%`,
                    porcentaje: pct,
                    donativosTexto: c.donativos === 1 ? '1 donativo' : `${c.donativos} donativos`,
                    periodo: `${fechas[0]} → ${fechas[1]}`,
                    textoPausa: c.activa ? 'Pausar' : 'Reactivar',
                    activa: c.activa
                };
            })
            .filter((c) => filtro === 'todas' || c.claveEstado === filtro);
    }

    get sinCampanas() {
        return this.campanasLista && this.campanas.length === 0;
    }

    /** Tipos de registro de Campaign disponibles para la persona (para elegir «Campaña de donación»). */
    @wire(getObjectInfo, { objectApiName: CAMPAIGN_OBJETO })
    infoCampana;

    /**
     * Abre el formulario de nueva campaña ya con el tipo «Campaña de donación», que es el que lleva los campos
     * del sitio (resumen, organiza, imagen…). Si ese tipo no existe en la org, abre el formulario normal.
     */
    nuevaCampana() {
        const tipos = (this.infoCampana && this.infoCampana.data && this.infoCampana.data.recordTypeInfos) || {};
        const donacion = Object.values(tipos).find((t) => t.available && !t.master && /donaci/i.test(t.name));
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Campaign', actionName: 'new' },
            state: donacion ? { recordTypeId: donacion.recordTypeId } : {}
        });
    }

    editarRegistro(evento) {
        const { id, objeto } = evento.currentTarget.dataset;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, objectApiName: objeto, actionName: 'edit' }
        });
    }

    verRegistro(evento) {
        const { id, objeto } = evento.currentTarget.dataset;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: id, objectApiName: objeto, actionName: 'view' }
        });
    }

    async alternarCampana(evento) {
        const id = evento.currentTarget.dataset.id;
        const activa = evento.currentTarget.dataset.activa === 'true';
        await this.guardar({ Id: id, IsActive: !activa }, activa ? 'Campaña pausada: ya no se publica en el sitio.' : 'Campaña reactivada.', 'campanas');
    }

    // ---------- Muro ----------

    get reconocimientos() {
        return this.listas.muro.filas.map((r) => this.armarReconocimiento(r));
    }

    get sinReconocimientos() {
        return this.listas.muro.cargado && this.listas.muro.filas.length === 0;
    }

    async alternarMuro(evento) {
        const id = evento.currentTarget.dataset.id;
        const visible = evento.currentTarget.dataset.visible === 'true';
        await this.guardar(
            { Id: id, Mostrar_En_Muro__c: !visible },
            visible ? 'Reconocimiento oculto del muro.' : 'Reconocimiento visible en el muro.',
            'muro'
        );
    }

    // ---------- Donativos ----------

    get donativos() {
        return this.listas.donativos.filas
            .map((d) => ({
                id: d.id,
                nombre: d.nombre,
                detalle: [d.campana, d.fecha ? FECHA.format(new Date(`${d.fecha}T00:00:00`)) : ''].filter(Boolean).join(' · '),
                montoTexto: d.monto == null ? '—' : MXN.format(d.monto),
                pagado: d.pagado,
                etapa: d.pagado ? 'Pagado' : d.etapa,
                claseEtapa: d.pagado ? 'etiqueta etiqueta-ok' : 'etiqueta etiqueta-aviso'
            }));
    }

    get sinDonativos() {
        return this.listas.donativos.cargado && this.listas.donativos.filas.length === 0;
    }

    // ---------- Escritura (respeta los permisos de la persona) ----------

    async guardar(campos, mensaje, recargar) {
        this.ocupado = true;
        try {
            await updateRecord({ fields: campos });
            this.dispatchEvent(new ShowToastEvent({ title: 'Listo', message: mensaje, variant: 'success' }));
            await Promise.all([this.cargar(recargar), this.cargar('resumen')]);
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({ title: 'No se pudo guardar', message: mensajeError(e), variant: 'error' }));
        } finally {
            this.ocupado = false;
        }
    }
}
