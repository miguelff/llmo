require "open3"

class ProcessReportJob < ApplicationJob
  queue_as :default

  MIN_UPDATE_INTERVAL = 2.seconds

  def perform(report, questions_count: Rails.configuration.x.questions_count)
    step_to_cost_dictionary = Analysis::Step.descendants.map { |step| [ step.name, step.cost(questions_count) ] }.to_h
    total_cost = step_to_cost_dictionary.values.sum
    steps_percentage_dictionary = step_to_cost_dictionary.transform_values { |cost| cost * 100 / total_cost }
    percentage = 0

    remaining_cost = total_cost
    last_updated_at = Time.now

    report.processing!

    input_classifier = Analysis::InputClassifier.new(report: report, language: Analysis::DEFAULT_LANGUAGE)
    report.update_progress(message: "Resoning on input")
    unless input_classifier.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error classifying input: #{input_classifier.error}"
      report.failed!
      return
    end
    topic = input_classifier.result
    Rails.logger.info "[Report #{report.id}] Topic: #{topic.inspect}"


    report.update_progress(message: "Detecting language", percentage: percentage += steps_percentage_dictionary[Analysis::InputClassifier.name])
    language_detector = Analysis::LanguageDetector.new(report: report)
    unless language_detector.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error detecting language: #{language_detector.error}"
      report.failed!
      return
    end
    report.update_progress(percentage: steps_percentage_dictionary[Analysis::LanguageDetector.name])

    language = language_detector.result
    Rails.logger.info "[Report #{report.id}] Language: #{language}"

    report.update_progress(message: "Sampling user questions", percentage: percentage += steps_percentage_dictionary[Analysis::LanguageDetector.name])
    question_synthesis = Analysis::QuestionSynthesis.new(report: report, language: language, questions_count: questions_count)
    unless question_synthesis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error synthesizing questions: #{question_synthesis.error}"
      report.failed!
      return
    end
    questions = question_synthesis.result
    Rails.logger.info "[Report #{report.id}] Questions: #{questions.inspect}"


    questions_answered = 0
    before_percentage = percentage
    after_percentage = before_percentage + steps_percentage_dictionary[Analysis::QuestionAnswering.name]

    report.update_progress(message: "Answering questions", percentage: percentage += steps_percentage_dictionary[Analysis::QuestionSynthesis.name])
    question_analysis = Analysis::QuestionAnswering.new(report: report, language: language, questions: questions).with_question_answered_callback(->(question, answer) {
      questions_answered += 1
      percentage = (before_percentage + (after_percentage - before_percentage) * questions_answered / questions.count.to_f).round
      report.update_progress(message: "Answered question #{questions_answered}/#{questions.count}", percentage: percentage)
    })

    unless question_analysis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error answering questions: #{question_analysis.error}"
      report.failed!
      return
    end
    answers = question_analysis.result
    Rails.logger.info "[Report #{report.id}] Answers: #{answers.inspect}"

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
    before_percentage = percentage
    after_percentage = before_percentage + steps_percentage_dictionary[Analysis::EntityExtractor.name]

    entity_extractor = Analysis::EntityExtractor.new(report: report, language: language, answers: answers).with_entities_extracted_callback(->(result) {
      units_processed += 1
      percentage = (before_percentage + (after_percentage - before_percentage) * units_processed / total_units.to_f).round
      report.update_progress(message: "Extracting entities", percentage: percentage)
    })

    unless entity_extractor.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error extracting entities: #{entity_extractor.error}"
      report.failed!
      return
    end
    entities = entity_extractor.result
    Rails.logger.info "[Report #{report.id}] Entities: #{entities.inspect}"

    report.update_progress(message: "Analyzing competitors")
    competitors_analysis = Analysis::Competitors.new(report: report, language: language, entities: entities, topic: topic, answers: answers)
    unless competitors_analysis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error analyzing competitors: #{competitors_analysis.error}"
      report.failed!
      return
    end
    Rails.logger.info "[Report #{report.id}] Competitors: #{competitors_analysis.result.inspect}"
    competitors = competitors_analysis.result

    report.update_progress(message: "Ranking results", percentage: percentage += steps_percentage_dictionary[Analysis::Competitors.name])
    ranking = Analysis::Ranking.new(report: report, entities: entities)
    unless ranking.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error ranking results: #{ranking.error}"
      report.failed!
      return
    end
    Rails.logger.info "[Report #{report.id}] Ranking: #{ranking.result.inspect}"

    report.complete_analysis
  rescue => e
    Rails.logger.error "[Report #{report.id}] Error processing report: #{e.message}. #{e.backtrace}"
    report.update!(latest_error: e.message, status: :failed)
    raise e
  end
end
