import ApexCharts from 'apexcharts'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static values = {
        options: Object,
    }

    connect() {
        this.chart = new ApexCharts(this.element, this.optionsValue)
        this.chart.render()
    }

    disconnect() {
        if (this.chart) {
            this.chart.destroy()
        }
    }
}

// const formatter = function (val, opt) {
//     return opt.w.globals.labels[opt.dataPointIndex] + ':  ' + val
// }
