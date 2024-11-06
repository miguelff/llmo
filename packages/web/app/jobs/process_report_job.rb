class ProcessReportJob < ApplicationJob
  queue_as :default

  def perform(report)
    total_count.times do |i|
      sleep rand
      Turbo::StreamsChannel.broadcast_replace_to(
        ["heavy_task_channel"],
        target: "heavy_task",
        partial: "reports/progress",
        locals: {
          progress: (i + 1) * 100 / total_count
        }
      )
    end
    # sleep 1
    # report.processing!
    # Turbo::StreamsChannel.broadcast_to "foo", action: :replace, target: "report-status-#{report.id}", partial: "reports/status", locals: { report: report }
    # sleep 1
    # report.completed!
    # Turbo::StreamsChannel.broadcast_to "foo", action: :replace, target: "report-status-#{report.id}", partial: "reports/status", locals: { report: report }
  end

  def total_count
    @total_count ||= rand(10..100)
  end
end
