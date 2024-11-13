import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z, ZodSchema } from 'zod'
import { Context } from '../context.js'
import { type Output as Input } from './questionExpansion.js'
import { ExtractionStep, StepResult, models } from './abstract.js'
import { Err, Ok, Result } from 'ts-results-es'
import { searchBing } from '../search.js'
import { OpenAI } from 'openai'
import { RunnableToolFunctionWithParse } from 'openai/lib/RunnableFunction'
import { zodToJsonSchema } from 'zod-to-json-schema'
import { JSONSchema } from 'openai/lib/jsonschema'

export class QuestionFormulation extends ExtractionStep<
    Input,
    Output,
    Context
> {
    static STEP_NAME = 'Question Formulation'

    private answerer: QuestionAnswerer

    public constructor(context: Context) {
        super(context, QuestionFormulation.STEP_NAME)
        this.answerer = new QuestionAnswerer(context)
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        this.beforeStart()
        const output: Record<string, string> = {}
        await Promise.all(
            input.questions.map((question) =>
                (async () => {
                    try {
                        const res = await this.answerQuestion(question)
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
                })()
            )
        )
        const result = Ok(output)
        this.afterEnd(result)
        return result
    }

    workUnits(): number {
        return this.context.inputArguments.count
    }

    description(): string {
        return `Formulating queries against ChatGPT gpt-4o`
    }

    async answerQuestion(question: string): Promise<Result<string, Error>> {
        return this.answerer.answer(question)
    }
}

export const Output = z.record(z.string()).describe('Preguntas y Respuestas')
export type Output = z.infer<typeof Output>

class QuestionAnswerer {
    private client: OpenAI

    constructor(private context: Context, private temperature: number = 0) {
        this.context = context
        this.temperature = temperature
        this.client = new OpenAI()
    }

    async answer(question: string): Promise<Result<string, Error>> {
        const runner = this.client.beta.chat.completions
            .runTools({
                model: 'gpt-4o',
                temperature: this.temperature,
                stream: true,
                messages: this.createPrompt(question),
                tools: [
                    zodFunction({
                        function: currySearchBing(this.context),
                        schema: z.object({
                            query: z.string(),
                            count: z.number(),
                        }),
                        name: 'search',
                        description:
                            'Busca en Bing resultados relevantes para proporcionar información fiable para la pregunta',
                    }),
                ],
            })
            .on('message', (msg) =>
                this.context.logger.trace(msg, 'message received')
            )
            .on('functionCall', (functionCall) =>
                this.context.logger.trace(functionCall, 'functionCall received')
            )
            .on('functionCallResult', (functionCallResult) =>
                this.context.logger.trace(
                    functionCallResult,
                    'functionCallResult received'
                )
            )
            .on('content', (diff) => this.context.logger.debug(diff, 'content'))

        const result = await runner.finalChatCompletion()

        // PArse the result, obtaining the answer which should be the first choice that's a message from the assistant
        const answer = result.choices.find(
            (c) => c.message.role === 'assistant'
        )
        if (!answer) {
            return Err(new Error('No answer found'))
        }
        const content = answer.message.content
        if (!content) {
            return Err(new Error('No content found in answer'))
        }
        return Ok(content)
    }

    private createPrompt(question: string): ChatCompletionMessageParam[] {
        return [
            {
                role: 'system',
                content:
                    'Eres un asistente que ayuda a elegir los mejores productos y servicios',
            },
            {
                role: 'user',
                content: question,
            },
        ]
    }
}

function currySearchBing(context: Context) {
    return async (args: { query: string; count: number }) => {
        return searchBing(context, args.query, args.count)
    }
}

function zodFunction<T extends object>({
    function: fn,
    schema,
    description = '',
    name,
}: {
    function: (args: T) => Promise<object>
    schema: ZodSchema<T>
    description?: string
    name?: string
}): RunnableToolFunctionWithParse<T> {
    return {
        type: 'function',
        function: {
            function: fn,
            name: name ?? fn.name,
            description: description,
            parameters: zodToJsonSchema(schema) as JSONSchema,
            parse(input: string): T {
                const obj = JSON.parse(input)
                return schema.parse(obj)
            },
        },
    }
}
