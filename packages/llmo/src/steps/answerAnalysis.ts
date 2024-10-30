import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context'
import {
    MapperStep,
    OpenAIExtractionStep,
    Ok,
    StepResult,
    ExtractionStep,
} from './abstract'
import { type Output as QuestionFormulationOutput } from './questionFormulation'

const Output = z.object({
    topics: z.array(
        z.object({
            name: z.string(),
            urls: z.array(z.string()),
            sentiments: z.array(z.number()),
        })
    ),
    urls: z.record(z.string(), z.array(z.string())),
})
export type Output = z.infer<typeof Output>

export class AnswerAnalysis extends ExtractionStep<
    QuestionFormulationOutput,
    Output,
    Context
> {
    static STEP_NAME = 'AnswerAnalysis'
    private mapper: AnswerAnalysisMapper

    public constructor(context: Context) {
        super(context, AnswerAnalysis.STEP_NAME)
        this.mapper = new AnswerAnalysisMapper(context)
    }

    async execute(
        input: QuestionFormulationOutput
    ): Promise<StepResult<Output>> {
        const result = await this.mapper.execute(input)
        if (!result.ok) {
            return result
        }
        const topics = result.val.reduce((acc, r) => {
            r.topics.forEach((topic) => {
                if (!acc[topic.name]) {
                    acc[topic.name] = {
                        name: topic.name,
                        urls: [],
                        sentiments: [],
                    }
                }
                if (topic.url) {
                    acc[topic.name].urls.push(topic.url)
                }
                acc[topic.name].sentiments.push(topic.sentiment)
            })
            return acc
        }, {} as Record<string, { name: string; urls: string[]; sentiments: number[] }>)

        const urls = result.val.reduce((acc, r) => {
            // Helper function to add URL to accumulator
            const addUrl = (url: string) => {
                try {
                    const domain = new URL(url).hostname
                    if (!acc[domain]) {
                        acc[domain] = []
                    }
                    if (!acc[domain].includes(url)) {
                        acc[domain].push(url)
                    }
                } catch (e) {
                    // Skip invalid URLs
                }
            }

            // Handle orphan URLs
            r.orphanUrls.forEach(addUrl)

            // Handle topic URLs
            r.topics.forEach((topic) => {
                if (topic.url) {
                    addUrl(topic.url)
                }
            })
            return acc
        }, {} as Record<string, string[]>)

        return Ok({ topics: Object.values(topics), urls })
    }
}

const Url = z.string()

const Topic = z.object({
    name: z.string().describe('El nombre de la marca/producto/servicio'),
    url: z
        .string()
        .nullable()
        .describe(
            'El enlace asociado proporcionado en el texto, o nulo si no hay un enlace que se refiera específicamente a ese topic'
        ),
    sentiment: z
        .number()
        .describe(
            'Una calificación del sentimiento del 1 al 5, donde 5 es muy positivo, 3 es neutral y 1 es muy negativo'
        ),
})

const IntermediateOutput = z.object({
    topics: z.array(Topic).describe('Una lista de información sobre topics'),
    orphanUrls: z
        .array(Url)
        .describe(
            'Una lista de enlaces generales, que el texto no esté refieriendo a un topic concreto'
        ),
})
export type IntermediateOutput = z.infer<typeof IntermediateOutput>

export class AnswerAnalysisMapper extends MapperStep<
    QuestionFormulationOutput,
    IntermediateOutput,
    string
> {
    static STEP_NAME = 'AnswerAnalysisMapper'
    public constructor(context: Context) {
        super(
            context,
            AnswerAnalysis.STEP_NAME,
            new SingleAnswerAnalysis(context)
        )
    }

    getCollection(input: QuestionFormulationOutput): string[] {
        return Object.values(input)
    }
}

export class SingleAnswerAnalysis extends OpenAIExtractionStep<
    string,
    IntermediateOutput
> {
    static STEP_NAME = 'SingleAnswerAnalysis'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: `Eres un asistente para la extracción de información de rendimiento de marcas, productos y servicios (en adelante topics) en los outputs de prompts
        en base a consulta inicial del usuario.
        
        Dado un output de un LLM, extrae una lista de todos los topics mencionados. Para cada uno, proporciona:

        - **Name**: el nombre del topic.
        - **URL**: el enlace asociado proporcionado en el texto, o nulo si no hay un enlace que se refiera específicamente a esa marca/producto/servicio
        - **Sentiment**: una calificación del sentimiento del 1 al 5, donde 5 es muy positivo, 3 es neutral y 1 es muy negativo.

        También proporciona una lista de enlaces generales, que el texto no esté refieriendo a una marca concreta.

        Pasos:
        1. Identifica los topics mencionados en el texto.
        2. No incluyas topics que no estén relacionados con la Consulta original del usuario. Para ello:
            * Si el topic no hace referencia a una marca/producto/servicio, descártalo del output.
            * Si el topic hace referencia a una marca/producto/servicio, pero no está relacionado con la Consulta original, descártalo del output.
        3. Para cada uno, analiza el sentimiento del texto respecto a ese topic.
        4. Busca enlaces en el texto que estén asociados al topic.
        5. Si no hay un enlace específico para el topic, usa nulo.
        6. Si el enlace no hace referencia a un topic concreto si no a todos en general, añade esa URL a la lista de enlaces generales.`,
    }

    public constructor(context: Context) {
        super(
            context,
            SingleAnswerAnalysis.STEP_NAME,
            IntermediateOutput,
            'gpt-4o'
        )
    }

    createPrompt(input: string): ChatCompletionMessageParam[] {
        return [
            SingleAnswerAnalysis.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: `Consulta original: ${this.context.bag['query']}
--                
TEXTO: "${input}"`,
            },
        ]
    }
}
