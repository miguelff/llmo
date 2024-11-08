class ReportsController < ApplicationController
  before_action :set_report, only: %i[ show result update destroy ]
  skip_before_action :verify_authenticity_token, only: :update

  # GET /reports/1 or /reports/1.json
  def show
    if @report.result.present?
      redirect_to result_report_path(@report)
    end
  end

  # GET /reports/1/result
  def result
    if @report.result.nil?
      redirect_to @report, status: :see_other, notice: "Report result is not ready yet"
    end
  end

  # GET /reports/new
  def new
    @report = Report.new
  end

  # POST /reports or /reports.json
  def create
    @report = Report.new(report_params)

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

  # PATCH/PUT /reports/1 or /reports/1.json
  def update
    if @report.update_progress(progress_params)
      render :show, status: :ok, location: @report
    else
      render json: @report.errors, status: :unprocessable_entity
    end
  end

  # DELETE /reports/1 or /reports/1.json
  def destroy
    @report.destroy!

    respond_to do |format|
      format.html { redirect_to reports_path, status: :see_other, notice: "Report was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_report
      @report = Report.includes(:result).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def report_params
      params.expect(report: [ :query, advanced_settings: Report::VALID_ADVANCED_SETTINGS ])
    end

    def progress_params
      params.expect(report: [ :percentage, :message, :result ])
    end
end
