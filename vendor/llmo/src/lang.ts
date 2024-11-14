import { Logger } from 'pino'

// ISO-639-2 three-letter language code
export const SUPPORTED_LANGUAGES = ['spa', 'eng'] as const
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number]

export function inferLanguage(
    text: string,
    logger: Logger | undefined
): SupportedLanguage | undefined {
    const lowercaseText = text.toLowerCase()
    const detectedLanguage = SUPPORTED_LANGUAGES.find((lang) =>
        lowercaseText.includes(lang)
    )
    logger?.debug({ detectedLanguage }, 'Inferred language from text')
    return detectedLanguage
}

export function localizedLanguageName(language: SupportedLanguage): string {
    switch (language) {
        case 'spa':
            return 'Español'
        case 'eng':
            return 'English'
    }
}

export function englishLanguageName(language: SupportedLanguage): string {
    switch (language) {
        case 'spa':
            return 'Spanish'
        case 'eng':
            return 'English'
    }
}
