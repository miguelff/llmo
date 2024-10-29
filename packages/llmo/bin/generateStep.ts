#!/usr/bin/env node

import { Command } from 'commander'
import * as fs from 'fs'
import * as path from 'path'

const program = new Command()

program
    .name('generate-step')
    .description('Generate a new LLM step from template')
    .requiredOption(
        '-n, --name <name>',
        'Name of the step (e.g. QuestionSynthesis)'
    )
    .action(async (options) => {
        const stepName = options.name

        // Convert to proper case if needed
        const className = stepName.charAt(0).toUpperCase() + stepName.slice(1)

        const template = `import { ChatCompletionMessageParam } from 'openai/resources/index.mjs'
import { z } from 'zod'
import { Context } from '../context'
import { OpenAIExtractionStep } from '../llmStep'

export class ${className} extends OpenAIExtractionStep<Input, Output> {
    static STEP_NAME = '${className}'

    static SYSTEM_MESSAGE: ChatCompletionMessageParam = {
        role: 'system',
        content: '' // TODO: Define system message prompt
    }

    public constructor(context: Context) {
        super(context, ${className}.STEP_NAME, Output, 'gpt-4o', 0)
    }

    createPrompt(input: Input): ChatCompletionMessageParam[] {
        // TODO: Implement prompt creation logic
        return [
            ${className}.SYSTEM_MESSAGE,
            {
                role: 'user',
                content: ''
            },
        ]
    }
}

const Input = z.object({
    // TODO: Define input schema
})
export type Input = z.infer<typeof Input>

const Output = z.object({
    // TODO: Define output schema
})
export type Output = z.infer<typeof Output>
`

        const outputPath = path.join(
            process.cwd(),
            'src',
            'steps',
            `${stepName.charAt(0).toLowerCase() + stepName.slice(1)}.ts`
        )

        if (fs.existsSync(outputPath)) {
            const readline = require('readline').createInterface({
                input: process.stdin,
                output: process.stdout,
            })

            const answer: any = await new Promise((resolve) => {
                readline.question(
                    `File ${outputPath} already exists. Overwrite? (y/N) `,
                    resolve
                )
            })

            readline.close()

            if (answer.toLowerCase() !== 'y') {
                console.log('Operation cancelled')
                return
            }
        }

        fs.writeFileSync(outputPath, template)
        console.log(`Generated step file at: ${outputPath}`)
    })

program.parse()
