module CurrentAnalysis
  extend ActiveSupport::Concern

  def cancel_current_analysis
    current_analysis&.canceled!
    session.delete(:analysis_id)
  end

  def current_analysis
    @current_analysis ||= Analysis::Record.find(session[:analysis_id]) if session[:analysis_id].present?
  end

  def set_current_analysis
    session[:analysis_id] ||= Analysis::Record.create(status: :pending).id.to_s
  end
end
