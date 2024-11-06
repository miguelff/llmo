class ProcessReportJob < ApplicationJob
  queue_as :default

  def perform(report)
    sleep 1
    report.processing!
    refresh_report_status(report, "Generating queries", 0)
    sleep 1
    refresh_report_status(report, "Generating queries", 5)
    sleep 2
    refresh_report_status(report, "Generating queries", 10)
    sleep 3
    refresh_report_status(report, "Generating queries", 30)
    sleep 4
    refresh_report_status(report, "Performing query analysis", 50)
    sleep 4
    refresh_report_status(report, "Generating insights", 80)
    sleep 2
    refresh_report_status(report, "Generating insights", 90)
    sleep 1
    report.completed!
    refresh_report_status(report, "Report generated successfully", 100)
  end

  def refresh_report_status(report, feedback, progress)
       Turbo::StreamsChannel.broadcast_replace_to(
        report,
        target: "report-status",
        partial: "reports/status",
        locals: {
          report: report,
          feedback: feedback,
          progress: progress,
        })
  end
end
