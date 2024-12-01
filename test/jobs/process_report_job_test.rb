require "test_helper"

class ProcessReportJobTest < ActiveJob::TestCase
  def assert_report_processed_correctly(report, questions_count:)
      assert report.completed?, "Report should be completed, but was #{report.status}"
      analyses = report.reload.analyses
      assert_equal [
        "Analysis::InputClassifier",
        "Analysis::LanguageDetector",
        "Analysis::QuestionSynthesis",
        "Analysis::QuestionAnswering",
        "Analysis::EntityExtractor",
        "Analysis::Competitors",
        "Analysis::Ranking"
        ], analyses.map(&:type)

        if ENV["OUTPUT_ANALYSES"]
          puts JSON.pretty_generate(analyses.map { |a| [ a.type, a.result ] })
        end

        assert analyses.all?(&:succeeded?), "All analyses should have succeeded"
        assert_equal questions_count, report.question_answering_analysis.result.count
  end


  test "process short report" do
    VCR.use_cassette("jobs/process_report_job/process_report_short") do
      questions_count = 2
      report = Report.create!(query: "What is the best laptop in the market?", cohort: "Software Engineering students", brand_info: "Dell XPS", owner: users(:jane))
      ProcessReportJob.perform_now(report, questions_count: questions_count)
      assert_report_processed_correctly(report, questions_count: questions_count)
    end
  end

  test "process long report" do
    skip "Skipping this test"
    VCR.use_cassette("jobs/process_report_job/process_report_long") do
      questions_count = 10
      report = Report.create!(query: "What is the best watch in the market?", cohort: "Watch Enthusiasts", brand_info: "Rolex Submariner", owner: users(:jane))
      ProcessReportJob.perform_now(report, questions_count: questions_count)
      assert_report_processed_correctly(report, questions_count: questions_count)
    end
  end
end
