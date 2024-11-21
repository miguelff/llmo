require "test_helper"

class Analysis::QuestionSynthesisTest < ActiveSupport::TestCase
  test "perform with given spanish language" do
    VCR.use_cassette("question_synthesis/es") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "spa")
      assert analysis.perform_and_save
      assert_equal 5, analysis.questions.count
    end
  end

  # test "perform with given english language" do
  #   VCR.use_cassette("question_synthesis/en") do
  #     report = reports(:safe_cars)
  #     analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "spa")
  #     assert analysis.perform_and_save
  #     assert_equal 5, analysis.questions.count
  #   end
  # end

  # test "unsupported language" do
  #   VCR.use_cassette("question_synthesis/unsupported") do
  #     report = reports(:safe_cars)
  #     analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "spa")
  #     assert analysis.perform_and_save
  #     assert_equal 5, analysis.questions.count
  #   end
  # end
end
