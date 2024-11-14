import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { inferLanguage } from '../lang.js'
import { OpenAIExtractionStep, OpenAIPrompt, StepResult } from './abstract.js'
import { Input } from './questionSynthesis.js'
import { Err } from 'ts-results-es'
import { Logger } from 'pino'
import { Ok } from 'ts-results-es'

const LanguageOutput = z.object({
    language: z
        .string()
        .describe('The ISO-639-2 language code of the input text'),
})
export type LanguageOutput = z.infer<typeof LanguageOutput>

export class LanguageDetection extends OpenAIExtractionStep<Input, Input> {
    static STEP_NAME = 'LanguageDetection'

    public constructor(context: Context) {
        super(
            context,
            LanguageDetection.STEP_NAME,
            LanguageOutput,
            new LanguageDetectionPrompt(),
            'gpt-4o-mini',
            0
        )
    }

    public async execute(input: Input): Promise<StepResult<Input>> {
        const res = await super.execute(input)
        if (res.isOk()) {
            // We tricked the abstraction by passing a LanguageOutput schema in the constructor
            const value = res.value as any as LanguageOutput
            const inferredLang = inferLanguage(
                value.language,
                this.context.logger
            )
            if (inferredLang) {
                this.context.detectedLanguage = inferredLang
            } else {
                this.context.logger.warn(
                    value.language,
                    'Language not supported, defaulting to English'
                )
                this.context.detectedLanguage = 'eng'
            }
        } else {
            return Err(res.error)
        }

        return Ok(input)
    }

    workUnits(): number {
        return 1
    }

    description(): string {
        return `Detecting language of input query`
    }
}

class LanguageDetectionPrompt extends OpenAIPrompt<Input> {
    systemPrompt(): string {
        return `You are an assistant specialized in language detection. Your task is to analyze text and determine its language.
Return only the ISO-639-2 three-letter language code (e.g. 'eng' for English, 'spa' for Spanish, etc.).
If the language cannot be determined, return 'und' for undefined.`
    }

    userPrompt(input: Input): string {
        return `Input: "${input.query}"${
            input.cohort ? ` "${input.cohort}"` : ''
        }`
    }
}
