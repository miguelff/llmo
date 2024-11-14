import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context.js'
import { OpenAIExtractionStep, OpenAIPrompt, StepResult } from './abstract.js'
import { Err, Ok } from 'ts-results-es'
export class QuestionSynthesis extends OpenAIExtractionStep<Input, Output> {
    static STEP_NAME = 'Question Synthesis'

    public constructor(context: Context) {
        super(
            context,
            QuestionSynthesis.STEP_NAME,
            Output,
            new QuestionSynthesisPrompt(context),
            'gpt-4o-mini',
            0
        )
    }

    async execute(input: Input): Promise<StepResult<Output>> {
        const res = await super.execute(input)
        if (res.isErr()) {
            return Err(res.error)
        } else {
            const questions = res.value.questions
            if (questions.length > input.count) {
                return Ok({ questions: questions.slice(0, input.count) })
            } else {
                return Ok(res.value)
            }
        }
    }

    workUnits(): number {
        return 1
    }

    description(): string {
        return `Sampling queries from cohort`
    }
}

const Input = z.object({
    query: z.string(),
    count: z.number().optional().default(10),
    region: z.string().optional(),
    cohort: z.string().optional(),
})
export type Input = z.infer<typeof Input>

const Output = z.object({
    questions: z.array(z.string()),
})
export type Output = z.infer<typeof Output>

class QuestionSynthesisPrompt extends OpenAIPrompt<Input> {
    delegate(): OpenAIPrompt<Input> {
        return this.context!.detectedLanguage === 'spa'
            ? new SpanishPrompt()
            : new EnglishPrompt()
    }

    systemPrompt(): string {
        return this.delegate().systemPrompt()
    }
    userPrompt(input: Input): string {
        return this.delegate().userPrompt(input)
    }
}

class SpanishPrompt extends QuestionSynthesisPrompt {
    systemPrompt(): string {
        return `
    Eres un asistente especializado en simular el comportamiento de usuarios de ChatGPT que investigan las mejores marcas, productos o servicios. Tu tarea es generar variaciones en lenguaje natural de una consulta que busca entender los mejores productos dentro de una categoría.
Entradas:

	•	query: El principal producto, marca o servicio que el usuario está investigando.
	•	cohort: (Opcional) Una descripción de la persona que realiza la consulta, incluyendo detalles demográficos, preferencias o necesidades específicas. Usa esta información para adaptar el tono, enfoque y preocupaciones específicas de las preguntas.
	•	region: (Opcional) Un país o región mundial específica para restringir el alcance de productos, servicios o marcas. Úsalo para generar consultas que se alineen con la disponibilidad específica de la región, marcas populares o consideraciones locales.

Instrucciones:

	1.	Genera preguntas claras y directas cuyas respuestas apunten a marcas, modelos o servicios específicos relevantes para la consulta dada.
	2.	Si se proporciona el cohort, refleja los intereses, necesidades o prioridades del usuario en las preguntas. Por ejemplo:
	•	Un usuario consciente del presupuesto se centraría en opciones asequibles.
	•	Un usuario consciente del medio ambiente consideraría aspectos de sostenibilidad.
	3.	Si se proporciona la región, adapta las preguntas para centrarte en marcas, modelos o servicios populares o disponibles en esa región, incluyendo preferencias locales o consideraciones de precios.
	4.	Si falta información de cohort o región:
	•	No hagas suposiciones sobre la demografía, preferencias o ubicación del usuario.
	•	Genera preguntas neutrales y generales que no sean específicas de ningún cohort o región.
	5.	Mantén las preguntas específicas a la categoría de consulta dada, evitando temas tangenciales. Por ejemplo:
	•	Si la consulta es sobre seguros de hogar, no generes preguntas sobre seguros de salud.
	•	Si la consulta es sobre suplementos dietéticos, no te limites a subcategorías específicas a menos que se solicite explícitamente.
	6.	Mantén la diversidad en la formulación de preguntas mientras te mantienes fiel al contexto proporcionado por las entradas.

Ejemplos de Salidas:

Dados los inputs:

	•	query: "mejores cafeteras para casa"
	•	cohort: No proporcionado
	•	region: No proporcionado

Genera preguntas como:

	•	"¿Cuáles son las cafeteras para casa mejor valoradas en el mercado?"
	•	"¿Qué cafeteras se consideran las más fiables para uso doméstico?"
	•	"¿Qué factores debo considerar al elegir una cafetera para casa?"
	•	"¿Cuáles son las mejores marcas de cafeteras para casa disponibles ahora mismo?"

Si los inputs son:

	•	query: "mejores cafeteras para casa"
	•	cohort: "Un estudiante consciente del presupuesto que vive en un apartamento pequeño"
	•	region: "Europa"

Genera preguntas como:

	•	"¿Cuáles son las cafeteras para casa más asequibles disponibles en Europa?"
	•	"¿Qué marcas de cafeteras son mejores para espacios pequeños y presupuestos de estudiantes?"
	•	"¿Hay cafeteras económicas que sean populares en los mercados europeos?"
	•	"¿Cuáles son las cafeteras compactas mejor valoradas para apartamentos pequeños en Europa?"

Tu objetivo es generar preguntas que reflejen la intención y el contexto del usuario, llevando a recomendaciones específicas de productos o marcas basadas en los inputs proporcionados.`
    }

