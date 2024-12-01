class Analysis::QuestionSynthesis < Analysis::Step
    include Analysis::Inference

    def self.cost(queries_count)
        1 * Analysis::Step::COSTS[:inference]
    end

    attribute :questions_count, :integer, default: 10
    validates_presence_of :questions_count, message: "Questions count is required"

    schema do
        define :question do
            string :question
        end
        array :questions, items: ref(:question)
    end

    MAX_QUESTIONS = 10

    system({
        eng: <<-EOF.promptize
           If I wanted to find out the top-rated products or services in a category without mentioning any product, brand or service specifically, which questions should I ask?

           The question should be oriented towards seeking the best products in this category in a first-shot, not the best features. do not ask about features. If the question was answered,
           in a phase later, it should provide me with products, brands or services.

           To do this, I will provide you with:
            * The category
            * A description of the ideal customer, so you can narrow the questions to seek the best alternatives for them.
            * The language in which you should formulate the questions
        EOF
    })

    def perform
        res = chat(user_message)
        unless res.refusal.present?
            self.result = extrapolate_questions(res.parsed.questions)
        else
            self.error = "Question synthesis refused: #{res.refusal}"
            Rails.logger.error(self.error)
        end

        true
    end

    def extrapolate_questions(questions)
        [].tap do |res|
            self.questions_count.times do |i|
                res << questions[i % questions.count]["question"]
            end
        end
    end

    def user_message
        persona = self.report.cohort.present? ? self.report.cohort : "a consumer"
        if self.report.region.present?
            persona += " from the region of #{self.report.region}"
        end

        <<-EOF.promptize
            response language: #{Analysis::LANGUAGE_NAMES_IN_ENGLISH[self.language] || "English"}
            category: #{self.report.query}
            ideal customer: #{persona}

            Generate #{number_of_questions} questions
        EOF
    end

    def number_of_questions
        [ self.questions_count, MAX_QUESTIONS ].min
    end
end
