module CurrentAnalysis
  extend ActiveSupport::Concern

  def cancel_current_analysis
    current_analysis&.canceled!
    session.delete(:analysis_id)
  end

  def current_analysis
    if session[:analysis_id].present?
      Analysis::Record.find_by(id: session[:analysis_id]).then do |record|
        if record.nil?
          Rails.logger.fatal "Analysis #{session[:analysis_id]} not found, this is a bug"
          session.delete(:analysis_id)
          current_analysis
        else
          record
        end
      end
    else
      record = Analysis::Record.create(status: :pending)
      session[:analysis_id] = record.id
      record
    end
  end
end
