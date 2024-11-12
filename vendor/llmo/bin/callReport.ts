#!/usr/bin/env node

import createContext from '../src/context'
import { Report } from '../src/steps/report'

async function main() {
    const data = require('./fixtures/cleaner.out.json')
    const context = createContext()
    context.input_arguments.query = 'coches baratos en españa'

    const result = await new Report(context).execute(data)
    console.log(result)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
