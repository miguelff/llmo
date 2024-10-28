import { Step, StepResult } from 'common/src/pipeline'
import { z } from 'zod'
import { Context } from './context'
import { OpenAI } from 'openai'
import { zodResponseFormat } from 'openai/helpers/zod.mjs'
import { Logger } from 'pino'
import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { Result, Ok, Err } from 'ts-results'

class OpenAIModel<T> {
    constructor(
        protected openai: OpenAI,
        protected schema: z.AnyZodObject,
        protected model: string,
        protected temperature: number
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
            response_format: zodResponseFormat(
                this.schema,
                'extractionResponse'
            ),
            temperature: this.temperature,
        })

        const message = completion.choices[0]?.message

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
            return Err('failed to parse result with json schema: ' + message)
        }
    }
}

export abstract class OpenAILLMStep<I, O> extends Step<I, O, Context> {
    protected model: OpenAIModel<O>

    public constructor(
        context: Context,
        descriptor: string,
        protected outputSchema: z.AnyZodObject,
        protected modelName = 'gpt-4o',
        protected temperature = 1
    ) {
        super(context, descriptor)
        const openai = new OpenAI({
            apiKey: context.env.OPENAI_API_KEY,
        })

        this.model = new OpenAIModel(
            openai,
            outputSchema,
            modelName,
            temperature
        )
    }

    async execute(input: I): Promise<StepResult<O>> {
        const logger = this.context.logger
        logger.debug(input, 'generating prompt')
        const prompt = this.createPrompt(input)
        logger.debug('asking model')
        const res = await this.model.invoke(prompt, logger)
        logger.debug(res, 'result')
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
