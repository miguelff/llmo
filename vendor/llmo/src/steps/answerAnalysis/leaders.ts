import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../../context.js'
import { Ok } from 'ts-results-es'
import { OpenAIExtractionStep } from '../abstract.js'
import { type Output as BrandsAndLinksOutput } from './brandsAndLinks.js'
import {
    QuestionFormulation,
    type Output as QuestionFormulationOutput,
} from '../questionFormulation.js'

export const Output = z.object({
    leaders: z.array(
        z.object({
            name: z.string(),
            score: z.number(),
        })
    ),
})

export type Output = z.infer<typeof Output>

export class Leaders extends OpenAIExtractionStep<
    BrandsAndLinksOutput,
    Output
> {
    static STEP_NAME = 'AnswerAnalysis::Leaders'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: `You are an assistant that ranks brands/products/services.`,
    }

    public constructor(context: Context, model: string) {
        super(context, Leaders.STEP_NAME, Output, model)
    }

    createPrompt(input: BrandsAndLinksOutput): ChatCompletionMessageParam[] {
        const previousAnswers = this.context.previous_answers[
            QuestionFormulation.STEP_NAME
        ] as QuestionFormulationOutput

        if (!previousAnswers) {
            throw new Error(
                'Previous answers for question formulation not found'
            )
        }

        return [
            Leaders.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: `
If I asked you about ${
                    this.context.input_arguments.query
                }, which brands/products/services would you say are the best from the following list?

${input.topics.map((topic) => `- ${topic.name}`).join('\n')}

* Take into account a previous context of similar queries and your responses to them. This information is between [CONTEXT] tags.
* Calculate a score from 0-100 for each brand/product/service
* Return the top 5 brands/products/services with the highest score and their scores.

[CONTEXT]
${Object.entries(previousAnswers)
    .map(
        ([question, answer]) =>
            `Query -> Your previous Answer: ${question} -> \n${answer}`
    )
    .join('\n')}
[END_CONTEXT]
`,
            },
        ]
    }

    workUnits(): number {
        return 1
    }

    description(): string {
        return 'Ranking brands by relevance and sentiment'
    }
}
