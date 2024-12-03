class ProcessReportJob < ApplicationJob
  class StepFailedError < StandardError
    attr_reader :step, :error, :args

    def initialize(step, error: nil)
      super("[Step: #{step}] Failed: #{error}")
      @step = step
      @error = error
      @args = args
    end
  end


  include Analysis::Inference

  limits_concurrency to: 1, key: ->(report, **_) { report }

  retry_on StepFailedError, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError, NameError, ArgumentError

  queue_as :default

  def perform(report, questions_count: Rails.configuration.x.questions_count)
    report.processing!
    report.update_progress(message: "Classifying input", percentage: 0)
    topic = run_step(Analysis::InputClassifier, report, language: Analysis::DEFAULT_LANGUAGE)

    report.update_progress(message: "Detecting language", percentage: 5)
    language = run_step(Analysis::LanguageDetector, report, language: Analysis::DEFAULT_LANGUAGE)

    report.update_progress(message: "Sampling user questions", percentage: 10)
    questions = run_step(Analysis::QuestionSynthesis, report, language: language, questions_count: questions_count)

    progress= 15
    report.update_progress(message: "Answering user questions", percentage: progress)
    questions_answered = 0
    before_percentage = progress
    after_percentage = 60
    callback = ->(question, answer) {
      questions_answered += 1
      percentage = (before_percentage + (after_percentage - before_percentage) * questions_answered / questions.count.to_f).round
      report.update_progress(message: "Answered question #{questions_answered}/#{questions.count}", percentage: percentage)
    }
    answers = run_step(Analysis::QuestionAnswering, report, language: language, questions: questions, callback: callback)

    case topic["entity_type"]
    when "brand"
      report.update_progress(message: "Extracting brands")
    when "product"
      report.update_progress(message: "Extracting products")
    when "service"
      report.update_progress(message: "Extracting service offerings")
    else
      report.update_progress(message: "Extracting entities")
    end
    units_processed = 0
    total_units = questions.count + 1
    before_percentage = 60
    after_percentage = 90
    callback = ->(result) {
      units_processed += 1
      percentage = (before_percentage + (after_percentage - before_percentage) * units_processed / total_units.to_f).round
      report.update_progress(message: "Performing analysis", percentage: percentage)
    }
    entities = run_step(Analysis::EntityExtractor, report, language: language, answers: answers, callback: callback)

    report.update_progress(message: "Pulling out competitors", percentage: 95)
    competitors = run_step(Analysis::Competitors, report, language: language, entities: entities, topic: topic, answers: answers)

    report.update_progress(message: "ranking results", percentage: 98)
    run_step(Analysis::Ranking, report, entities: entities)

    report.complete_analysis
  rescue => e
    Rails.logger.error "[Report #{report.id}] #{e.message}"
    report.update!(latest_error: e.message, status: :failed)
    raise e
  end

  def run_step(step, report, **args)
    result = step.perform_if_needed(report, **args)

    if result.failed?
      Rails.logger.error "[Report #{report.id}] [Step: #{step.name}] #{result.error}"
      report.failed!
      throw StepFailedError.new(step, error: result.error)
    end

    Rails.logger.info "[Report #{report.id}] [Step: #{step.name}] Completed: #{result.inspect}"
    result.value!
  end
end
