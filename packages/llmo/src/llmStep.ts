import { Step, StepResult } from 'common/src/pipeline'
import { z } from 'zod'
import { Context } from './context'
import { OpenAI } from 'openai'
import { zodResponseFormat } from 'openai/helpers/zod.mjs'
import { Logger } from 'pino'
import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { Result, Ok, Err } from 'ts-results'
import { env } from './env'

export class OpenAIModel<T> {
    public static fromEnv<T>(
        env: env,
        model: string = 'gpt-4o',
        temperature: number = 1,
        schema: z.AnyZodObject | undefined = undefined
    ) {
        const openai = new OpenAI({
            apiKey: env.OPENAI_API_KEY,
        })
        return new OpenAIModel<T>(openai, model, temperature, schema)
    }

    constructor(
        protected openai: OpenAI,
        protected model: string,
        protected temperature: number,
        protected schema: z.AnyZodObject | undefined
    ) {}

    async invoke(
        messages: ChatCompletionMessageParam[],
        logger: Logger | undefined = undefined,
        debugContext: any = {}
    ): Promise<Result<T, string>> {
        logger?.debug(
            {
                messages,
                temperature: this.temperature,
                ...debugContext,
            },
            'performing extraction'
        )

        const completion = await this.openai.beta.chat.completions.parse({
            model: this.model,
            messages: messages,
            response_format: this.schema
                ? zodResponseFormat(this.schema, 'extractionResponse')
                : undefined,
            temperature: this.temperature,
        })

        const message = completion.choices[0]?.message

        if (this.schema) {
            if (message.parsed) {
                logger?.debug(
                    { parsed: message.parsed },
                    'parsed extraction result'
                )
                return Ok(message.parsed as T)
            } else {
                logger?.debug(
                    { unparsed: message },
                    'failed to parse result with json schema, returning raw'
                )
                return Err(
                    'failed to parse result with json schema: ' + message
                )
            }
        } else {
            return Ok(message.content as T)
        }
    }
}

export abstract class OpenAIExtractionStep<I, O> extends Step<I, O, Context> {
    protected model: OpenAIModel<O>

    public constructor(
        context: Context,
        descriptor: string,
        protected outputSchema: z.AnyZodObject,
        protected modelName = 'gpt-4o',
        protected temperature = 1
    ) {
        super(context, descriptor)
        this.model = OpenAIModel.fromEnv(
            context.env,
            modelName,
            temperature,
            outputSchema
        )
    }

    async execute(input: I): Promise<StepResult<O>> {
        const logger = this.context.logger
        const prompt = this.createPrompt(input)
        const res = await this.model.invoke(prompt, logger)
        logger.debug(res, 'LLM result')
        if (res.ok) {
            const parsed = this.outputSchema.safeParse(res.val)
            if (parsed.error) {
                return Err({
                    cause: parsed.error.message,
                    step: this.descriptor,
                })
            } else {
                return Ok(parsed.data as O)
            }
        } else {
            return Err({
                cause: 'There was an error invoking the model',
                step: this.descriptor,
            })
        }
    }

    abstract createPrompt(input: I): ChatCompletionMessageParam[]
}

export abstract class MapperStep<I, O, C> extends Step<I, O[], Context> {
    protected innerStep: Step<C, O, Context>

    constructor(
        context: Context,
        descriptor: string,
        innerStep: Step<C, O, Context>
    ) {
        super(context, descriptor)
        this.innerStep = innerStep
    }

    abstract getCollection(input: I): C[]

    async execute(input: I): Promise<StepResult<O[]>> {
        const collection = this.getCollection(input)
        const results: O[] = []

        for (const item of collection) {
            console.log(item, 'item')
            const result = await this.innerStep.execute(item)
            if (!result.ok) {
                return result
            }
            results.push(result.val)
        }

        return Ok(results)
    }
}
