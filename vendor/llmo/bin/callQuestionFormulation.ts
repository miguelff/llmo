import { z } from 'zod'
import { searchBing } from '../src/search'
import createContext from '../src/context'
import { QuestionFormulationWithSearch } from '../src/steps/queryFormulationWithSearch'

async function main() {
    const context = createContext()

    const res = await new QuestionFormulationWithSearch(context).execute({
        questions: ['que reloj de lujo es el mejor'],
    })
    console.log(res)
}

main().catch((error) => {
    console.error('Failed to execute:', error)
    process.exit(1)
})
