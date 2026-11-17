import { LightningElement, api } from 'lwc';
import { resolverUrl } from 'c/mesaUtil';

/**
 * Encabezado del sitio: marca, navegación y botón Donar. En pantallas chicas la navegación se abre
 * con un botón de menú. Los nombres siguen lo que pidió el panel: «Campañas activas» y «Campañas
 * pasadas», no un genérico «Campañas» que no dice qué lista.
 */
export default class MesaEncabezado extends LightningElement {
    @api marca = 'Mesa de regalos';
    @api lema = 'Comunidad Salesforce · Facultad de Matemáticas';
    @api paginaMuro = 'muro';
    @api paginaFacturas = 'facturas';

    menuAbierto = false;

    /** Pestaña/página donde estamos, para marcar el enlace activo. */
    get actual() {
        const ruta = window.location.pathname.replace(/\/+$/, '');
        const tramo = ruta.substring(ruta.lastIndexOf('/') + 1);
        const consulta = new URLSearchParams(window.location.search);
        if (tramo === '' || tramo === 's' || tramo === 'inicio') {
            return consulta.get('pestana') === 'pasadas' ? 'pasadas' : 'activas';
        }
        if (tramo === this.paginaMuro) {
            return 'muro';
        }
        if (tramo === this.paginaFacturas) {
            return 'facturas';
        }
        return '';
    }

    get enlaces() {
        const inicio = resolverUrl('', null, false);
        const lista = [
            { id: 'activas', texto: 'Campañas activas', url: `${inicio}?pestana=activas` },
            { id: 'pasadas', texto: 'Campañas pasadas', url: `${inicio}?pestana=pasadas` },
            { id: 'muro', texto: 'Quién ya se sumó', url: resolverUrl(this.paginaMuro, null, false) },
            { id: 'facturas', texto: 'Facturas', url: resolverUrl(this.paginaFacturas, null, false) }
        ];
        return lista.map((e) => ({
            ...e,
            clase: e.id === this.actual ? 'enlace activo' : 'enlace',
            actual: e.id === this.actual ? 'page' : null
        }));
    }

    get urlInicio() {
        return resolverUrl('', null, false);
    }

    /** «Donar» lleva a elegir campaña: la persona primero decide a cuál. */
    get urlDonar() {
        return `${resolverUrl('', null, false)}?pestana=activas`;
    }

    get claseMenu() {
        return this.menuAbierto ? 'menu menu-abierto' : 'menu';
    }

    get etiquetaBoton() {
        return this.menuAbierto ? 'Cerrar menú' : 'Abrir menú';
    }

    get expandido() {
        return this.menuAbierto ? 'true' : 'false';
    }

    alternarMenu() {
        this.menuAbierto = !this.menuAbierto;
    }

    teclaMenu(evento) {
        if (evento.key === 'Escape' && this.menuAbierto) {
            this.menuAbierto = false;
        }
    }

    /** La ventana de ayuda vive en el pie; se le avisa por un evento de la ventana. */
    abrirAyuda() {
        this.menuAbierto = false;
        window.dispatchEvent(new CustomEvent('mesa:abrir-ayuda'));
    }
}
