require "test_helper"

class Analysis::QuestionSynthesisTest < ActiveSupport::TestCase
  test "perform for spanish language" do
    VCR.use_cassette("analysis/question_synthesis/es") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "spa")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "¿Cuáles son los coches más recomendados por expertos en seguridad para mujeres mayores de 45 años?", analysis.result.first
    end
  end

  test "limit questions count" do
    VCR.use_cassette("analysis/question_synthesis/limit_questions_count") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 20, language: "spa")
      assert analysis.perform_and_save
      assert_equal 10, analysis.reload.result.count
    end
  end

  test "perform for german language" do
    VCR.use_cassette("analysis/question_synthesis/deu") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "deu")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "Welche Autos gelten als die sichersten für Frauen über 45 Jahre?", analysis.result.first
    end
  end

  test "perform for french language" do
    VCR.use_cassette("analysis/question_synthesis/fra") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "fra")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "Quelles sont les voitures les plus recommandées pour leur sécurité dans la tranche d'âge des femmes de 45 ans et plus ?", analysis.result.first
    end
  end

  test "perform for english language" do
    VCR.use_cassette("analysis/question_synthesis/en") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "eng")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "What are the most recommended safe cars for women over 45?", analysis.result.first
    end
  end

  test "perform for unsupported language" do
    VCR.use_cassette("analysis/question_synthesis/unsupported") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "und")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "What are the most recommended safe cars for women over 45?", analysis.result.first
    end
  end
end
