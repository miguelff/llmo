import { Application } from '@hotwired/stimulus'
// Attach ApexCharts to the window object
const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application

export { application }
