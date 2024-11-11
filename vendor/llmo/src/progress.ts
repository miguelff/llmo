import { Context } from './context.js'

export async function submitProgress(
    context: Context,
    message: string | undefined = undefined
) {
    const webhook = context.bag['callback']
    const result = JSON.stringify(context.bag['result'])

    if (webhook) {
        const payload = {
            report: {
                percentage: Math.round(
                    (context.processed_work_units / context.total_work_units) *
                        100
                ),
                message,
                result,
            },
        }
        try {
            await fetch(webhook, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(payload),
            })
        } catch (error) {
            context.logger.error('Failed to submit progress:', error)
        }
    }
}
