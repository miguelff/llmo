class ProcessReportJob < ApplicationJob
  queue_as :default

  def perform(report)
    report.processing!
    report_url = Rails.application.routes.url_helpers.report_url(report, host: "127.0.0.1:3000", format: :json)

    node_script = Rails.root.join("vendor/llmo/dist/index.js").to_s
    query = report.query
    count = case report.advanced_settings&.dig("exhaustiveness")&.to_sym || :brief
    when :brief then 5
    when :standard then 10
    when :thorough then 30
    end

    command = [ "node", node_script, "report", "--query", query, "--callback", report_url, "--count", count.to_s ]
    Rails.logger.info "Running command: #{command.join(' ')}"

    if system(Rails.application.credentials.processor.stringify_keys, *command)
      report.completed!
    else
      report.failed!
    end
  rescue => e
    Rails.logger.error "Error processing report: #{e.message}"
    report.failed!
  end
end
