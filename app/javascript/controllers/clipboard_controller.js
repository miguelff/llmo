import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static values = {
        text: String,
        successMessage: String,
    }

    async copy(event) {
        event.preventDefault()

        try {
            await navigator.clipboard.writeText(this.textValue)

            // Create and show toast notification
            const toast = document.createElement('div')
            toast.className =
                'fixed bottom-4 left-1/2 -translate-x-1/2 bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-white px-6 py-3 rounded-lg shadow-lg'
            toast.textContent = this.successMessageValue
            document.body.appendChild(toast)

            // Remove toast after 2 seconds
            setTimeout(() => {
                toast.remove()
            }, 2000)
        } catch (err) {
            console.error('Failed to copy text:', err)
        }
    }
}
