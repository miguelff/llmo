require "test_helper"

class Analysis::QuestionAnsweringTest < ActiveSupport::TestCase
  test "answering questions" do
    VCR.use_cassette("question_answering/deu") do
      report = reports(:safe_cars)
      question = "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?"
      analysis = Analysis::QuestionAnswering.new(report: report, questions: [ { question: question, language: "deu" } ])
      assert analysis.perform_and_save
      assert_equal 1, analysis.reload.answers.count

      assert_equal question, analysis.answers.first["question"]
      assert_equal <<-EOF.squish, analysis&.answers&.first&.[]("answer")&.squish
        Um die sichersten Fahrzeuge für Frauen über 45 Jahren zu identifizieren, ist es wichtig, auf Automarken und Modelle zu achten, die in Sicherheitsbewertungen und Tests gut abschneiden. Hier sind einige Marken und Modelle, die für ihre Sicherheitsmerkmale bekannt sind:

        1. **Volvo**:
           - Modelle wie der Volvo XC60 und der Volvo S60 sind bekannt für ihre fortschrittlichen Sicherheitsmerkmale. Volvo hat einen hervorragenden Ruf für Sicherheit und ist oft Vorreiter bei der Einführung neuer Sicherheitsinnovationen.
           - Quelle: [IIHS - Volvo Safety Ratings](https://www.iihs.org/ratings/volvo)

        2. **Subaru**:
           - Der Subaru Outback und der Subaru Forester sind bekannt für ihre Sicherheitsmerkmale, einschließlich des EyeSight-Systems, das Fahrerassistenzfunktionen bietet.
           - Quelle: [IIHS - Subaru Safety Ratings](https://www.iihs.org/ratings/subaru)

        3. **Toyota**:
           - Modelle wie der Toyota Camry und der Toyota RAV4 bieten umfassende Sicherheitsmerkmale und haben in Crashtests gut abgeschnitten.
           - Quelle: [IIHS - Toyota Safety Ratings](https://www.iihs.org/ratings/toyota)

        4. **Honda**:
           - Der Honda CR-V und der Honda Accord sind für ihre Sicherheitsmerkmale und Zuverlässigkeit bekannt. Sie bieten fortschrittliche Fahrerassistenzsysteme.
           - Quelle: [IIHS - Honda Safety Ratings](https://www.iihs.org/ratings/honda)

        5. **Mazda**:
           - Der Mazda CX-5 ist ein weiteres Modell, das für seine Sicherheitsmerkmale und seine gute Leistung in Crashtests bekannt ist.
           - Quelle: [IIHS - Mazda Safety Ratings](https://www.iihs.org/ratings/mazda)

        Diese Marken und Modelle wurden aufgrund ihrer hohen Bewertungen in Sicherheitsbewertungen und ihrer Ausstattung mit fortschrittlichen Sicherheitsmerkmalen ausgewählt. Die Insurance Institute for Highway Safety (IIHS) und die National Highway Traffic Safety Administration (NHTSA) sind zuverlässige Quellen für Sicherheitsbewertungen, die bei der Auswahl berücksichtigt wurden.

        Die genannten Modelle bieten eine Kombination aus aktiven und passiven Sicherheitsmerkmalen, die besonders für Fahrerinnen über 45 Jahren von Vorteil sein können, da sie oft Wert auf Zuverlässigkeit und umfassende Sicherheitsausstattung legen.
      EOF
    end
  end
end
