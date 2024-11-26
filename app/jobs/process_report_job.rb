require "open3"

class ProcessReportJob < ApplicationJob
  queue_as :default

  def perform(report)
    report.processing!
    # report_url = Rails.application.routes.url_helpers.report_url(report, protocol: "http", host: "127.0.0.1:3000", format: :json)



    # node_script = Rails.root.join("vendor/llmo/dist/index.js").to_s
    # query = report.query
    # count = 30

    # command = [ "node", node_script, "report", "--query", query, "--callback", report_url, "--count", count.to_s ]
    # command += [ "--cohort", report.cohort ] if report.cohort.present?
    # command += [ "--brand_info", report.brand_info ] if report.brand_info.present?
    # command += [ "--region", report.region ] if report.region.present?

    # Rails.logger.info "[Report #{report.id}] Running command: #{command.join(' ')}"

    # env = Rails.application.credentials.processor.stringify_keys
    # env["LOG_LEVEL"] ||= "info"

    # log, status = Open3.capture2e(env, *command)

    # Rails.logger.info "[Report #{report.id}] Execution log:\n#{log}"

    # TODO store logs with active storage

    if status.success?
      Rails.logger.info "[Report #{report.id}] Command executed successfully!"
      report.completed!
    else
      Rails.logger.error "[Report #{report.id}] Command failed with status: #{status.exitstatus}"
      report.failed!
    end
  rescue => e
    Rails.logger.error "[Report #{report.id}] Error processing report: #{e.message}"
    report.failed!
  end
end
