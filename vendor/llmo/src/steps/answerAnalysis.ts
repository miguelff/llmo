import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { Ok, Err } from 'ts-results-es'
import { StepResult, ExtractionStep } from './abstract.js'
import { type Output as QuestionFormulationOutput } from './questionFormulation.js'
import {
    Output as BrandsAndLinksOutput,
    BrandsAndLinks,
} from './answerAnalysis/brandsAndLinks.js'
import { Leaders, Output as LeadersOutput } from './answerAnalysis/leaders.js'

const Output = z.object({
    brandsAndLinks: BrandsAndLinksOutput,
    leaders: LeadersOutput,
})
export type Output = z.infer<typeof Output>

export class AnswerAnalysis extends ExtractionStep<
    QuestionFormulationOutput,
    Output,
    Context
> {
    static STEP_NAME = 'AnswerAnalysis'
    static MODEL = 'gpt-4o'

    private brandsAndLinks: BrandsAndLinks
    private leaders: Leaders

    public constructor(context: Context) {
        super(context, AnswerAnalysis.STEP_NAME)
        this.brandsAndLinks = new BrandsAndLinks(context, AnswerAnalysis.MODEL)
        this.leaders = new Leaders(context, AnswerAnalysis.MODEL)
    }

    async execute(
        input: QuestionFormulationOutput
    ): Promise<StepResult<Output>> {
        const result: any = {}

        this.beforeStart()
        const brandsAndLinks = await this.brandsAndLinks.execute(input)
        if (brandsAndLinks.isErr()) {
            return Err(brandsAndLinks.error)
        } else {
            result.brandsAndLinks = brandsAndLinks.value
        }

        const leaders = await this.leaders.execute(brandsAndLinks.value)
        if (leaders.isErr()) {
            return Err(leaders.error)
        } else {
            result.leaders = leaders.value.leaders
        }

        return Ok(result)
    }

    workUnits(): number {
        return this.brandsAndLinks.workUnits()
    }

    description(): string {
        return `Analyzing LLM answers`
    }
}
