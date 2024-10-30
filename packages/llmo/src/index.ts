import { Input, QuestionSynthesis } from './steps/questionSynthesis'
import { QuestionExpansion } from './steps/questionExpansion'
import { QuestionFormulation } from './steps/questionFormulation'
import { AnswerAnalysis } from './steps/answerAnalysis'
import createContext from './context'
import { Command } from 'commander'
import { Cleaner } from './steps/cleaner'
import { Report } from './steps/report'
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
    context.bag['query'] = query

    const input: Input = { query, count }
    const result = await new QuestionSynthesis(context)
        .then(new QuestionExpansion(context))
        .then(new QuestionFormulation(context))
        .then(new AnswerAnalysis(context))
        .then(new Cleaner(context))
        .then(new Report(context))
        .execute(input)

    context.logger.info(result)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
