import { z } from 'zod'
import { OpenAI } from 'openai'
import { zodResponseFormat } from 'openai/helpers/zod.mjs'
import { Logger } from 'pino'
import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { Result, Ok, Err } from 'ts-results-es'
import { env } from './env.js'

export class OpenAIModel<T> {
    public static fromEnv<T>(
        env: env,
        schema: z.AnyZodObject | undefined = undefined,
        model: string = 'gpt-4o',
        temperature: number = 1
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
