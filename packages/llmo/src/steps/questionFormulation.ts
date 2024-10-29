import { Step, StepResult } from 'common/src/pipeline'
import { Ok } from 'ts-results'
import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context'
import { type Output as Input } from './questionExpansion'
import { OpenAIModel } from '../llmStep'

export class QuestionFormulation extends Step<Input, Output, Context> {
    static STEP_NAME = 'Question Formulation'
    private model: OpenAIModel<string>

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content:
            'Eres un agente especializado en comparación de empresas/marcas y productos/servicios y en ayudar a los usuarios a tomar decisiones',
    }

    public constructor(context: Context) {
        super(context, QuestionFormulation.STEP_NAME)
        this.model = OpenAIModel.fromEnv(context.env)
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        const output: Record<string, string> = {}
        for (const question of input.questions) {
            const prompt = this.createPrompt(question)
            try {
                const res = await this.model.invoke(prompt, this.logger)
                if (res.ok) {
                    output[question] = res.val
                    this.logger.info(
                        { question, answer: res.val },
                        'question answered'
                    )
                } else {
                    this.logger.error(
                        res.val,
                        `error asking model for question ${question}, skipping.`
                    )
                }
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
}

const Output = z.record(z.string()).describe('Preguntas y Respuestas')
export type Output = z.infer<typeof Output>
