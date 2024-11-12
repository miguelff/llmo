import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { type Output as Input } from './answerAnalysis.js'
import { ExtractionStep, StepResult, models } from './abstract.js'
import { Ok, Err } from 'ts-results-es'
import { OpenAIModel } from '../llm.js'

export type Output = Input & { discards: IrrelevantTopicsOutput }

export class Cleaner extends ExtractionStep<Input, Output, Context> {
    static STEP_NAME = 'Cleaner'
    private topicAbstractionModel: OpenAIModel<ConceptAbstractionOutput>
    private irrelevantExtractionModel: OpenAIModel<IrrelevantTopicsOutput>

    public constructor(context: Context) {
        super(context, Cleaner.STEP_NAME)
        this.irrelevantExtractionModel = models.openai.fromEnv(
            context.env,
            IrrelevantTopicsOutput
        )
        this.topicAbstractionModel = models.openai.fromEnv(
            context.env,
            z.object({
                concept: z.string(),
            })
        )
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        const conceptPrompt = [
            {
                role: 'user',
                content: `Extrae el concepto principal de la consulta del usuario. Una sola palabra. Consulta original: ${this.context.inputArguments.query}`,
            },
        ]

        this.context.logger.debug(conceptPrompt, 'Prompting LLM (1/2)')

        const concept = await this.topicAbstractionModel.invoke(
            conceptPrompt as ChatCompletionMessageParam[],
            this.context.logger
        )

        if (concept.isErr()) {
            return Err({
                step: Cleaner.STEP_NAME,
                cause: concept.error,
            })
        }

        const prompt = [
            {
                role: 'user',
                content: `Analiza la siguiente lista de temas y la consulta del usuario. 

Identifica los temas que son "cisnes negros" - es decir, temas que no encajan con el resto o no son relevantes para el concepto principal proporcionado.

Para ello identifica los temas que no encajan con ese concepto:

Concepto principal: "${concept.value.concept}"

Temas:
${input.brandsAndLinks.topics.map((t) => `- ${t.name}`).join('\n')}

Devuelve solo los temas que NO son relevantes para la consulta. Por ejemplo, si la consulta es sobre ropa y hay un tema "Good on you", ese tema debería incluirse en la lista de irrelevantes ya que a diferencia del resto, no es una marca o modelo de ropa, si no una organización que evalúa la sostenibilidad de las marcas.

Responde SOLO con la lista de temas irrelevantes, sin explicaciones adicionales.
`,
            },
        ]

        this.context.logger.debug(prompt, 'Prompting LLM (2/2)')

        const res = await this.irrelevantExtractionModel.invoke(
            prompt as ChatCompletionMessageParam[],
            this.context.logger
        )

        if (res.isOk()) {
            const output = input as Output
            output.brandsAndLinks.topics = output.brandsAndLinks.topics.filter(
                (topic) =>
                    !res.value.list.some((t) => t.topic.includes(topic.name))
            )
            output.discards = res.value
            return Ok(output)
        } else {
            return Err({
                step: Cleaner.STEP_NAME,
                cause: res.error,
            })
        }
    }

    workUnits(): number {
        return 2
    }

    description(): string {
        return `Performing grounding and filtering outlier information`
    }
}

const ConceptAbstractionOutput = z.object({
    concept: z.string().describe('El concepto principal'),
})
type ConceptAbstractionOutput = z.infer<typeof ConceptAbstractionOutput>

const IrrelevantTopicsOutput = z
    .object({
        list: z
            .array(
                z.object({
                    topic: z
                        .string()
                        .describe('El nombre del tema que no es relevante'),
                    explanation: z
                        .string()
                        .describe(
                            'La explicación de por qué ese tema no es relevante para la consulta'
                        ),
                })
            )
            .describe(
                'Una lista con las temas que no guardan tanta relación semántica entre el resto consulta, con la explicación de porqué'
            ),
    })
    .extend(ConceptAbstractionOutput.shape)

export type IrrelevantTopicsOutput = z.infer<typeof IrrelevantTopicsOutput>
