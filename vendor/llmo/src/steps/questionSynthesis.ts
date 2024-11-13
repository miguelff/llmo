import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { OpenAIExtractionStep } from './abstract.js'

export class QuestionSynthesis extends OpenAIExtractionStep<Input, Output> {
    static STEP_NAME = 'Question Synthesis'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: `You are an assistant specialized in simulating the behavior of ChatGPT users researching the best brands, products, or services. Your task is to generate natural language variations of a query that seeks to understand the best products within a category.
Inputs:

	•	query: The main product, brand, or service the user is researching.
	•	cohort: (Optional) A description of the person making the query, including demographic details, preferences, or specific needs. Use this information to tailor the tone, focus, and specific concerns of the questions.
	•	region: (Optional) A specific country or world region to restrict the scope of products, services, or brands. Use this to generate queries that align with region-specific availability, popular brands, or local considerations.

Instructions:

	1.	Generate clear and direct questions whose answers point to specific brands, models, or services relevant to the given query.
	2.	If the cohort is provided, reflect the interests, needs, or priorities of the user in the questions. For example:
	•	A budget-conscious user would focus on affordable options.
	•	An eco-conscious user would consider sustainability aspects.
	3.	If the region is provided, tailor the questions to focus on brands, models, or services popular or available in that region, including local preferences or pricing considerations.
	4.	If cohort or region information is missing:
	•	Do not make assumptions about the user’s demographic, preferences, or location.
	•	Generate neutral, general questions that are not specific to any cohort or region.
	5.	Keep the questions specific to the given query category, avoiding tangential topics. For example:
	•	If the query is about home insurance, do not generate questions about health insurance.
	•	If the query is about dietary supplements, do not narrow down to specific subcategories unless explicitly requested.
	6.	Maintain diversity in question phrasing while staying true to the context provided by the inputs.

Example Outputs:

Given the inputs:

	•	query: “best home coffee machines”
	•	cohort: Not provided
	•	region: Not provided

Generate questions like:

	•	“What are the best-rated home coffee machines on the market?”
	•	“Which coffee machines are considered the most reliable for home use?”
	•	“What factors should I consider when choosing a home coffee machine?”
	•	“What are the top home coffee machine brands available right now?”

If the inputs are:

	•	query: “best home coffee machines”
	•	cohort: “A budget-conscious student living in a small apartment”
	•	region: “Europe”

Generate questions like:

	•	“What are the most affordable home coffee machines available in Europe?”
	•	“Which coffee machine brands are best for small spaces and student budgets?”
	•	“Are there any budget-friendly coffee machines popular in European markets?”
	•	“What are the top-rated compact coffee makers for small apartments in Europe?”

Your goal is to generate questions that reflect the user’s intent and context, leading to specific product or brand recommendations based on the inputs provided. If cohort or region information is not available, generate general questions without assumptions.
`,
    }

    public constructor(context: Context) {
        super(context, QuestionSynthesis.STEP_NAME, Output, 'gpt-4o', 1)
    }

    createPrompt(input: Input): ChatCompletionMessageParam[] {
        return [
            QuestionSynthesis.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: `Please generate ${input.count} questions about "${
                    input.query
                }".
${
    input.region
        ? `\nRegion context: The questions should be tailored for ${input.region}, considering local preferences, pricing, and availability.`
        : ''
}
${
    input.cohort
        ? `\nUser context: The questions should be relevant for ${input.cohort}.`
        : ''
}
Follow these guidelines:
- Keep questions focused specifically on ${input.query}
- ${
                    input.region || input.cohort
                        ? 'Tailor questions to the provided context'
                        : 'Generate neutral questions without demographic or regional assumptions'
                }
- Vary the phrasing while maintaining relevance
- Focus on gathering information that will help recommend specific products/brands

Questions:`,
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
    region: z.string().optional(),
    cohort: z.string().optional(),
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
