import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../../context.js'
import { type Output as BrandsAndLinksOutput } from './brandsAndLinks.js'
import { Ok } from 'ts-results-es'
import { ExtractionStep, StepResult } from '../abstract.js'

export const Output = z.object({
    leaders: z.array(
        z.object({
            name: z.string(),
            score: z.number(),
        })
    ),
})

export type Output = z.infer<typeof Output>

export class Leaders extends ExtractionStep<
    BrandsAndLinksOutput,
    Output,
    Context
> {
    static STEP_NAME = 'AnswerAnalysis::Leaders'

    public constructor(context: Context) {
        super(context, Leaders.STEP_NAME)
    }

    async execute(input: BrandsAndLinksOutput): Promise<StepResult<Output>> {
        // Create a map to count brand occurrences
        const brandCounts = input.topics.reduce((acc, topic) => {
            acc[topic.name] = (acc[topic.name] || 0) + 1
            return acc
        }, {} as Record<string, number>)

        // Convert to array and find min/max counts
        const entries = Object.entries(brandCounts)
        const maxCount = Math.max(...entries.map(([_, count]) => count))
        const minCount = Math.min(...entries.map(([_, count]) => count))

        // Convert to array of {name, score} objects with normalized scores
        const leaders = entries
            .map(([name, count]) => ({
                name,
                // Normalize score between 50 and 100
                score:
                    maxCount === minCount
                        ? 75 // If all counts are equal, use middle value
                        : 50 +
                          (50 * (count - minCount)) / (maxCount - minCount),
            }))
            .sort((a, b) => b.score - a.score) // Sort by score descending

        return Ok({ leaders })
    }

    workUnits(): number {
        return 0
    }

    description(): string {
        return 'Ranking brands by relevance'
    }
}
