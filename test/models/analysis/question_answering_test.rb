require "test_helper"

class Analysis::QuestionAnsweringTest < ActiveSupport::TestCase
  test "answering questions" do
    VCR.use_cassette("question_answering/deu") do
      report = reports(:safe_cars)
      question = "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?"

      questions = []
      30.times do
        questions << { question: question }
      end
      analysis = Analysis::QuestionAnswering.new(report: report, language: "deu", questions: questions)

      assert analysis.perform_and_save
      assert_equal 30, analysis.reload.answers.count

      assert_equal question, analysis.answers.first["question"]
      assert analysis.answers.first["answer"].include?("für"), "Answer should be present"
    end
  end
end
