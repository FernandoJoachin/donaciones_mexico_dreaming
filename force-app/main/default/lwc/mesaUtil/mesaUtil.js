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

export function irA(url) {
    window.location.assign(url);
}

export function mensajeError(e) {
    return (e && e.body && e.body.message) || 'Ocurrió un error. Intenta de nuevo en unos minutos.';
}
