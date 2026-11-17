import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import obtenerResumen from '@salesforce/apex/MesaPanelController.obtenerResumen';
import listarCampanas from '@salesforce/apex/MesaPanelController.listarCampanas';
import listarReconocimientos from '@salesforce/apex/MesaPanelController.listarReconocimientos';
import listarDonativos from '@salesforce/apex/MesaPanelController.listarDonativos';

const MXN = new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' });
const FECHA_HORA = new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
const FECHA = new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' });

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
    muroLista;
    donativosLista;
    error;
    ocupado = false;

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
            } else if (clave === 'muro') {
                this.muroLista = await listarReconocimientos();
            } else if (clave === 'donativos') {
                this.donativosLista = await listarDonativos();
            }
        } catch (e) {
            this.error = mensajeError(e);
        }
    }

    get menu() {
        return this.secciones.map((s) => ({
            ...s,
            clase: s.clave === this.seccion ? 'menu-item menu-activo' : 'menu-item',
            actual: s.clave === this.seccion ? 'page' : 'false'
        }));
    }

    irASeccion(evento) {
        this.seccion = evento.currentTarget.dataset.clave;
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
        const datos = { resumen: this.resumen, campanas: this.campanasLista, muro: this.muroLista, donativos: this.donativosLista };
        return !this.error && !datos[this.seccion];
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

    nuevaCampana() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Campaign', actionName: 'new' }
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
        const filtro = this.filtros.muro;
        return (this.muroLista || [])
            .map((r) => this.armarReconocimiento(r))
            .filter((r) => filtro === 'todos' || (filtro === 'visibles' ? r.visible : !r.visible));
    }

    get sinReconocimientos() {
        return this.muroLista && this.reconocimientos.length === 0;
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
        const filtro = this.filtros.donativos;
        return (this.donativosLista || [])
            .map((d) => ({
                id: d.id,
                nombre: d.nombre,
                detalle: [d.campana, d.fecha ? FECHA.format(new Date(`${d.fecha}T00:00:00`)) : ''].filter(Boolean).join(' · '),
                montoTexto: d.monto == null ? '—' : MXN.format(d.monto),
                pagado: d.pagado,
                etapa: d.pagado ? 'Pagado' : d.etapa,
                claseEtapa: d.pagado ? 'etiqueta etiqueta-ok' : 'etiqueta etiqueta-aviso'
            }))
            .filter((d) => filtro === 'todos' || (filtro === 'pagados' ? d.pagado : !d.pagado));
    }

    get sinDonativos() {
        return this.donativosLista && this.donativos.length === 0;
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
