import { Context } from '../context.js'
import { ExtractionStep, StepResult } from './abstract.js'
import { Output as Input } from './cleaner.js'
import { Ok } from 'ts-results-es'

export type Output = string

export class Report extends ExtractionStep<Input, Output, Context> {
    static STEP_NAME = 'Report'

    constructor(context: Context) {
        super(context, Report.STEP_NAME)
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        const html = generateReport(input, this.context.inputArguments.query)
        this.logger.info({ html }, 'Generated report')
        return Ok(html)
    }
}

function generateReport(data: Input, query: string) {
    let html = `
    <div class="max-w-6xl mx-auto">
        <h1 class="text-3xl font-bold text-gray-900 mb-8">Informe de Rendimiento de Marcas Asociadas a la Consulta: "${query}"</h1>

        <section class="mb-12">
            <h2 class="text-2xl font-semibold text-gray-800 mb-4">Introducción</h2>
            <p class="text-gray-600">Este informe analiza el rendimiento de diferentes marcas y modelos asociados a la consulta de usuario "<strong>${query}</strong>". El objetivo es proporcionar información útil para el equipo de marketing que necesita tomar decisiones de posicionamiento de su marca.</p>
        </section>

        <section class="mb-12">
            <h2 class="text-2xl font-semibold text-gray-800 mb-4">Marcas y Modelos Relevantes</h2>
            <div class="overflow-x-auto">
                <table class="min-w-full bg-white rounded-lg overflow-hidden shadow-sm">
                    <thead class="bg-gray-100">
                        <tr>
                            <th class="px-6 py-3 text-left text-sm font-semibold text-gray-700">Marca/Modelo</th>
                            <th class="px-6 py-3 text-left text-sm font-semibold text-gray-700">Valoración de Sentimiento (1-5)</th>
                            <th class="px-6 py-3 text-left text-sm font-semibold text-gray-700">Enlaces Web</th>
                        </tr>
                    </thead>
                    <tbody>
`

    // Sort topics by sentiment average (descending)
    const sortedTopics = [...data.brandsAndLinks.topics].sort((a, b) => {
        const avgA =
            a.sentiments.reduce((sum, val) => sum + val, 0) /
            a.sentiments.length
        const avgB =
            b.sentiments.reduce((sum, val) => sum + val, 0) /
            b.sentiments.length
        return avgB - avgA
    })

    // Procesar los temas (marcas y modelos)
    sortedTopics.forEach((topic) => {
        // Calcular la media de sentimientos
        let sentiments = topic.sentiments
        let avgSentimentNumber =
            sentiments.reduce((a, b) => a + b, 0) / sentiments.length
        let avgSentiment = avgSentimentNumber.toFixed(2)

        // Generar la lista de URLs
        let urlsList = '<ul class="space-y-1">'
        if (topic.urls.length > 0) {
            topic.urls.forEach((url) => {
                urlsList += `<li><a href="${url}" class="text-blue-600 hover:text-blue-800 hover:underline">${url}</a></li>`
            })
        } else {
            urlsList +=
                '<li class="text-gray-500">No hay enlaces disponibles.</li>'
        }
        urlsList += '</ul>'

        html += `
                        <tr class="border-b border-gray-200 hover:bg-gray-50">
                            <td class="px-6 py-4 text-gray-900">${topic.name}</td>
                            <td class="px-6 py-4 text-gray-900">${avgSentiment} (${topic.sentiments.length} muestras)</td>
                            <td class="px-6 py-4">${urlsList}</td>
                        </tr>
    `
    })

    html += `
                    </tbody>
                </table>
            </div>
        </section>

        <section class="mb-12">
            <h2 class="text-2xl font-semibold text-gray-800 mb-4">Websites Relevantes para Estrategia de Contenido</h2>
            <p class="text-gray-600 mb-4">A continuación se presenta una lista de dominios que proveen contenido relevante para la consulta y donde sería beneficioso desarrollar una estrategia de contenido para aparecer en ellos:</p>
            <ul class="space-y-2">
`

    // Procesar los dominios de URLs
    for (let domain in data.brandsAndLinks.urls) {
        html += `<li><a href="https://${domain}" class="text-blue-600 hover:text-blue-800 hover:underline">${domain}</a></li>`
    }

    html += `
            </ul>
        </section>

        <section class="mb-12">
            <h2 class="text-2xl font-semibold text-gray-800 mb-4">Marcas y Modelos Descartados</h2>
            <div class="overflow-x-auto">
                <table class="min-w-full bg-white rounded-lg overflow-hidden shadow-sm">
                    <thead class="bg-gray-100">
                        <tr>
                            <th class="px-6 py-3 text-left text-sm font-semibold text-gray-700">Tema</th>
                            <th class="px-6 py-3 text-left text-sm font-semibold text-gray-700">Razón de Descarte</th>
                        </tr>
                    </thead>
                    <tbody>
`

    // Procesar los descartes
    data.discards.list.forEach((discard) => {
        html += `
                        <tr class="border-b border-gray-200 hover:bg-gray-50">
                            <td class="px-6 py-4 text-gray-900">${discard.topic}</td>
                            <td class="px-6 py-4 text-gray-600">${discard.explanation}</td>
                        </tr>
    `
    })

    html += `
                    </tbody>
                </table>
            </div>
        </section>
    </div>
`

    return html
}
