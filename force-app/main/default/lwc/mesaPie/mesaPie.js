import { LightningElement, api } from 'lwc';
import { resolverUrl } from 'c/mesaUtil';

/**
 * Pie de pagina del sitio. Todo lo que cambia de una organizacion a otra se edita en
 * Experience Builder, sin desplegar. Lo que se deja vacio no se muestra: no hay datos de
 * contacto ni redes inventados.
 */
export default class MesaPie extends LightningElement {
    @api titulo = 'Apoya a la comunidad';
    @api descripcion = 'Comunidad Salesforce de la Facultad de Matemáticas, reunida en torno a causas que importan.';
    @api universidad = 'Universidad Autónoma de Yucatán';
    @api facultad = 'Facultad de Matemáticas';

    // Paginas del mismo sitio (nombre de la pagina). Vacio = no se muestra ese enlace.
    @api paginaCampanas = '';
    @api paginaDonar = 'registro';
    @api paginaMuro = 'muro';
    @api paginaReencuentro = 'reencuentro';
    @api paginaFacturas = 'facturas';

    // Aviso de privacidad: URL o nombre de pagina. Vacio = no se muestra.
    @api paginaAviso = '';

    @api correoContacto = '';
    @api telefonoContacto = '';
    @api urlInstagram = '';
    @api urlFacebook = '';
    @api urlLinkedin = '';

    @api textoCta = 'Cada aporte cuenta. Elige una campaña y sé parte.';
    @api textoBotonCta = 'Quiero donar';

    @api textoLegal = 'Facultad de Matemáticas, UADY.';

    ayudaAbierta = false;

    // El encabezado pide abrir la ayuda con un evento de la ventana (están en componentes distintos).
    _alAbrirAyuda = () => {
        this.ayudaAbierta = true;
    };

    connectedCallback() {
        window.addEventListener('mesa:abrir-ayuda', this._alAbrirAyuda);
    }

    disconnectedCallback() {
        window.removeEventListener('mesa:abrir-ayuda', this._alAbrirAyuda);
    }

    abrirAyuda() {
        this.ayudaAbierta = true;
    }

    cerrarAyuda() {
        this.ayudaAbierta = false;
    }

    /** Un clic dentro de la caja no debe cerrar el fondo. */
    detener(evento) {
        evento.stopPropagation();
    }

    teclaAyuda(evento) {
        if (evento.key === 'Escape') {
            this.cerrarAyuda();
        }
    }

    get anio() {
        return new Date().getFullYear();
    }

    get enlaces() {
        const lista = [
            { id: 'inicio', texto: 'Inicio', url: resolverUrl('', null, false) },
            { id: 'campanas', texto: 'Campañas', pagina: this.paginaCampanas },
            { id: 'donar', texto: 'Donar', url: this.urlDonar },
            { id: 'muro', texto: 'Quién ya se sumó', pagina: this.paginaMuro },
            { id: 'reencuentro', texto: 'Reencuentro', pagina: this.paginaReencuentro },
            { id: 'facturas', texto: 'Facturas', pagina: this.paginaFacturas }
        ];
        // El muro es de cada campaña: el enlace solo aparece dentro de una campaña y lleva al muro de esa campaña.
        const idCampana = new URLSearchParams(window.location.search).get('campana');
        const campanaValida = idCampana && /^[A-Za-z0-9]{15}([A-Za-z0-9]{3})?$/.test(idCampana);
        return lista
            .filter((e) => e.id !== 'muro' || (campanaValida && this.paginaMuro))
            .map((e) => {
                if (e.id === 'muro') {
                    return {
                        ...e,
                        texto: 'Muro de esta campaña',
                        url: `${resolverUrl(this.paginaMuro, null, false)}?campana=${encodeURIComponent(idCampana)}`
                    };
                }
                return e.pagina !== undefined ? { ...e, url: e.pagina ? resolverUrl(e.pagina, null, false) : null } : e;
            })
            .filter((e) => e.url);
    }

    get urlDonar() {
        // Donar lleva a la lista de campañas activas (la persona elige cuál), no a la primera campaña.
        return this.paginaDonar ? `${resolverUrl('', null, false)}?pestana=activas` : null;
    }

    get urlAviso() {
        return this.paginaAviso ? resolverUrl(this.paginaAviso, null, false) : null;
    }

    get hayContacto() {
        return Boolean(this.correoContacto || this.telefonoContacto);
    }

    get hrefCorreo() {
        return this.correoContacto ? `mailto:${this.correoContacto}` : null;
    }

    get hrefTelefono() {
        return this.telefonoContacto ? `tel:${this.telefonoContacto.replace(/[^\d+]/g, '')}` : null;
    }

    // Solo https: una propiedad mal escrita en el Builder no puede inyectar otro esquema.
    get redes() {
        return [
            { id: 'instagram', texto: 'Instagram', url: this.urlInstagram },
            { id: 'facebook', texto: 'Facebook', url: this.urlFacebook },
            { id: 'linkedin', texto: 'LinkedIn', url: this.urlLinkedin }
        ].filter((r) => r.url && /^https:\/\//i.test(r.url));
    }

    get hayRedes() {
        return this.redes.length > 0;
    }
}
