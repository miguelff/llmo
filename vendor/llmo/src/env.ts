/* eslint-disable node/no-process-env */
import { config } from 'dotenv'
import { expand } from 'dotenv-expand'
import path from 'node:path'
import { pino } from 'pino'
import pretty from 'pino-pretty'
import { z } from 'zod'

expand(
    config({
        path: path.resolve(
            process.cwd(),
            process.env.NODE_ENV === 'test' ? '.env.test' : '.env'
        ),
    })
)

const EnvSchema = z
    .object({
        OPENAI_API_KEY: z.string(),
        BingApiKey: z.string(),
        NODE_ENV: z.string().default('development'),
        LOG_LEVEL: z
            .enum([
                'fatal',
                'error',
                'warn',
                'info',
                'debug',
                'trace',
                'silent',
            ])
            .default('info'),
    })
    .superRefine((input, ctx) => {
        const logger = pino(
            { level: input.LOG_LEVEL },
            input.NODE_ENV === 'production' ? undefined : pretty()
        )
    })

export type env = z.infer<typeof EnvSchema>

// eslint-disable-next-line ts/no-redeclare
const { data: env, error } = EnvSchema.safeParse(process.env)

if (error) {
    console.error('❌ Invalid env:')
    console.error(JSON.stringify(error, null, 2))
    process.exit(1)
}

export default env!
