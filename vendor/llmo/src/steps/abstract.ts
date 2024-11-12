import fs from 'fs'
import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import path from 'path'
import { Logger } from 'pino'
import { Err, Ok, Result } from 'ts-results-es'
import { z } from 'zod'
import { Context } from '../context.js'
import { OpenAIModel } from '../llm.js'
import { submitProgress } from '../progress.js'

export type Error = { cause: Error | string; step: string }
export type StepResult<T> = Result<T, Error>

/**
 * A step in a pipeline
 *
 * @param I The type of the input object that is passed to the pipeline
 * @param O The type of the output object that is passed to the next step in the pipeline
 * @param C The type of the context object that is passed to each step in the pipeline
 */
export abstract class ExtractionStep<I, O, C extends Context> {
    protected logger: Logger

    constructor(protected context: C, public descriptor: string) {
        this.logger = this.context.logger.child({ step: descriptor })
    }

    abstract execute(input: I): Promise<StepResult<O>>

    description(): string | undefined {
        return undefined
    }

    workUnits(): number {
        return 0
    }

    then<Next>(next: ExtractionStep<O, Next, C>): ExtractionStep<I, Next, C> {
        return new Sequence(this.context, this, next)
    }

    withLogs(
        fileGenerator: (i: I) => string,
        contentGenerator: (o: StepResult<O>) => any = (o: StepResult<O>) =>
            o.unwrap()
    ): ExtractionStep<I, O, C> {
        return new Recording(
            this.context,
            this,
            fileGenerator,
            contentGenerator
        )
    }

    /**
     * Hooks
     */

    beforeStart() {
        submitProgress(this.context, this.description())
    }

    beforeInvoke(prompt: ChatCompletionMessageParam[]) {}

    afterInvoke(result: Result<O, string>) {
        this.context.processedWorkUnits++
        submitProgress(this.context)
    }

    afterEnd(result: StepResult<O>) {
        this.context.previousAnswers[this.descriptor] = result
    }
}

/**
 * A step that executes a sequence of steps
 */
export class Sequence<I, X, O, C extends Context> extends ExtractionStep<
    I,
    O,
    C
> {
    constructor(
        protected context: C,
        private head: ExtractionStep<I, X, C>,
        private tail: ExtractionStep<X, O, C>
    ) {
        super(context, head.descriptor)
    }

    async execute(input: I): Promise<StepResult<O>> {
        const headResult = await this.head.execute(input)
        if (headResult.isOk()) {
            const tailInput = headResult.value
            return await this.tail.execute(tailInput)
        } else {
            return Err(headResult.error)
        }
    }

    workUnits(): number {
        return this.head.workUnits() + this.tail.workUnits()
    }
}

/**
 * A step that records the output of a previous step
 */
export class Recording<I, O, C extends Context> extends ExtractionStep<
    I,
    O,
    C
> {
    constructor(
        protected context: C,
        private prev: ExtractionStep<I, O, C>,
        private fileNameGenerator: (i: I) => string,
        private contentGenerator: (o: StepResult<O>) => any
    ) {
        super(context, `recording(${prev.descriptor})`)
    }

    async execute(input: I): Promise<StepResult<O>> {
        const res = await this.prev.execute(input)

        const file = this.fileNameGenerator(input)
        const targetDir = path.dirname(file)
        try {
            await fs.mkdirSync(targetDir, { recursive: true })
        } catch (err) {
            /**/
        }

        fs.writeFileSync(
            file,
            JSON.stringify(this.contentGenerator(res), null, 2)
        )

        this.logger.info(`💾 ${file} saved`)

        return res
    }
}

export const models = {
    openai: OpenAIModel,
}

export abstract class OpenAIExtractionStep<I, O> extends ExtractionStep<
    I,
    O,
    Context
> {
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
        this.beforeStart()
        const logger = this.context.logger
        const prompt = this.createPrompt(input)
        this.beforeInvoke(prompt)
        const res = await this.model.invoke(prompt, logger)
        this.afterInvoke(res)

        var result: StepResult<O>

        if (res.isOk()) {
            const parsed = this.outputSchema.safeParse(res.value)
            if (parsed.error) {
                result = Err({
                    cause: parsed.error.message,
                    step: this.descriptor,
                })
            } else {
                result = Ok(parsed.data as O)
            }
        } else {
            result = Err({
                cause: 'There was an error invoking the model',
                step: this.descriptor,
            })
        }

        try {
            this.afterEnd(result)
        } catch (err) {
            this.logger.error(err, 'Error after end')
        }

        return result
    }

    abstract createPrompt(input: I): ChatCompletionMessageParam[]
}

export abstract class MapperStep<I, O, C> extends ExtractionStep<
    I,
    O[],
    Context
> {
    protected innerStep: ExtractionStep<C, O, Context>

    constructor(
        context: Context,
        descriptor: string,
        innerStep: ExtractionStep<C, O, Context>
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
            if (!result.isOk()) {
                return result
            }
            results.push(result.value)
        }

        return Ok(results)
    }
}
