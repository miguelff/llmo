class AnalysisController < ApplicationController
  include CurrentAnalysis

  def destroy
    cancel_current_analysis
    redirect_to root_path
  end

  def your_website
    @your_website = Analysis::YourWebsite::Form.new(analysis: current_analysis)
    render "analysis/your_website/new"
  end

  def process_your_website
    @your_website = Analysis::YourWebsite::Form.new(your_website_params)
    if @your_website.perform_later
      current_analysis.update!(status: :performing, next_action: :your_website_results)
      redirect_to action: :your_website_results
    else
      render "analysis/your_website/new"
    end
  end

  def your_website_results
    @your_website = Analysis::YourWebsite.find_by(analysis: current_analysis)
    render "analysis/your_website/results"
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

  def your_website_params
    with_analyis(params.require(:analysis_your_website_form).permit(:url))
  end

  def with_analyis(params)
    params.merge(analysis: current_analysis)
  end
end
