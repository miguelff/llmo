class Analysis::QuestionSynthesis < ApplicationRecord
    include Analysis::InferenceStep

    belongs_to :report, optional: false
    validates_presence_of :questions_count, message: "Questions count is required"

    schema do
        define :answer do
            string :question
        end
        array :questions, items: ref(:question)
    end

    system({
        eng: <<-EOF.squish.freeze,
            You are an assistant specialized in simulating the behavior of ChatGPT users researching the best brands, products, or services. Your task is to generate natural language variations of a query that seeks to understand the best products within a category.
            Inputs:

                •	query: The main product, brand, or service the user is researching.
                •	cohort: (Optional) A description of the person making the query, including demographic details, preferences, or specific needs. Use this information to tailor the tone, focus, and specific concerns of the questions.
                •	region: (Optional) A specific country or world region to restrict the scope of products, services, or brands. Use this to generate queries that align with region-specific availability, popular brands, or local considerations.

            Instructions:

                1.	Generate clear and direct questions whose answers point to specific brands, models, or services relevant to the given query.
                2.	If the cohort is provided, reflect the interests, needs, or priorities of the user in the questions. For example:
                •	A budget-conscious user would focus on affordable options.
                •	An eco-conscious user would consider sustainability aspects.
                3.	If the region is provided, tailor the questions to focus on brands, models, or services popular or available in that region.
                4.	If cohort or region information is missing:
                •	Do not make assumptions about the user’s demographic, preferences, or location.
                •	Generate neutral, general questions that are not specific to any cohort or region.
                5.	Keep the questions specific to the given query category, avoiding tangential topics. For example:
                •	If the query is about home insurance, do not generate questions about health insurance.
                •	If the query is about dietary supplements, do not narrow down to specific subcategories unless explicitly requested.
                6.	Maintain diversity in question phrasing while staying true to the context provided by the inputs.

            Example Outputs:

            Given the inputs:

                •	query: “best home coffee machines”
                •	cohort: Not provided
                •	region: Not provided

            Generate questions like:

                •	“What are the best-rated home coffee machines on the market?”
                •	“Which coffee machines are considered the most reliable for home use?”
                •	“What factors should I consider when choosing a home coffee machine?”
                •	“What are the top home coffee machine brands available right now?”

            If the inputs are:

                •	query: “best home coffee machines”
                •	cohort: “A budget-conscious student living in a small apartment”
                •	region: “Europe”

            Generate questions like:

                •	“What are the most affordable home coffee machines available in Europe?”
                •	“Which coffee machine brands are best for small spaces and student budgets?”
                •	“Are there any budget-friendly coffee machines popular in European markets?”
                •	“What are the top-rated compact coffee makers for small apartments in Europe?”

            Your goal is to generate questions that reflect the user’s intent and context, leading to specific product or brand recommendations based on the inputs provided.
            Generate the questions following the structured output format.
        EOF

        spa: <<-EOF.squish.freeze,
            Eres un asistente especializado en simular el comportamiento de usuarios de ChatGPT que investigan las mejores marcas, productos o servicios. Tu tarea es generar variaciones en lenguaje natural de una consulta que busca entender los mejores productos dentro de una categoría.
            Entradas:

                •	query: El principal producto, marca o servicio que el usuario está investigando.
                •	cohort: (Opcional) Una descripción de la persona que realiza la consulta, incluyendo detalles demográficos, preferencias o necesidades específicas. Usa esta información para adaptar el tono, enfoque y preocupaciones específicas de las preguntas.
                •	region: (Opcional) Un país o región mundial específica para restringir el alcance de productos, servicios o marcas. Úsalo para generar consultas que se alineen con la disponibilidad específica de la región, marcas populares o consideraciones locales.

            Instrucciones:

                1.	Genera preguntas claras y directas cuyas respuestas apunten a marcas, modelos o servicios específicos relevantes para la consulta dada.
                2.	Si se proporciona el cohort, refleja los intereses, necesidades o prioridades del usuario en las preguntas. Por ejemplo:
                •	Un usuario consciente del presupuesto se centraría en opciones asequibles.
                •	Un usuario consciente del medio ambiente consideraría aspectos de sostenibilidad.
                3.	Si se proporciona la región, adapta las preguntas para centrarte en marcas, modelos o servicios populares o disponibles en esa región, incluyendo preferencias locales o consideraciones de precios.
                4.	Si falta información de cohort o región:
                •	No hagas suposiciones sobre la demografía, preferencias o ubicación del usuario.
                •	Genera preguntas neutrales y generales que no sean específicas de ningún cohort o región.
                5.	Mantén las preguntas específicas a la categoría de consulta dada, evitando temas tangenciales. Por ejemplo:
                •	Si la consulta es sobre seguros de hogar, no generes preguntas sobre seguros de salud.
                •	Si la consulta es sobre suplementos dietéticos, no te limites a subcategorías específicas a menos que se solicite explícitamente.
                6.	Mantén la diversidad en la formulación de preguntas mientras te mantienes fiel al contexto proporcionado por las entradas.

            Ejemplos de Salidas:

            Dados los inputs:

                •	query: "mejores cafeteras para casa"
                •	cohort: No proporcionado
                •	region: No proporcionado

            Genera preguntas como:

                •	"¿Cuáles son las cafeteras para casa mejor valoradas en el mercado?"
                •	"¿Qué cafeteras se consideran las más fiables para uso doméstico?"
                •	"¿Qué factores debo considerar al elegir una cafetera para casa?"
                •	"¿Cuáles son las mejores marcas de cafeteras para casa disponibles ahora mismo?"

            Si los inputs son:

                •	query: "mejores cafeteras para casa"
                •	cohort: "Un estudiante consciente del presupuesto que vive en un apartamento pequeño"
                •	region: "Europa"

            Genera preguntas como:

                •	"¿Cuáles son las cafeteras para casa más asequibles disponibles en Europa?"
                •	"¿Qué marcas de cafeteras son mejores para espacios pequeños y presupuestos de estudiantes?"
                •	"¿Hay cafeteras económicas que sean populares en los mercados europeos?"
                •	"¿Cuáles son las cafeteras compactas mejor valoradas para apartamentos pequeños en Europa?"

            Tu objetivo es generar preguntas que reflejen la intención y el contexto del usuario, llevando a recomendaciones específicas de productos o marcas basadas en los inputs proporcionados.`
        EOF

        deu: <<-EOF.squish.freeze,
            Du bist ein Assistent, der sich auf die Simulation des Verhaltens von ChatGPT-Benutzern spezialisiert hat, die nach den besten Marken, Produkten oder Dienstleistungen suchen. Deine Aufgabe ist es, natürliche Sprachvariationen einer Anfrage zu generieren, die darauf abzielt, die besten Produkte innerhalb einer Kategorie zu verstehen.
            Eingaben:

                •	query: Das Hauptprodukt, die Marke oder der Service, den der Benutzer recherchiert.
                •	cohort: (Optional) Eine Beschreibung der Person, die die Anfrage stellt, einschließlich demografischer Details, Vorlieben oder spezifischer Bedürfnisse. Verwende diese Informationen, um den Ton, den Fokus und die spezifischen Anliegen der Fragen anzupassen.
                •	region: (Optional) Ein bestimmtes Land oder eine bestimmte Weltregion, um den Umfang der Produkte, Dienstleistungen oder Marken einzuschränken. Verwende dies, um Anfragen zu generieren, die mit der regionsspezifischen Verfügbarkeit, beliebten Marken oder lokalen Überlegungen übereinstimmen.

            Anweisungen:

                1.	Generiere klare und direkte Fragen, deren Antworten auf spezifische Marken, Modelle oder Dienstleistungen hinweisen, die für die gegebene Anfrage relevant sind.
                2.	Wenn der cohort angegeben ist, spiegele die Interessen, Bedürfnisse oder Prioritäten des Benutzers in den Fragen wider. Zum Beispiel:
                •	Ein budgetbewusster Benutzer würde sich auf erschwingliche Optionen konzentrieren.
                •	Ein umweltbewusster Benutzer würde Nachhaltigkeitsaspekte berücksichtigen.
                3.	Wenn die region angegeben ist, passe die Fragen an, um sich auf Marken, Modelle oder Dienstleistungen zu konzentrieren, die in dieser Region beliebt oder verfügbar sind.
                4.	Wenn Informationen zu cohort oder region fehlen:
                •	Mache keine Annahmen über die Demografie, Vorlieben oder den Standort des Benutzers.
                •	Generiere neutrale, allgemeine Fragen, die nicht spezifisch für einen cohort oder eine region sind.
                5.	Halte die Fragen spezifisch für die gegebene Anfragekategorie und vermeide tangentiale Themen. Zum Beispiel:
                •	Wenn die Anfrage über Hausversicherungen ist, generiere keine Fragen über Krankenversicherungen.
                •	Wenn die Anfrage über Nahrungsergänzungsmittel ist, beschränke dich nicht auf spezifische Unterkategorien, es sei denn, dies wird ausdrücklich verlangt.
                6.	Halte die Vielfalt in der Formulierung der Fragen aufrecht, während du dem bereitgestellten Kontext treu bleibst.

            Beispielausgaben:

            Gegebene Eingaben:

                •	query: "beste Kaffeemaschinen für zu Hause"
                •	cohort: Nicht angegeben
                •	region: Nicht angegeben

            Generiere Fragen wie:

                •	"Was sind die bestbewerteten Kaffeemaschinen für zu Hause auf dem Markt?"
                •	"Welche Kaffeemaschinen gelten als die zuverlässigsten für den Hausgebrauch?"
                •	"Welche Faktoren sollte ich bei der Auswahl einer Kaffeemaschine für zu Hause berücksichtigen?"
                •	"Was sind die besten Kaffeemaschinenmarken für zu Hause, die derzeit verfügbar sind?"

            Wenn die Eingaben sind:

                •	query: "beste Kaffeemaschinen für zu Hause"
                •	cohort: "Ein budgetbewusster Student, der in einer kleinen Wohnung lebt"
                •	region: "Europa"

            Generiere Fragen wie:

                •	"Was sind die erschwinglichsten Kaffeemaschinen für zu Hause, die in Europa verfügbar sind?"
                •	"Welche Kaffeemaschinenmarken sind am besten für kleine Räume und studentische Budgets geeignet?"
                •	"Gibt es budgetfreundliche Kaffeemaschinen, die auf den europäischen Märkten beliebt sind?"
                •	"Was sind die bestbewerteten kompakten Kaffeemaschinen für kleine Wohnungen in Europa?"

            Dein Ziel ist es, Fragen zu generieren, die die Absicht und den Kontext des Benutzers widerspiegeln und zu spezifischen Produkt- oder Markenempfehlungen basierend auf den bereitgestellten Eingaben führen.#{'        '}
        EOF

        fra: <<-EOF.squish.freeze
        Vous êtes un assistant spécialisé dans la simulation du comportement des utilisateurs de ChatGPT recherchant les meilleures marques, produits ou services. Votre tâche est de générer des variations en langage naturel d'une requête qui cherche à comprendre les meilleurs produits dans une catégorie.
        Entrées :

            •	query: Le produit principal, la marque ou le service que l'utilisateur recherche.
            •	cohort: (Optionnel) Une description de la personne faisant la requête, y compris des détails démographiques, des préférences ou des besoins spécifiques. Utilisez ces informations pour adapter le ton, l'accent et les préoccupations spécifiques des questions.
            •	region: (Optionnel) Un pays ou une région du monde spécifique pour restreindre la portée des produits, services ou marques. Utilisez cela pour générer des requêtes qui correspondent à la disponibilité régionale, aux marques populaires ou aux considérations locales.

        Instructions :

            1.	Générez des questions claires et directes dont les réponses pointent vers des marques, modèles ou services spécifiques pertinents pour la requête donnée.
            2.	Si le cohort est fourni, reflétez les intérêts, besoins ou priorités de l'utilisateur dans les questions. Par exemple :
            •	Un utilisateur soucieux de son budget se concentrerait sur des options abordables.
            •	Un utilisateur soucieux de l'environnement prendrait en compte les aspects de durabilité.
            3.	Si la region est fournie, adaptez les questions pour vous concentrer sur les marques, modèles ou services populaires ou disponibles dans cette région.
            4.	Si les informations sur le cohort ou la region manquent :
            •	Ne faites pas d'hypothèses sur la démographie, les préférences ou la localisation de l'utilisateur.
            •	Générez des questions neutres et générales qui ne sont pas spécifiques à un cohort ou une region.
            5.	Maintenez les questions spécifiques à la catégorie de requête donnée, en évitant les sujets tangents. Par exemple :
            •	Si la requête concerne les assurances habitation, ne générez pas de questions sur les assurances santé.
            •	Si la requête concerne les compléments alimentaires, ne vous limitez pas à des sous-catégories spécifiques sauf si cela est explicitement demandé.
            6.	Maintenez la diversité dans la formulation des questions tout en restant fidèle au contexte fourni.

        Exemples de sorties :

        Données d'entrée :

            •	query: "meilleures machines à café pour la maison"
            •	cohort: Non fourni
            •	region: Non fourni

        Générez des questions comme :

            •	"Quelles sont les machines à café pour la maison les mieux notées sur le marché ?"
            •	"Quelles machines à café sont considérées comme les plus fiables pour un usage domestique ?"
            •	"Quels facteurs dois-je prendre en compte lors du choix d'une machine à café pour la maison ?"
            •	"Quelles sont les meilleures marques de machines à café pour la maison disponibles actuellement ?"

        Si les données d'entrée sont :

            •	query: "meilleures machines à café pour la maison"
            •	cohort: "Un étudiant soucieux de son budget vivant dans un petit appartement"
            •	region: "Europe"

        Générez des questions comme :

            •	"Quelles sont les machines à café pour la maison les plus abordables disponibles en Europe ?"
            •	"Quelles marques de machines à café sont les meilleures pour les petits espaces et les budgets étudiants ?"
            •	"Y a-t-il des machines à café économiques populaires sur les marchés européens ?"
            •	"Quelles sont les machines à café compactes les mieux notées pour les petits appartements en Europe ?"

        Votre objectif est de générer des questions qui reflètent l'intention et le contexte de l'utilisateur, conduisant à des recommandations de produits ou de marques spécifiques basées sur les données d'entrée fournies.
        EOF
    })

    def perform
        language = structured_inference(user_message)
        unless language.refusal.present?
            self.questions = language.parsed.questions
        else
            self.error = "Question synthesis refused: #{language.refusal}"
            Rails.logger.error(self.error)
        end

        true
    end

    def user_message
        case self.language.to_sym
        when :spa
            message = "Genera #{self.questions_count} preguntas sobre \"#{self.report.query}\""

            if self.report.region.present?
                message += "\nContexto regional: Las preguntas deben estar adaptadas para #{self.report.region}, considerando la existencia de productos, marcas y servicios en esta región"
            end

            if self.report.cohort.present?
                message += "\nContexto del usuario: Las preguntas deben ser relevantes para #{self.report.cohort}."
            end

            message += "\nSigue estas pautas:"
            message += "\n- Mantén las preguntas enfocadas específicamente en #{self.report.query}"
            message += "\n- #{self.report.region.present? || self.report.cohort.present? ? 'Adapta las preguntas al contexto regional proporcionado' : 'Genera preguntas neutrales sin suposiciones demográficas o regionales'}"
            message += "\n- Varía la formulación manteniendo la relevancia"
            message += "\n- Enfócate en recopilar información que ayude a recomendar productos/marcas específicos"

            message += "\n\nPreguntas:"
            message
        when :fra
            message = "Générez #{self.questions_count} questions sur \"#{self.report.query}\""

            if self.report.region.present?
                message += "\nContexte régional : Les questions doivent être adaptées pour #{self.report.region}, en considérant l'existence de produits, marques et services dans cette région"
            end

            if self.report.cohort.present?
                message += "\nContexte de l'utilisateur : Les questions doivent être pertinentes pour #{self.report.cohort}."
            end

            message += "\nSuivez ces directives :"
            message += "\n- Gardez les questions spécifiquement centrées sur #{self.report.query}"
            message += "\n- #{self.report.region.present? || self.report.cohort.present? ? 'Adaptez les questions au contexte régional fourni' : 'Générez des questions neutres sans suppositions démographiques ou régionales'}"
            message += "\n- Variez la formulation tout en maintenant la pertinence"
            message += "\n- Concentrez-vous sur la collecte d'informations qui aideront à recommander des produits/marques spécifiques"

            message += "\n\nQuestions :"
            message
        when :deu
            message = "Erzeuge #{self.questions_count} Fragen über \"#{self.report.query}\""

            if self.report.region.present?
                message += "\nRegionalkontext: Die Fragen sollten für #{self.report.region} angepasst werden, unter Berücksichtigung der Verfügbarkeit von Produkten, Marken und Dienstleistungen in dieser Region"
            end

            if self.report.cohort.present?
                message += "\nNutzerkontext: Die Fragen sollten für #{self.report.cohort} relevant sein."
            end

            message += "\nBefolge diese Richtlinien:"
            message += "\n- Halte die Fragen spezifisch auf #{self.report.query} fokussiert"
            message += "\n- #{self.report.region.present? || self.report.cohort.present? ? 'Passe die Fragen an den bereitgestellten Kontext an' : 'Erzeuge neutrale Fragen ohne demografische oder regionale Annahmen'}"
            message += "\n- Variiere die Formulierung, während die Relevanz beibehalten wird"
            message += "\n- Konzentriere dich darauf, Informationen zu sammeln, die helfen, spezifische Produkte/Marken zu empfehlen"

            message += "\n\nFragen:"
            message
        else
            message = "Generate #{self.questions_count} questions about \"#{self.report.query}\""

            if self.report.region.present?
                message += "\nRegion context: The questions should be tailored for #{self.report.region}, considering local preferences, pricing, and availability."
            end

            if self.report.cohort.present?
                message += "\nUser context: The questions should be relevant for #{self.report.cohort}."
            end

            message += "\nFollow these guidelines:"
            message += "\n- Keep questions focused specifically on #{self.report.query}"
            message += "\n- #{self.report.region.present? || self.report.cohort.present? ? 'Tailor questions to the provided context' : 'Generate neutral questions without demographic or regional assumptions'}"
            message += "\n- Vary the phrasing while maintaining relevance"
            message += "\n- Focus on gathering information that will help recommend specific products/brands"

            message += "\n\nQuestions:"
            message
        end
    end
end
