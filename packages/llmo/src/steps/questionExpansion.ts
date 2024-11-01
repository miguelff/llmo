import { z } from 'zod'
import { Context } from '../context'
import { ExtractionStep, Ok, StepResult } from './abstract'

export class QuestionExpansion extends ExtractionStep<Input, Output, Context> {
    static STEP_NAME = 'Question Expansion'

    constructor(context: Context) {
        super(context, QuestionExpansion.STEP_NAME)
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        const output = input.questions.map((question) => {
            return (
                question +
                '. ' +
                suffixes[Math.floor(Math.random() * suffixes.length)]
            )
        })
        this.logger.info({ output }, 'Expanded questions')
        return Ok({ questions: output })
    }
}

const Input = z.object({
    questions: z
        .array(z.string())
        .describe(
            'Las preguntas que usuarios de ChatGPT harían con el objetivo de resolver sus necesidades de información'
        ),
})
export type Input = z.infer<typeof Input>

const Output = Input
export type Output = z.infer<typeof Output>

const suffixes = [
    'Incluye URLs para respaldar la información proporcionada. A ser posible reviews en blogs o webs especializadas, no incluyas fuentes que sean las oficiales de la propia marca, producto, servicio citado.',
]
