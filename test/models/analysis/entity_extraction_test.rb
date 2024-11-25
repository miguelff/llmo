require "test_helper"

class Analysis::EntityExtractionTest < ActiveSupport::TestCase
  test "de" do
    answers = [ {
      "Welche Automarken bieten die sichersten Fahrzeuge für Frauen über 45 Jahren an?" =>  <<-TEXT.squish
      "Hier sind einige der sichersten Automarken und Modelle, die für Frauen über 45 Jahren empfohlen werden, basierend auf den neuesten Euro NCAP-Crashtests und Sicherheitsbewertungen:

        ### 1. **Volkswagen**
          - **Modell:** VW ID.7
          - **Sicherheitsbewertung:** 5 Sterne (346/400 Punkte)
          - **Begründung:** Der VW ID.7 bi
        etet hervorragenden Schutz für Insassen und Fußgänger sowie fortschrittliche Fahrassistenzsysteme, die das Unfallrisiko minimieren. Die hohe Punktzahl in den Crashtests zeigt, dass Volkswagen großen Wert auf Sicherheit legt.
          - **Quelle:** [ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos-euroncap/)

        ### 2. *
        *NIO**
          - **Modell:** NIO ET5
          - **Sicherheitsbewertung:** 5 Sterne (345/400 Punkte)
          - **Begründung:** Der NIO ET5 bietet exzellenten Insassenschutz und wirksame Notbremssysteme, die auf verschiedene Verkehrsteilnehmer reagieren. Dies macht ihn zu einer sicheren Wahl für alle Fahrer.
          - **Quelle:** [AutoScout24](https://www.autosco
        ut24.de/informieren/ratgeber/auto-sicherheit/ncap-sicherste-autos/)

        ### 3. **Smart**
          - **Modell:** Smart #3
          - **Sicherheitsbewertung:** 5 Sterne (345/400 Punkte)
          - **Begründung:** Der Smart #3 ist ein kompakter SUV mit umfangreichen Sicherheitsfeatures, die sowohl Insassen als auch Fußgänger schützen. Seine hohe Sicherheitsbewert
        ung macht ihn zu einer idealen Wahl für sicherheitsbewusste Fahrer.
          - **Quelle:** [Finn](https://www.finn.com/de-DE/auto/bestenliste/sicherstes-auto)

        ### 4. **Tesla**
          - **Modelle:** Tesla Model 3, Model Y
          - **Sicherheitsbewertung:** 5 Sterne
          - **Begründung:** Tesla-Fahrzeuge sind bekannt für ihren hohen Insassenschutz und umf
        angreiche Sicherheitsassistenzsysteme. Die Modelle bieten nicht nur Sicherheit, sondern auch innovative Technologien, die das Fahren erleichtern.
          - **Quelle:** [Carwow](https://www.carwow.de/beste-autos/euro-ncap-crashtest-llste-der-sichersten-autos)

        ### 5. **Volvo**
          - **Modelle:** Volvo XC60, XC90
          - **Sicherheitsbewertung:** 5 S
        terne
          - **Begründung:** Volvo hat einen hervorragenden Ruf für Sicherheit. Die Modelle XC60 und XC90 bieten herausragenden Insassenschutz und sind mit effektiven aktiven Sicherheitssystemen ausgestattet, die das Risiko von Unfällen verringern.
          - **Quelle:** [ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/crashtest/sichere-autos
        -euroncap-2022/)

        ### Fazit
        Die oben genannten Modelle wurden aufgrund ihrer hohen Sicherheitsbewertungen und der Verfügbarkeit moderner Sicherheitsassistenzsysteme ausgewählt. Diese Fahrzeuge bieten nicht nur Schutz für die Insassen, sondern auch Technologien, die das Fahren sicherer und einfacher machen. Es ist wichtig, beim Autokauf auf d
        ie Euro NCAP-Bewertungen zu achten und sich mit den spezifischen Sicherheitsmerkmalen der Fahrzeuge vertraut zu machen.
    TEXT
    } ]

    extraction = Analysis::EntityExtraction.new(answers: answers, language: "deu")
    assert extraction.valid?

    res = extraction.perform
    assert_equal [], res
  end
end
