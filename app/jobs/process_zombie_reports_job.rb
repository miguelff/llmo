class ProcessZombieReportsJob < ApplicationJob
  queue_as :default

  ZOMBIE_REPORT_TIMEOUT = 2.minutes

  def perform
    Report.zombies.find_each do |report|
      Rails.logger.info "[Report #{report.id}] Retrying zombie report"
      if report.retry
        Rails.logger.info "[Report #{report.id}] Retrying zombie successfully"
      else
        Rails.logger.error "[Report #{report.id}] Error retrying zombie report"
      end
    end
  end
end
