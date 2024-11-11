import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Ok } from 'ts-results-es'

import { ChatPromptTemplate } from '@langchain/core/prompts'
import { createToolCallingAgent } from 'langchain/agents'
import { AgentExecutor } from 'langchain/agents'
import { BingSerpAPI } from '@langchain/community/tools/bingserpapi'
import { ChatOpenAI } from '@langchain/openai'
import env from '../src/env'
import createContext from '../src/context'
import { create } from 'domain'

async function main() {
    const context = createContext()
    context.logger.info(context.env, 'Starting')

    const llm = new ChatOpenAI({
        model: 'gpt-4o-mini',
        temperature: 0,
    })

    // BingApiKey env
    const searchTool = new BingSerpAPI()

    const tools = [searchTool]

    const prompt = ChatPromptTemplate.fromMessages([
        [
            'system',
            'Eres un agente especializado en comparación de empresas/marcas y productos/servicios y en ayudar a los usuarios a tomar decisiones',
        ],
        ['placeholder', '{chat_history}'],
        ['human', '{input}'],
        ['placeholder', '{agent_scratchpad}'],
    ])

    const agent = createToolCallingAgent({
        llm,
        tools,
        prompt,
    })
    const agentExecutor = new AgentExecutor({
        agent,
        tools,
    })

    const result = await agentExecutor.invoke({
        input: '¿Cuáles son las marcas de relojes de lujo más prestigiosas?. Busca información en la web para respaldar la información proporcionada. Incluye links que estén activos para respaldar la información proporcionada. A ser posible reviews en blogs o webs especializadas No halucines URLs, si no las hay, no las inventes.',
    })

    context.logger.info(result, 'Result')
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