    userPrompt(input: Input): string {
        return `Por favor genera ${input.count} preguntas sobre "${
            input.query
        }".
${
    input.region
        ? `\nContexto regional: Las preguntas deben estar adaptadas para ${input.region}, considerando la existencia de productos, marcas y servicios en esta región`
        : ''
}
${
    input.cohort
        ? `\nContexto del usuario: Las preguntas deben ser relevantes para ${input.cohort}.`
        : ''
}
Sigue estas pautas:
- Mantén las preguntas enfocadas específicamente en ${input.query}
- ${
            input.region || input.cohort
                ? 'Adapta las preguntas al contexto regional proporcionado'
                : 'Genera preguntas neutrales sin suposiciones demográficas o regionales'
        }
- Varía la formulación manteniendo la relevancia
- Enfócate en recopilar información que ayude a recomendar productos/marcas específicos

Preguntas:`
    }
}

class EnglishPrompt extends QuestionSynthesisPrompt {
    systemPrompt(): string {
        return `
    You are an assistant specialized in simulating the behavior of ChatGPT users researching the best brands, products, or services. Your task is to generate natural language variations of a query that seeks to understand the best products within a category.
Inputs:

	•	query: The main product, brand, or service the user is researching.
	•	cohort: (Optional) A description of the person making the query, including demographic details, preferences, or specific needs. Use this information to tailor the tone, focus, and specific concerns of the questions.
	•	region: (Optional) A specific country or world region to restrict the scope of products, services, or brands. Use this to generate queries that align with region-specific availability, popular brands, or local considerations.

Instructions:

	1.	Generate clear and direct questions whose answers point to specific brands, models, or services relevant to the given query.
	2.	If the cohort is provided, reflect the interests, needs, or priorities of the user in the questions. For example:
	•	A budget-conscious user would focus on affordable options.
	•	An eco-conscious user would consider sustainability aspects.
	3.	If the region is provided, tailor the questions to focus on brands, models, or services popular or available in that region.
	4.	If cohort or region information is missing:
	•	Do not make assumptions about the user’s demographic, preferences, or location.
	•	Generate neutral, general questions that are not specific to any cohort or region.
	5.	Keep the questions specific to the given query category, avoiding tangential topics. For example:
	•	If the query is about home insurance, do not generate questions about health insurance.
	•	If the query is about dietary supplements, do not narrow down to specific subcategories unless explicitly requested.
	6.	Maintain diversity in question phrasing while staying true to the context provided by the inputs.

Example Outputs:

Given the inputs:

	•	query: “best home coffee machines”
	•	cohort: Not provided
	•	region: Not provided

Generate questions like:

	•	“What are the best-rated home coffee machines on the market?”
	•	“Which coffee machines are considered the most reliable for home use?”
	•	“What factors should I consider when choosing a home coffee machine?”
	•	“What are the top home coffee machine brands available right now?”

If the inputs are:

	•	query: “best home coffee machines”
	•	cohort: “A budget-conscious student living in a small apartment”
	•	region: “Europe”

Generate questions like:

	•	“What are the most affordable home coffee machines available in Europe?”
	•	“Which coffee machine brands are best for small spaces and student budgets?”
	•	“Are there any budget-friendly coffee machines popular in European markets?”
	•	“What are the top-rated compact coffee makers for small apartments in Europe?”

Your goal is to generate questions that reflect the user’s intent and context, leading to specific product or brand recommendations based on the inputs provided.
Generate the questions following the structured output format.
`
    }

    userPrompt(input: Input): string {
        return `Please generate ${input.count} questions about "${input.query}".
${
    input.region
        ? `\nRegion context: The questions should be tailored for ${input.region}, considering local preferences, pricing, and availability.`
        : ''
}
${
    input.cohort
        ? `\nUser context: The questions should be relevant for ${input.cohort}.`
        : ''
}
Follow these guidelines:
- Keep questions focused specifically on ${input.query}
- ${
            input.region || input.cohort
                ? 'Tailor questions to the provided context'
                : 'Generate neutral questions without demographic or regional assumptions'
        }
- Vary the phrasing while maintaining relevance
- Focus on gathering information that will help recommend specific products/brands

Questions:`
    }
}
