import { Input, QuestionSynthesis } from './steps/questionSynthesis.js'
import { QuestionExpansion } from './steps/questionExpansion.js'
import { AnswerAnalysis } from './steps/answerAnalysis.js'
import createContext from './context.js'
import { Command } from 'commander'
import { submitProgress } from './progress.js'
import { QuestionFormulation } from './steps/questionFormulation.js'

async function main() {
    const program = new Command()

    program
        .command('report')
        .description('Generate and analyze questions')
        .option('-q, --query <query>', 'Search query to analyze')
        .option(
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
    const count = 1 // parseInt(options.count)

    const context = createContext()
    context.inputArguments = {
        query,
        count,
        callback,
    }

    const pipeline = new QuestionSynthesis(context)
        .then(new QuestionExpansion(context))
        .then(new QuestionFormulation(context))
        .then(new AnswerAnalysis(context))

    context.totalWorkUnits = pipeline.workUnits()
    context.logger.info(`Total work units: ${context.totalWorkUnits}`)

    const input: Input = { query, count }
    const result = await pipeline.execute(input)

    context.bag['result'] = result
    context.processedWorkUnits = context.totalWorkUnits
    await submitProgress(context, 'Report completed')

    context.logger.info(result)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
