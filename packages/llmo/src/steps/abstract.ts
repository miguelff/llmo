import { Step, StepResult as BaseStepResult, Error } from 'common/src/pipeline'
import { z } from 'zod'
import { Context } from '../context'
import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { OpenAIModel } from '../llm'
import { Ok as BaseOk, Err as BaseErr } from 'ts-results'

export type StepResult<T> = BaseStepResult<T>
export function Ok<T>(val: T) {
    return BaseOk(val)
}

export function Err<T>(err: Error) {
    return BaseErr(err)
}

export const ExtractionStep = Step

export const models = {
    openai: OpenAIModel,
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
            outputSchema,
            modelName,
            temperature
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
