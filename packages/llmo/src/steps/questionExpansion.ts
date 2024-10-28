import { z } from 'zod'
import { Context } from '../context'
import { Step, StepResult } from 'common/src/pipeline'
import { Ok } from 'ts-results'

export class QuestionExpansion extends Step<Input, Output, Context> {
    static STEP_NAME = 'Question Expansion'

    constructor(context: Context) {
        super(context, QuestionExpansion.STEP_NAME)
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        const output = input.questions.map((question) => {
            return (
                question +
                ' ' +
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
    'Proporciona enlaces y citas de internet para respaldar la respuesta',
]
