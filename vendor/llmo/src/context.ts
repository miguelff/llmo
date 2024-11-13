import { Logger, pino } from 'pino'
import PinoPretty from 'pino-pretty'
import e, { type env } from './env.js'
import { z } from 'zod'

export type DataBag = Record<string, any>

export const InputArguments = z.object({
    query: z.string(),
    count: z.number(),
    callback: z.string().optional(),
    region: z.string().optional(),
    brand_info: z.string().optional(),
    cohort: z.string().optional(),
})

// TODO: rename to camelCase
export type Context = {
    logger: Logger
    env: env
    totalWorkUnits: number
    processedWorkUnits: number
    bag: DataBag
    previousAnswers: DataBag
    inputArguments: z.infer<typeof InputArguments>
}

export default function (): Context {
    return {
        logger: pino(
            { level: e.LOG_LEVEL },
            e.NODE_ENV === 'production' ? undefined : PinoPretty()
        ),
        env: e,
        bag: {},
        inputArguments: {
            query: '',
            count: 10,
            callback: undefined,
        },
        previousAnswers: {},
        totalWorkUnits: 0,
        processedWorkUnits: 0,
    }
}
