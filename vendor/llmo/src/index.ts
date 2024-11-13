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
        .requiredOption('-q, --query <query>', 'Search query to analyze')
        .option('-C, --cohort <cohort>', 'Cohort to analyze')
        .option('-b, --brand_info <brand_info>', 'Brand or product to analyze')
        .option(
            '-r, --region <region>',
            'Perform analysis for a specific region'
        )
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
    region: string
    brand_info: string
    cohort: string
}) {
    const callback = options.callback
    const query = options.query
    const count = parseInt(options.count)
    const region = options.region
    const brand_info = options.brand_info
    const cohort = options.cohort

    const context = createContext()
    context.inputArguments = {
        query,
        count,
        region,
        brand_info,
        cohort,
        callback,
    }

    const pipeline = new QuestionSynthesis(context)
        .then(new QuestionExpansion(context))
        .then(new QuestionFormulation(context))
        .then(new AnswerAnalysis(context))

    context.totalWorkUnits = pipeline.workUnits()
    context.logger.info(`Total work units: ${context.totalWorkUnits}`)

    const input: Input = { query, count, region, cohort }
    context.logger.info(input, 'Pipeline input')
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
