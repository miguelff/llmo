require "test_helper"

class Analysis::QuestionSynthesisTest < ActiveSupport::TestCase
  test "perform for spanish language" do
    VCR.use_cassette("question_synthesis/es") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "spa")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "¿Cuáles son los coches más seguros recomendados para mujeres mayores de 45 años?", analysis.result.first["question"]
    end
  end

  test "perform for german language" do
    VCR.use_cassette("question_synthesis/deu") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "deu")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?", analysis.result.first["question"]
    end
  end

  test "perform for french language" do
    VCR.use_cassette("question_synthesis/fra") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "fra")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "Quelles sont les voitures les plus sûres recommandées pour les femmes de plus de 45 ans ?", analysis.result.first["question"]
    end
  end

  test "perform for english language" do
    VCR.use_cassette("question_synthesis/en") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "eng")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "What are the safest car models recommended for women over 45?", analysis.result.first["question"]
    end
  end

  test "perform for unsupported language" do
    VCR.use_cassette("question_synthesis/unsupported") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "und")
      assert analysis.perform_and_save
      assert_equal 5, analysis.reload.result.count
      assert_equal "What are the safest car models recommended for women over 45?", analysis.result.first["question"]
    end
  end
end
