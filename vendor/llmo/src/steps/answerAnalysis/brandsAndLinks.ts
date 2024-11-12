import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../../context.js'
import { Ok } from 'ts-results-es'
import {
    MapperStep,
    OpenAIExtractionStep,
    StepResult,
    ExtractionStep,
} from '../abstract.js'
import { Output as QuestionFormulationOutput } from '../questionFormulation.js'

export const Output = z.object({
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

export class BrandsAndLinks extends ExtractionStep<
    QuestionFormulationOutput,
    Output,
    Context
> {
    static STEP_NAME = 'AnswerAnalysis::BrandsAndLinks'
    private mapper: SingleAnswerAnalysisMapper

    public constructor(context: Context, model: string) {
        super(context, BrandsAndLinks.STEP_NAME)
        this.mapper = new SingleAnswerAnalysisMapper(context, model)
    }

    async execute(
        input: QuestionFormulationOutput
    ): Promise<StepResult<Output>> {
        const result = await this.mapper.execute(input)
        if (result.isErr()) {
            return result
        }
        const topics = result.value.reduce((acc, r) => {
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

        const urls = result.value.reduce((acc, r) => {
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

            // Handle brand/product/service URLs
            r.topics.forEach((topic) => {
                if (topic.url) {
                    addUrl(topic.url)
                }
            })
            return acc
        }, {} as Record<string, string[]>)

        return Ok({
            topics: Object.values(topics),
            urls,
        })
    }

    workUnits(): number {
        return this.context.inputArguments.count
    }

    description(): string {
        return `Analyzing brands and links`
    }
}

const Url = z.string()

const Topic = z.object({
    name: z.string().describe('The name of the brand/product/service'),
    url: z
        .string()
        .nullable()
        .describe(
            'The associated link provided in the text, or null if there is no link specifically referring to that brand/product/service'
        ),
    sentiment: z
        .number()
        .describe(
            'A sentiment rating from 1 to 5, where 5 is very positive, 3 is neutral and 1 is very negative'
        ),
})

const IntermediateOutput = z.object({
    topics: z
        .array(Topic)
        .describe('A list of information about brands/products/services'),
    orphanUrls: z
        .array(Url)
        .describe(
            'A list of general links that are not specifically referring to any brand/product/service'
        ),
})
export type IntermediateOutput = z.infer<typeof IntermediateOutput>

export class SingleAnswerAnalysisMapper extends MapperStep<
    QuestionFormulationOutput,
    IntermediateOutput,
    string
> {
    static STEP_NAME = 'AnswerAnalysisMapper'
    public constructor(context: Context, model: string) {
        super(
            context,
            BrandsAndLinks.STEP_NAME,
            new SingleAnswerBrandsAndLinks(context, model)
        )
    }

    getCollection(input: QuestionFormulationOutput): string[] {
        return Object.values(input)
    }
}

export class SingleAnswerBrandsAndLinks extends OpenAIExtractionStep<
    string,
    IntermediateOutput
> {
    static STEP_NAME = 'SingleAnswerAnalysis'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: `You are an assistant for extracting performance information about brands, products and services from prompt outputs
        based on the user's initial query.
        
        Given an LLM output, extract a list of all mentioned brands/products/services. For each one, provide:

        - **Name**: the name of the brand/product/service.
        - **URL**: the associated link provided in the text, or null if there is no link specifically referring to that brand/product/service
        - **Sentiment**: a sentiment rating from 1 to 5, where 5 is very positive, 3 is neutral and 1 is very negative.

        Also provide a list of general links that are not referring to any specific brand.

        Steps:
        1. Identify the brands/products/services mentioned in the text.
        2. Do not include brands/products/services that are not related to the original Query. To do this:
            * If the brand/product/service does not refer to a brand/product/service, discard it from the output.
            * If the brand/product/service refers to a brand/product/service but is not related to the original Query, discard it from the output.
        3. For each one, analyze the sentiment of the text regarding that brand/product/service.
        4. Look for links in the text that are associated with the brand/product/service.
        5. If there is no specific link for the brand/product/service, use null.
        6. If the link does not refer to a specific brand/product/service but rather to all in general, add that URL to the list of general links.`,
    }

    public constructor(context: Context, model: string) {
        super(
            context,
            SingleAnswerBrandsAndLinks.STEP_NAME,
            IntermediateOutput,
            model
        )
    }

    createPrompt(input: string): ChatCompletionMessageParam[] {
        return [
            SingleAnswerBrandsAndLinks.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: `Original Query: ${this.context.inputArguments.query}
---                
TEXT: "${input}"`,
            },
        ]
    }
}
