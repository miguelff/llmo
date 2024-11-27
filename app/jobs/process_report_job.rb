require "open3"

class ProcessReportJob < ApplicationJob
  queue_as :default

  QUESTIONS_COUNT = 30

  def perform(report, questions_count: QUESTIONS_COUNT)
    events = []

    ActiveSupport::Notifications.instrument("analysis.operation", { step: self.class.name, units: 1 }) do |name, start, finish, id, payload|
      events << payload
    end

    report.processing!

    language_detector = Analysis::LanguageDetector.new(report: report)
    unless language_detector.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error detecting language: #{language_detector.error}"
      report.failed!
      return
    end
    language = language_detector.result
    Rails.logger.info "[Report #{report.id}] Language: #{language}"

    question_synthesis = Analysis::QuestionSynthesis.new(report: report, language: language, questions_count: questions_count)
    unless question_synthesis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error synthesizing questions: #{question_synthesis.error}"
      report.failed!
      return
    end
    questions = question_synthesis.result
    Rails.logger.info "[Report #{report.id}] Questions: #{questions.inspect}"

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

    entity_extractor = Analysis::EntityExtractor.new(report: report, language: language, answers: answers)
    unless entity_extractor.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error extracting entities: #{entity_extractor.error}"
      report.failed!
      return
    end
    entities = entity_extractor.result
    Rails.logger.info "[Report #{report.id}] Entities: #{entities.inspect}"

    competitors_analysis = Analysis::Competitors.new(report: report, language: language, entities: entities, topic: topic, answers: answers)
    unless competitors_analysis.perform_and_save
      Rails.logger.error "[Report #{report.id}] Error analyzing competitors: #{competitors_analysis.error}"
      report.failed!
      return
    end
    Rails.logger.info "[Report #{report.id}] Competitors: #{competitors_analysis.result.inspect}"
    report.completed!
  rescue => e
    Rails.logger.error "[Report #{report.id}] Error processing report: #{e.message}"
    e.backtrace.each { |line| Rails.logger.error "[Report #{report.id}] #{line}" }
    report.failed!
  ensure
    Rails.logger.info "[Report #{report.id}] Events received: #{events.inspect}"
  end
end
