import { Logger, pino } from 'pino'
import PinoPretty from 'pino-pretty'
import e, { type env } from './env.js'
import { z } from 'zod'

export type DataBag = Record<string, any>

export const InputArguments = z.object({
    query: z.string(),
    count: z.number(),
    callback: z.string().optional(),
})

// TODO: rename to camelCase
export type Context = {
    logger: Logger
    env: env
    total_work_units: number
    processed_work_units: number
    bag: DataBag
    previous_answers: DataBag
    input_arguments: z.infer<typeof InputArguments>
}

export default function (): Context {
    return {
        logger: pino(
            { level: e.LOG_LEVEL },
            e.NODE_ENV === 'production' ? undefined : PinoPretty()
        ),
        env: e,
        bag: {},
        input_arguments: {
            query: '',
            count: 10,
            callback: undefined,
        },
        previous_answers: {},
        total_work_units: 0,
        processed_work_units: 0,
    }
}
