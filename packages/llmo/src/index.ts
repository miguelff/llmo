import { Input, QuestionSynthesis } from './steps/questionSynthesis.js'
import { QuestionExpansion } from './steps/questionExpansion.js'
import { QuestionFormulation } from './steps/questionFormulation.js'
import { AnswerAnalysis } from './steps/answerAnalysis.js'
import createContext from './context.js'
import { Command } from 'commander'
import { Cleaner } from './steps/cleaner.js'
import { Report } from './steps/report.js'
import { submitProgress } from './progress.js'
async function main() {
    const program = new Command()

    program
        .command('report')
        .description('Generate and analyze questions')
        .requiredOption('-q, --query <query>', 'Search query to analyze')
        .requiredOption(
            '-c, --callback <url>',
            'Callback URL to send progress updates to'
        )
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

export async function report(options: {
    callback: string
    query: string
    count: string
}) {
    const callback = options.callback
    const query = options.query
    const count = parseInt(options.count)

    const context = createContext()
    context.bag['count'] = count
    context.bag['query'] = query
    context.bag['callback'] = callback

    const pipeline = new QuestionSynthesis(context)
        .then(new QuestionExpansion(context))
        .then(new QuestionFormulation(context))
        .then(new AnswerAnalysis(context))
        .then(new Cleaner(context))
        .then(new Report(context))

    context.total_work_units = pipeline.workUnits()
    context.logger.info(`Total work units: ${context.total_work_units}`)

    const input: Input = { query, count }
    const result = await pipeline.execute(input)

    context.bag['result'] = result
    context.processed_work_units = context.total_work_units
    await submitProgress(context, 'Report completed')

    context.logger.info(result)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
