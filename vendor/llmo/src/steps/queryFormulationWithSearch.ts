import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { type Output as Input } from './questionExpansion.js'
import { ExtractionStep, StepResult, models } from './abstract.js'
import { Ok } from 'ts-results-es'
import { OpenAIModel } from '../llm.js'

import { ChatPromptTemplate } from '@langchain/core/prompts'
import { createToolCallingAgent } from 'langchain/agents'
import { AgentExecutor } from 'langchain/agents'
import { tool } from '@langchain/core/tools'
import { ChatOpenAI } from '@langchain/openai'

const llm = new ChatOpenAI({
    model: 'gpt-4o-mini',
})

const magicTool = tool(
    async ({ input }: { input: number }) => {
        return `${input + 2}`
    },
    {
        name: 'magic_function',
        description: 'Applies a magic function to an input.',
        schema: z.object({
            input: z.number(),
        }),
    }
)

const tools = [magicTool]

const prompt = ChatPromptTemplate.fromMessages([
    [
        'system',
        'Eres un agente especializado en comparación de empresas/marcas y productos/servicios y en ayudar a los usuarios a tomar decisiones',
    ],
    ['placeholder', '{chat_history}'],
    ['human', '{input}'],
    ['placeholder', '{agent_scratchpad}'],
])

const agent = createToolCallingAgent({
    llm,
    tools,
    prompt,
})
const agentExecutor = new AgentExecutor({
    agent,
    tools,
})

export class QuestionFormulationWithSearch extends ExtractionStep<
    Input,
    Output,
    Context
> {
    static STEP_NAME = 'Question Formulation'
    private model: OpenAIModel<string>

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content:
            'Eres un agente especializado en comparación de empresas/marcas y productos/servicios y en ayudar a los usuarios a tomar decisiones',
    }

    public constructor(context: Context) {
        super(context, QuestionFormulationWithSearch.STEP_NAME)
        this.model = models.openai.fromEnv(context.env, undefined, 'gpt-4o', 0)
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        this.beforeStart()
        const output: Record<string, string> = {}
        for (const question of input.questions) {
            const prompt = this.createPrompt(question)
            try {
                const res = await this.model.invoke(prompt, this.logger)
                if (res.isOk()) {
                    output[question] = res.value
                    this.logger.info(
                        { question, answer: res.value },
                        'question answered'
                    )
                } else {
                    this.logger.error(
                        res.error,
                        `error asking model for question ${question}, skipping.`
                    )
                }
                this.afterInvoke(res as any)
            } catch (e) {
                this.logger.error(
                    e,
                    `error asking model for question ${question}, skipping.`
                )
            }
        }
        return Ok(output)
    }

    createPrompt(content: string): ChatCompletionMessageParam[] {
        return [
            QuestionFormulation.SYSTEM_MESSAGE,
            {
                role: 'user',
                content,
            },
        ]
    }

    workUnits(): number {
        return this.context.bag['count']
    }

    description(): string {
        return `Formulating queries against ChatGPT gpt-4o`
    }
}

const Output = z.record(z.string()).describe('Preguntas y Respuestas')
export type Output = z.infer<typeof Output>