import { Input, QuestionSynthesis } from './steps/questionSynthesis'
import { QuestionExpansion } from './steps/questionExpansion'
import createContext, { Context } from './context'

async function main() {
    const context = createContext()

    const input: Input = { query: 'coche seguro', count: 10 }
    const result = await run(input, context)
    context.logger.info(result)
}

function run(input: Input, context: Context) {
    return new QuestionSynthesis(context)
        .then(new QuestionExpansion(context))
        .execute(input)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
