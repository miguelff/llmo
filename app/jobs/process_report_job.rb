require "open3"

class ProcessReportJob < ApplicationJob
  queue_as :default

  MIN_UPDATE_INTERVAL = 2.seconds

  def perform(report, questions_count: Rails.configuration.x.questions_count)
    percentage = 0
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

    progress = 5
    report.update_progress(message: "Detecting language", percentage: progress)
    language_detector = Analysis::LanguageDetector.new(report: report)
    unless language_detector.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error detecting language: #{language_detector.error}"
      report.failed!
      return
    end

    language = language_detector.result
    Rails.logger.info "[Report #{report.id}] Language: #{language}"

    progress = 10
    report.update_progress(message: "Sampling user questions", percentage: progress)
    question_synthesis = Analysis::QuestionSynthesis.new(report: report, language: language, questions_count: questions_count)
    unless question_synthesis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error synthesizing questions: #{question_synthesis.error}"
      report.failed!
      return
    end
    questions = question_synthesis.result
    Rails.logger.info "[Report #{report.id}] Questions: #{questions.inspect}"


    progress= 15
    questions_answered = 0
    before_percentage = progress
    after_percentage = 60

    report.update_progress(message: "Formulating questions", percentage: progress)
    question_analysis = Analysis::QuestionAnswering.new(report: report, language: language, questions: questions).with_question_answered_callback(->(question, answer) {
      questions_answered += 1
      percentage = (before_percentage + (after_percentage - before_percentage) * questions_answered / questions.count.to_f).round
      report.update_progress(message: "Answered question #{questions_answered}/#{questions.count}", percentage: percentage)
    })

    sleep 1

    unless question_analysis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error answering questions: #{question_analysis.error}"
      report.failed!
      return
    end
    answers = question_analysis.result
    Rails.logger.info "[Report #{report.id}] Answers: #{answers.inspect}"

    progress = 60
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

    entity_extractor = Analysis::EntityExtractor.new(report: report, language: language, answers: answers).with_entities_extracted_callback(->(result) {
      units_processed += 1
      percentage = (before_percentage + (after_percentage - before_percentage) * units_processed / total_units.to_f).round
      report.update_progress(message: "Performing analysis", percentage: percentage)
    })

    unless entity_extractor.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error extracting entities: #{entity_extractor.error}"
      report.failed!
      return
    end
    entities = entity_extractor.result
    Rails.logger.info "[Report #{report.id}] Entities: #{entities.inspect}"

    progress = 95
    report.update_progress(message: "pulling out competitors", percentage: progress)
    competitors_analysis = Analysis::Competitors.new(report: report, language: language, entities: entities, topic: topic, answers: answers)
    unless competitors_analysis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error analyzing competitors: #{competitors_analysis.error}"
      report.failed!
      return
    end
    Rails.logger.info "[Report #{report.id}] Competitors: #{competitors_analysis.result.inspect}"
    competitors = competitors_analysis.result

    progress = 98
    report.update_progress(message: "ranking results", percentage: progress)
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
