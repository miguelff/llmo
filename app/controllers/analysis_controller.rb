class AnalysisController < ApplicationController
  before_action :set_session, only: :process_your_website
  before_action :redirect_if_no_analysis_id, except: :process_your_website
  helper_method :current_analysis

  def your_website
    head :not_found
  end

  def process_your_website
    @your_website = Analysis::YourWebsite.for(your_website_params)
    if @your_website.perform_and_save
      render "analysis/your_website/result"
    else
      render "analysis/your_website/new"
    end
  end

  # def your_brand
  #   # Add logic for your_brand action here
  #   render partial: "analysis/process_your_brand"
  # end

  # def process_your_brand
  #   # Add logic for processing your_brand action here
  #   render partial: "analysis/process_your_brand"
  # end

  # def order_confirmation
  #   # Add logic for order_confirmation action here
  #   render partial: "analysis/order_confirmation"
  # end

  # def process_order_confirmation
  #   # Add logic for processing order_confirmation action here
  #   render partial: "analysis/process_order_confirmation"
  # end

  # def pay
  #   # Add logic for pay action here
  #   render partial: "analysis/pay"
  # end

  # def process_pay
  #   # Add logic for processing pay action here
  #   render partial: "analysis/process_pay"
  # end

  # def receive_report
  #   # Add logic for receive_report action here
  #   render partial: "analysis/receive_report"
  # end

  # def process_receive_report
  #   # Add logic for processing receive_report action here
  #   render partial: "analysis/process_receive_report"
  # end

  private

  def current_analysis
    @current_analysis ||= Analysis::Record.find(session[:analysis_id]) if analysis_started?
  end

  def analysis_started?
    session[:analysis_id].present?
  end

  def redirect_if_no_analysis_id
    redirect_to action: :one unless session[:analysis_id]
  end

  def set_session
    session[:analysis_id] = Analysis::Record.create!.id.to_s
  end

  def your_website_params
    with_analyis(params.require(:analysis_website).permit(:url))
  end

  def with_analyis(params)
    params.merge(analysis: current_analysis)
  end
end
