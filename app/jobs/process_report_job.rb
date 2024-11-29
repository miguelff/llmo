require "open3"

class ProcessReportJob < ApplicationJob
  queue_as :default

  MIN_UPDATE_INTERVAL = 2.seconds

  def perform(report, questions_count: Rails.configuration.x.questions_count)
    total_cost = Analysis::Step.descendants.map { |step| step.cost(questions_count) }.sum
    remaining_cost = total_cost
    last_updated_at = Time.now

    ActiveSupport::Notifications.subscribe("expensive_operation") do |event|
      remaining_cost -= event.payload[:cost]
      now = Time.now
      if Rails.env.test? || (now - last_updated_at > MIN_UPDATE_INTERVAL)
        percentage = ((total_cost - remaining_cost) * 100 / total_cost).clamp(0, 100).to_i
        report.update_progress(percentage: percentage) unless report.completed?
        last_updated_at = Time.now
      end
    end

    report.processing!

    report.update_progress(message: "Detecting language")
    language_detector = Analysis::LanguageDetector.new(report: report)
    unless language_detector.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error detecting language: #{language_detector.error}"
      report.failed!
      return
    end
    language = language_detector.result
    Rails.logger.info "[Report #{report.id}] Language: #{language}"

    report.update_progress(message: "Sampling user questions")
    question_synthesis = Analysis::QuestionSynthesis.new(report: report, language: language, questions_count: questions_count)
    unless question_synthesis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error synthesizing questions: #{question_synthesis.error}"
      report.failed!
      return
    end
    questions = question_synthesis.result
    Rails.logger.info "[Report #{report.id}] Questions: #{questions.inspect}"

    report.update_progress(message: "Answering questions")
    question_analysis = Analysis::QuestionAnswering.new(report: report, language: language, questions: questions)
    unless question_analysis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error answering questions: #{question_analysis.error}"
      report.failed!
      return
    end
    answers = question_analysis.result
    Rails.logger.info "[Report #{report.id}] Answers: #{answers.inspect}"

    input_classifier = Analysis::InputClassifier.new(report: report, language: language)
    unless input_classifier.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error classifying input: #{input_classifier.error}"
      report.failed!
      return
    end
    topic = input_classifier.result
    Rails.logger.info "[Report #{report.id}] Topic: #{topic.inspect}"

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

    entity_extractor = Analysis::EntityExtractor.new(report: report, language: language, answers: answers)
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

    report.update_progress(message: "Ranking results")
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
