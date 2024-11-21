require "test_helper"

class Analysis::QuestionSynthesisTest < ActiveSupport::TestCase
  test "perform given spanish language" do
    VCR.use_cassette("question_synthesis/es") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "spa")
      assert analysis.perform_and_save
      assert_equal 5, analysis.questions.count
      assert_equal "¿Cuáles son las características de seguridad más importantes que las mujeres de 45 años o más deben considerar al elegir un coche seguro?", analysis.questions.first["question"]
    end
  end

  test "perform given english language" do
    VCR.use_cassette("question_synthesis/en") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "eng")
      assert analysis.perform_and_save
      assert_equal 5, analysis.questions.count
      assert_equal "What safety features do you prioritize when considering a car, such as advanced driver assistance systems or crash test ratings?", analysis.questions.first["question"]
    end
  end

  test "unsupported language" do
    VCR.use_cassette("question_synthesis/unsupported") do
      report = reports(:safe_cars)
      analysis = Analysis::QuestionSynthesis.new(report: report, questions_count: 5, language: "und")
      assert analysis.perform_and_save
      assert_equal 5, analysis.questions.count
      assert_equal "What safety features do you prioritize when considering a car, such as advanced driver assistance systems or crash test ratings?", analysis.questions.first["question"]
    end
  end
end
