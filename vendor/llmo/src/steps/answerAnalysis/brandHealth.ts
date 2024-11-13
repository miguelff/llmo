import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../../context.js'
import { OpenAIExtractionStep } from '../abstract.js'
import {
    QuestionFormulation,
    Output as QuestionFormulationOutput,
} from '../questionFormulation.js'
import { Output as LeadersOutput } from './leaders.js'

export const Input = z.object({
    leaders: LeadersOutput,
    brandInfo: z.string(),
})
export type Input = z.infer<typeof Input>

export const Output = z.object({
    brands: z.array(
        z.object({
            health: z
                .enum(['best', 'excellent', 'good', 'neutral', 'bad'])
                .optional(),
            rank: z
                .number()
                .optional()
                .describe(
                    'The position of the brand in the ranking, if it is in the ranking'
                ),
            score: z
                .number()
                .describe(
                    'The score of the brand between 1 and 100, equal to that of the ranking'
                ),
            remarks: z
                .string()
                .describe(
                    'Why the brand was given the health and score values'
                ),
            citations: z
                .array(z.string())
                .describe(
                    'Excerpts from the answers where the brand is mentioned'
                ),
        })
    ),
})
export type Output = z.infer<typeof Output>

export class BrandHealth extends OpenAIExtractionStep<Input, Output> {
    static STEP_NAME = 'AnswerAnalysis::BrandHealth'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: `You are an assistant specialized in analyzing brand health and ranking from text data. Your task is to analyze the brand health and rank the brands based on the context provided.
        The context is comprised by:

        * A user question, that is aimed at finding information about the best brands, products or services, between [QUESTION][/QUESTION] tags
        * A series of answers, that aim at provide information about the best brands, products or services for the user question, between [ANSWERS][/ANSWERS] tags
        * A ranking of the brands that are relevant to the query, that was elaborated by another agent, between [RANKING][/RANKING] tags
        * A brand for which you need to analyze the health, between [BRAND][/BRAND] tags
        
        Given this context, take the brand and follow the following heuristic:

        * See whether it's in the ranking and in which position. If it's in the ranking, pick the position and the score. 
        * If it's not in the ranking, see whether it's mentioned in the answers. If it's mentioned, see whether it's mentioned in a positive or negative way. 

        The result will be:

        * Health: best/excellent/good/neutral/bad: 
            - Best -> ranking 1
            - Excellent -> ranking 2-5
            - Good -> ranking 6-10
            - Neutral -> lower in the ranking, or not in the ranking, but mentioned positively in the answers in any case
            - Bad -> not even mentioned in the answers, or mentioned negatively

        * Rank: the position of the brand in the ranking, if it's in the ranking.
        * Score: the score of the brand in the ranking, if it's in the ranking, a lower score than those in the ranking if it's not in the ranking, below the latest in ranking, but closer to it if the exact product is not mentioned but the brand is, 0 if it's not even mentioned in the answers.
        * Remarks: Why it was given the health score, if it's not in the ranking. Examples: "It's mentioned in the answers as a good brand", "It's not mentioned in the answers, but a different product of the brand is mentioned positively", "It's not mentioned in the answers"
        * Citations: excerpts from the answers where the brand is mentioned, if they exist.
        
        Provide the result in a structured format that can be parsed.
        `,
    }

    public constructor(context: Context, model: string) {
        super(context, BrandHealth.STEP_NAME, Output, model, 0.3)
    }

    createPrompt(input: Input): ChatCompletionMessageParam[] {
        const previousAnswers = this.context.previousAnswers[
            QuestionFormulation.STEP_NAME
        ] as QuestionFormulationOutput

        if (!previousAnswers) {
            throw new Error(
                'Previous answers for question formulation not found'
            )
        }

        return [
            BrandHealth.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: `Please analyze the [BRAND] health for the following brands based on your own previous [ANSWERS] relative to a user [QUERY] and the [RANKING] of different brands another agent elaborated:

[BRAND]
${input.brandInfo}
[/BRAND]

[QUESTION]
${this.context.inputArguments.query}
[/QUESTION]

[ANSWERS]
${Object.entries(previousAnswers)
    .map(
        ([_, answer]) => `
Answer: ${answer}
`
    )
    .join('\n\n')}
[/ANSWERS]

[RANKING]
${input.leaders.leaders
    .map(
        (leader, index) => `
Brand: ${leader.name}
Rank: ${index + 1}
Score: ${leader.score}
Context: ${leader.reason}
`
    )
    .join('\n\n')}
[/RANKING]`,
            },
        ]
    }

    workUnits(): number {
        return 1
    }

    description(): string {
        return 'Analyzing brand health and sentiment'
    }
}
