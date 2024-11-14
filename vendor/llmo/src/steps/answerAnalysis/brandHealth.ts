import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../../context.js'
import { ExtractionStep, StepResult } from '../abstract.js'
import { Output as LeadersOutput } from './leaders.js'
import { Output as BrandsAndLinksOutput } from './brandsAndLinks.js'
import { Ok } from 'ts-results-es'

export const Input = z.object({
    brandsAndLinks: BrandsAndLinksOutput,
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
                )
                .optional(),
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

export class BrandHealth extends ExtractionStep<Input, Output, Context> {
    static STEP_NAME = 'AnswerAnalysis::BrandHealth'

    public constructor(context: Context) {
        super(context, BrandHealth.STEP_NAME)
    }

    /**
     *  If the brand is mentioned in the ranking, then we need to find the index of the brand in the ranking
     *      * If the brand is the first in the ranking, then health is "best"
     *      * If it's in the top quarter, then health is "excellent"
     *      * else health is "good", because it's still a top performer
     *  If the brand is not mentioned in the ranking, if a n-gram of the brand is mentioned in the ranking, then we need to find the index of the n-gram in the ranking
     *      * If the n-gram is in the ranking in top half, then health is "good"
     *      * If the n-gram is the bottom half, then health is "neutral"
     *      * else, if it's not in the mentioned, then health is "bad"
     */
    async execute(input: Input): Promise<StepResult<Output>> {
        const brand = normalize(input.brandInfo)
        this.context.logger.info(
            { leaders: JSON.stringify(input.leaders, null, 2) },
            'Leaders'
        )
        this.context.logger.info(JSON.stringify(brand, null, 2), 'brand')

        const leaderIdx = indexLeaders(input)
        this.context.logger.info(
            { index: JSON.stringify(leaderIdx, null, 2) },
            'Leader index'
        )

        const brandIdx = indexBrands(input)
        const unigramRank = rankBrand(brand, leaderIdx)

        if (unigramRank.rank == 100) {
            return Ok({
                brands: [
                    {
                        health: 'best',
                        rank: unigramRank.rank,
                        score: 100,
                        remarks: 'Your brand is the best in ranking',
                        citations: brandCitations(brand, brandIdx),
                    },
                ],
            })
        } else if (unigramRank.rank >= 75) {
            return Ok({
                brands: [
                    {
                        health: 'excellent',
                        rank: unigramRank.rank,
                        score: unigramRank.data?.score ?? 0,
                        remarks: 'Your brand is in the top 25% of the ranking',
                        citations: brandCitations(brand, brandIdx),
                    },
                ],
            })
        } else if (unigramRank.rank > 0) {
            return Ok({
                brands: [
                    {
                        health: 'good',
                        rank: unigramRank.rank,
                        score: unigramRank.data?.score ?? 0,
                        remarks:
                            'Your brand was cited in answers to user questions',
                        citations: brandCitations(brand, brandIdx),
                    },
                ],
            })
        } else {
            const ngramsIndex = brandNgrams(input)
            const brandNGrams = wordNgrams(brand)

            const ngramsIndexMatches = ngramsIndex.find((ngram) =>
                brandNGrams.some((ngramBrand) => ngramBrand === ngram.name)
            )

            if (ngramsIndexMatches) {
                return Ok({
                    brands: [
                        {
                            health: 'neutral',
                            rank: undefined,
                            score: undefined,
                            remarks:
                                'Other products relative to your brand were mentioned in answers to user questions',
                            citations: ngramsIndexMatches.keyPhrases,
                        },
                    ],
                })
            } else {
                return Ok({
                    brands: [
                        {
                            health: 'bad',
                            rank: undefined,
                            score: undefined,
                            remarks: 'Your brand was not mentioned',
                            citations: [],
                        },
                    ],
                })
            }
        }
    }

    workUnits(): number {
        return 0
    }

    description(): string {
        return 'Analyzing brand health and sentiment'
    }
}

type BrandRank = {
    rank: number
    data?: { name: string; score: number }
}

function rankBrand(brand: string, topicRank: TopicRank): BrandRank {
    const index = topicRank.index.findIndex((t) => t.name === brand)

    var rank = 0

    if (index !== -1) {
        // Calculate percentage of items with lower rank
        const lowerRankCount = topicRank.index.filter(
            (t) => t.rank > topicRank.index[index].rank
        ).length
        rank = Math.ceil((lowerRankCount / topicRank.count) * 100)
    }

    var data: { name: string; score: number } | undefined = undefined
    if (index !== -1) {
        data = topicRank.index[index]
    }

    return {
        rank,
        data,
    }
}

function brandCitations(brand: string, brands: Brands): string[] {
    return brands.find((b) => b.name === brand)?.keyPhrases ?? []
}

type TopicRank = {
    index: { name: string; score: number; rank: number }[]
    count: number
}

function indexLeaders(input: Input): TopicRank {
    var rank = 0
    const leaders = input.leaders.leaders.map((leader) => ({
        name: normalize(leader.name),
        score: leader.score,
        rank: ++rank,
    }))

    return {
        index: leaders,
        count: rank,
    }
}

type Brands = {
    name: string
    urls: string[]
    keyPhrases: string[]
}[]

function indexBrands(input: Input): Brands {
    return input.brandsAndLinks.topics.map((brand) => ({
        name: normalize(brand.name),
        urls: brand.urls,
        keyPhrases: brand.keyPhrases,
    }))
}

function brandNgrams(input: Input): Brands {
    const brands = indexBrands(input)
    const result: Brands = []

    for (const brand of brands) {
        const ngrams = wordNgrams(brand.name)
        result.push(
            ...ngrams.map((ngram) => ({
                name: ngram,
                urls: brand.urls,
                keyPhrases: brand.keyPhrases,
            }))
        )
    }

    return result
}

function normalize(name: string) {
    return name
        .toLowerCase()
        .replace(/[^a-z0-9 ]/g, '')
        .trim()
}

function wordNgrams(sentence: string): string[] {
    const ngrams: string[] = []

    const words = sentence.split(' ')
    for (let length = 1; length <= words.length; length++) {
        for (let start = 0; start <= words.length - length; start++) {
            ngrams.push(words.slice(start, start + length).join(' '))
        }
    }

    return ngrams
}
