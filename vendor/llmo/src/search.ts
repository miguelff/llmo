import { Context } from './context.js'

export async function searchBing(
    context: Context,
    query: string,
    count: number
) {
    const apiKey = context.env.BingApiKey

    try {
        const response = await fetch(
            `https://api.bing.microsoft.com/v7.0/search?q=${encodeURIComponent(
                query
            )}&count=${count}&mkt=en-us`,
            {
                headers: {
                    'Ocp-Apim-Subscription-Key': apiKey,
                },
            }
        )

        if (!response.ok) {
            context.logger.error(
                { status: response.status },
                'error searching bing'
            )
            return []
        }

        const data = await response.json()
        return data?.webPages?.value
    } catch (error) {
        context.logger.error(error, 'error searching bing')
        throw error
    }
}
