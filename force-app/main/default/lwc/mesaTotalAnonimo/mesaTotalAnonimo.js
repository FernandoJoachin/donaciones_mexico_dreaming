import { LightningElement, api } from 'lwc';
import { formatearMonto } from 'c/mesaUtil';

const FORMATO_PORCENTAJE = new Intl.NumberFormat('es-MX', { style: 'percent', maximumFractionDigits: 1 });
const PROPORCION_MINIMA_VISIBLE = 0.001;

/**
 * Tarjeta con la suma de las donaciones anónimas de una campaña. Solo recibe montos agregados:
 * nunca nombres, conteos ni montos individuales. El componente que la usa decide si se muestra.
 */
export default class MesaTotalAnonimo extends LightningElement {
    /** Suma de las donaciones anónimas pagadas. */
    @api monto;
    /** Total recaudado de la campaña; si no se conoce, no se muestra el porcentaje. */
    @api totalRecaudado;

    get montoFormateado() {
        return formatearMonto(Number(this.monto) || 0);
    }

    get porcentajeTexto() {
        const monto = Number(this.monto);
        const total = Number(this.totalRecaudado);
        if (!(monto > 0) || !(total >= monto)) {
            return undefined;
        }
        const proporcion = monto / total;
        return proporcion < PROPORCION_MINIMA_VISIBLE
            ? 'Menos de 0.1% del total'
            : `${FORMATO_PORCENTAJE.format(proporcion)} del total`;
    }
}
