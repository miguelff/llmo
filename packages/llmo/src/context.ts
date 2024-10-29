import { Context as OriginalContext } from 'common/src/pipeline'
import pino from 'pino'
import PinoPretty from 'pino-pretty'
import e, { type env } from './env'

export type DataBag = Record<string, any>

export type Context = OriginalContext & {
    env: env
    bag: DataBag
}

export default function (): Context {
    return {
        logger: pino(
            { level: e.LOG_LEVEL },
            e.NODE_ENV === 'production' ? undefined : PinoPretty()
        ),
        mustHalt: () => false,
        env: e,
        bag: {},
    }
}
