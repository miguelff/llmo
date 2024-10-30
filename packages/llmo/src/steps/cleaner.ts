import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context'
import { type Output as Input } from './answerAnalysis'
import { Err, ExtractionStep, Ok, StepResult, models } from './abstract'
import { OpenAIModel } from '../llm'

type Output = Input & { discards: IrrelevantTopicsOutput }

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
                content: `Extrae el concepto principal de la consulta del usuario. Un sólo término. Generalmente es un nombre de marca/producto/servicio/categoría ampliada a un concepto más amplio (hiperónimo).  Consulta original: ${this.context.bag['query']}`,
            },
        ]

        this.context.logger.debug(conceptPrompt, 'Prompting LLM (1/2)')

        const concept = await this.topicAbstractionModel.invoke(
            conceptPrompt as ChatCompletionMessageParam[],
            this.context.logger
        )

        if (!concept.ok) {
            return Err({
                step: Cleaner.STEP_NAME,
                cause: concept.val,
            })
        }

        const prompt = [
            {
                role: 'user',
                content: `Analiza la siguiente lista de temas y la consulta del usuario. 

Identifica los temas que son "cisnes negros" - es decir, temas que no encajan con el resto o no son relevantes para el concepto principal proporcionado.

Para ello identifica los temas que no encajan con ese concepto:

Concepto principal: "${concept.val.concept}"

Temas:
${input.topics.map((t) => `- ${t.name}`).join('\n')}

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

        if (res.ok) {
            const output = input as Output
            output.topics = output.topics.filter(
                (topic) =>
                    !res.val.list.some((t) => t.theme.includes(topic.name))
            )
            output.discards = res.val
            return Ok(output)
        } else {
            return Err({
                step: Cleaner.STEP_NAME,
                cause: res.val,
            })
        }
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
                    theme: z
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
