import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { OpenAIExtractionStep } from './abstract.js'

export class QuestionSynthesis extends OpenAIExtractionStep<Input, Output> {
    static STEP_NAME = 'Question Synthesis'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: `Eres un asistente especializado en simular el comportamiento de usuarios de ChatGPT en base a las consultas que ellos formularían a un buscador convencional como google.
        Tu objetivo es generar preguntas cuyas respuestas apunten a marcas y modelos de productos o servicios. Intenta que las preguntas estén relacionadas con el objeto de la consulta, y no
        otros relacionados. Por ejemplo, si te preguntan por un teléfono móvil, no respondas con preguntas sobre ordenadores, si te preguntan por una prenda de ropa, no respondas con calzado, o 
        con preguntas sobre productos de limpieza. Las preguntas deben ser claras y directas, y no modificar demasiado la consulta original incluyendo atributos derivados, si te pregunto por
        una objeto, como un coche, no respondas con preguntas sobre otros objetos, como ordenadores, si te pregunto por un tipo de producto concreto, como seguros de hogar, no respondas con seguros de salud.
        Si pregunto por algo general como "mejores suplementos alimenticios", no respondas con "mejores suplementos de omega 3" o "mejores suplementos para deportistas", sino que respondas con 
        preguntas relacionadas con suplementos alimenticios en general.`,
    }

    public constructor(context: Context) {
        super(context, QuestionSynthesis.STEP_NAME, Output, 'gpt-4o', 1)
    }

    createPrompt(input: Input): ChatCompletionMessageParam[] {
        return [
            QuestionSynthesis.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: `Consulta: "${input.query}", dame ${input.count} preguntas. \nPreguntas:`,
            },
        ]
    }

    workUnits(): number {
        return 1
    }

    description(): string {
        return `Sampling queries from cohort`
    }
}

const Input = z.object({
    query: z.string(),
    count: z.number().optional().default(10),
})
export type Input = z.infer<typeof Input>

const Output = z.object({
    questions: z
        .array(z.string())
        .describe(
            'Las preguntas que usuarios de ChatGPT harían con el objetivo de resolver sus necesidades de información'
        ),
})
export type Output = z.infer<typeof Output>
