require "test_helper"

class Analysis::QuestionAnsweringTest < ActiveSupport::TestCase
  test "answering questions (deu)" do
    VCR.use_cassette("analysis/question_answering/deu") do
      report = reports(:safe_cars)
      question = "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?"

      questions = []
      2.times do
        questions << question
      end
      analysis = Analysis::QuestionAnswering.new(report: report, language: "deu", questions: questions)

      assert analysis.perform_and_save, "Error prevented saving: #{analysis.error}"
      assert_equal 2, analysis.reload.result.count
      assert_equal question, analysis.result.first["question"]
      assert analysis.result.first["answer"].include?("für"), "Answer should be present"
    end
  end
end
