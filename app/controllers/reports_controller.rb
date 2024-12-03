class ReportsController < ApplicationController
  include ApplicationHelper

  before_action :set_report, only: %i[ show result destroy retry clone]

  skip_before_action :authenticate_user!, only: [ :result ]

  # GET /reports/1 or /reports/1.json
  def show
    if @report.completed?
      redirect_to result_report_path(@report)
    end
  end

  # GET /reports/1/result
  def result
    if !@report.completed?
      redirect_to @report, status: :see_other, notice: "Report result is not ready yet"
    elsif current_user.nil?
      render layout: "application"
    else
      render
    end
  end

  def retry
    @report.retry
    redirect_to @report, status: :see_other, notice: "Retrying report"
  end

  def clone
    @report = @report.dup
    render :new
  end

  # GET /reports/new
  def new
    @report = Report.new
  end

  # POST /reports or /reports.json
  def create
    @report = Report.new(report_params)
    @report.owner = current_user
    respond_to do |format|
      if @report.save
        format.html { redirect_to @report, notice: "Report was successfully created." }
        format.json { render :show, status: :created, location: @report }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reports/1 or /reports/1.json
  def destroy
    @report.destroy!

    respond_to do |format|
      format.html { render partial: "reports/recent", status: :ok }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_report
      begin
        @report = Report.find(params.expect(:id))
      rescue ActiveRecord::RecordNotFound
        redirect_to root_path, status: :see_other, notice: "Report not found"
      end
    end

    # Only allow a list of trusted parameters through.
    def report_params
      params.expect(report: [ :query, :brand_info, :cohort, :region ])
    end

    def progress_params
      params.expect(report: [ :percentage, :message, :result ])
    end
end
