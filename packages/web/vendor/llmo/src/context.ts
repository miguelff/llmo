import { Logger, pino } from 'pino'
import PinoPretty from 'pino-pretty'
import e, { type env } from './env.js'

export type DataBag = Record<string, any>

export type Context = {
    logger: Logger
    env: env
    total_work_units: number
    processed_work_units: number
    bag: DataBag
}

export default function (): Context {
    return {
        logger: pino(
            { level: e.LOG_LEVEL },
            e.NODE_ENV === 'production' ? undefined : PinoPretty()
        ),
        env: e,
        bag: {},
        total_work_units: 0,
        processed_work_units: 0,
    }
}
