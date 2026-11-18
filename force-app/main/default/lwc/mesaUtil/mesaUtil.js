/**
 * Utilidades compartidas por los componentes del sitio. No es un componente visual:
 * se importa con  import { ... } from 'c/mesaUtil';
 */

/**
 * Convierte lo que escribió la persona en un número.
 * Acepta "1500", "1,500", "1 500", "$1,500.50" y "1.500" (punto como separador de miles).
 * Si hay un separador seguido de 1 o 2 dígitos al final, se toma como decimal.
 * Devuelve null si no hay un número utilizable.
 *
 * Existe porque el campo de monto llegaba con formato ("1,500") y Number("1,500") es NaN.
 */
export function parseMonto(texto) {
    if (typeof texto === 'number') {
        return Number.isFinite(texto) ? texto : null;
    }
    if (texto === null || texto === undefined) {
        return null;
    }
    const limpio = String(texto).replace(/[^\d.,]/g, '');
    if (!/\d/.test(limpio)) {
        return null;
    }
    const decimal = limpio.match(/[.,](\d{1,2})$/);
    let entero = limpio;
    let decimales = '';
    if (decimal) {
        entero = limpio.slice(0, limpio.length - decimal[0].length);
        decimales = decimal[1];
    }
    entero = entero.replace(/[.,]/g, '');
    const numero = Number(decimales ? `${entero}.${decimales}` : entero);
    return Number.isFinite(numero) ? numero : null;
}

export function formatearMonto(numero) {
    return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(numero);
}

/**
 * Arma la dirección de otra página del mismo sitio, con o sin token.
 *  - destino: nombre de la página ("donar") o una ruta/URL completa ("/mi-sitio/donar", "https://...").
 *  - desdeInicio: verdadero si el componente está en la página de inicio del sitio.
 *    En cualquier otra página, la hermana se arma reemplazando el último tramo de la ruta,
 *    lo que respeta el prefijo del sitio ("/prefijo/registro" -> "/prefijo/donar").
 */
export function resolverUrl(destino, token, desdeInicio) {
    const consulta = token ? `?token=${encodeURIComponent(token)}` : '';
    if (/^(https?:)?\//.test(destino)) {
        return destino + consulta;
    }
    const ruta = window.location.pathname;
    const base = desdeInicio
        ? (ruta.endsWith('/') ? ruta : `${ruta}/`)
        : ruta.substring(0, ruta.lastIndexOf('/') + 1);
    return base + destino + consulta;
}

const CLAVE_RETORNO_PAGO = 'mesaRetornoPago';

/** Marca que la persona sale a pagar (se guarda el Id del donativo). Si el navegador bloquea el almacenamiento, simplemente no se marca. */
export function guardarRetornoPago(estado) {
    try {
        window.sessionStorage.setItem(CLAVE_RETORNO_PAGO, estado);
    } catch (e) {
        // sin almacenamiento: el muro no mostrará el mensaje de gracias
    }
}

/** Lee y borra la marca: el mensaje de gracias sale una sola vez y solo si se venía del flujo de pago. */
export function leerRetornoPago() {
    try {
        const estado = window.sessionStorage.getItem(CLAVE_RETORNO_PAGO);
        window.sessionStorage.removeItem(CLAVE_RETORNO_PAGO);
        return estado || undefined;
    } catch (e) {
        return undefined;
    }
}

export function irA(url) {
    window.location.assign(url);
}

export function mensajeError(e) {
    return (e && e.body && e.body.message) || 'Ocurrió un error. Intenta de nuevo en unos minutos.';
}

/** Verdadero si la página actual es el inicio del sitio (donde vive la lista de campañas). */
export function esPaginaInicio() {
    const ruta = window.location.pathname.replace(/\/+$/, '');
    const tramo = ruta.substring(ruta.lastIndexOf('/') + 1);
    return tramo === '' || tramo === 's' || tramo === 'inicio';
}

/**
 * Los enlaces «Donar» / «Campañas» (encabezado y pie) llaman a esto con el evento del clic. Si ya estamos
 * en el inicio, la lista de campañas baja sola, sin recargar la página. Si no hay quien escuche el aviso
 * (o estamos en otra página), no se hace nada y el enlace navega como siempre.
 * Devuelve verdadero si el desplazamiento se hizo aquí.
 */
export function bajarALista(evento) {
    const enlace = evento.currentTarget;
    const pestana = enlace && enlace.dataset ? enlace.dataset.lista : undefined;
    if (!pestana || !esPaginaInicio()) {
        return false;
    }
    const aviso = new CustomEvent('mesa:ir-a-campanas', { detail: { pestana, manejado: false } });
    window.dispatchEvent(aviso);
    if (aviso.detail.manejado) {
        evento.preventDefault();
        return true;
    }
    return false;
}

const NOMBRE_SITIO = 'Mesa de regalos · México Dreamin';

/** Ícono de la pestaña: la nube de la marca sobre el azul del sitio (SVG incrustado, sin archivos aparte). */
const ICONO_SVG =
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>" +
    "<defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='#032d60'/><stop offset='1' stop-color='#0176d3'/></linearGradient></defs>" +
    "<rect width='64' height='64' rx='16' fill='url(#g)'/>" +
    "<path transform='translate(32 32) scale(.72) translate(-33 -27)' d='M19.2 47a11.5 11.5 0 0 1-1.75-22.9A15 15 0 0 1 46.5 21.5a13 13 0 0 1-1.5 25.5z' fill='#fff'/></svg>";

/** Pone el ícono de la marca en la pestaña del navegador (quita el genérico). */
export function ponerIcono() {
    try {
        const href = `data:image/svg+xml,${encodeURIComponent(ICONO_SVG)}`;
        document.querySelectorAll('link[rel~="icon"], link[rel="shortcut icon"]').forEach((l) => l.remove());
        const link = document.createElement('link');
        link.rel = 'icon';
        link.type = 'image/svg+xml';
        link.href = href;
        document.head.appendChild(link);
    } catch (e) {
        // Sin acceso al documento (por ejemplo, en una vista previa): no pasa nada, solo no hay ícono propio.
    }
}

/**
 * Título de la pestaña: «Parte · Mesa de regalos» (o el nombre del sitio si no hay parte). La plataforma pone
 * su propio título al cambiar de página, así que se vuelve a poner si lo cambia en los primeros segundos.
 */
export function ponerTitulo(parte) {
    const titulo = parte ? `${parte} · Mesa de regalos` : NOMBRE_SITIO;
    try {
        document.title = titulo;
        const nodo = document.querySelector('title');
        if (nodo && typeof MutationObserver !== 'undefined') {
            const vigilante = new MutationObserver(() => {
                if (document.title !== titulo) {
                    document.title = titulo;
                }
            });
            vigilante.observe(nodo, { childList: true, characterData: true, subtree: true });
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => vigilante.disconnect(), 8000);
        }
    } catch (e) {
        // Sin acceso al documento: se queda el título de la plataforma.
    }
}
