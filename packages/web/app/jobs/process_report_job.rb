class ProcessReportJob < ApplicationJob
  queue_as :default

  def perform(report)
    # sleep 1
    report.processing!
    # sleep 1
    # report.update(progress_percent: 10, progress_details: [ "Started" ])
    # sleep 2
    # report.update(progress_percent: 20, progress_details: [ "Foo" ])
    # sleep 1
    # report.update(progress_percent: 20, progress_details: [ "Bar" ])
    # sleep 1
    # report.update(progress_percent: 20, progress_details: [ "Completed" ])
    # sleep 1
    # report.completed!
  end
end
