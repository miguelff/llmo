import { Input, QuestionSynthesis } from './steps/questionSynthesis'
import { QuestionExpansion } from './steps/questionExpansion'
import createContext from './context'
import { Command } from 'commander'

async function main() {
    const program = new Command()

    program
        .command('report')
        .description('Generate and analyze questions')
        .requiredOption('-q, --query <query>', 'Search query to analyze')
        .option(
            '-n, --count <count>',
            'Number of seed questions to generate',
            '10'
        )
        .action(async (options) => {
            await report(options)
        })

    await program.parseAsync()
}

export async function report(options: { query: string; count: string }) {
    const query = options.query
    const count = parseInt(options.count)

    const context = createContext()
    const input: Input = { query, count }
    const result = await new QuestionSynthesis(context)
        .then(new QuestionExpansion(context))
        .execute(input)

    context.logger.info(result)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
