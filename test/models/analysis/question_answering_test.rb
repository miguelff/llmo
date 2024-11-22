require "test_helper"

class Analysis::QuestionAnsweringTest < ActiveSupport::TestCase
  test "answering questions" do
    VCR.use_cassette("question_answering/deu") do
      report = reports(:safe_cars)
      question = "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?"
      analysis = Analysis::QuestionAnswering.new(report: report, language: "deu", questions: [ { question: question } ])
      assert analysis.perform_and_save
      assert_equal 1, analysis.reload.answers.count

      assert_equal question, analysis.answers.first["question"]
      assert analysis.answers.first["answer"].present?, "Answer should be present"
    end
  end
end
