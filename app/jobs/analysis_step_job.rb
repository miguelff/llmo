class AnalysisStepJob < ApplicationJob
  queue_as :priority
  limits_concurrency to: 1, key: ->(step) { [ step.analysis_id, step.type ] }

  retry_on StandardError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError, NameError, ArgumentError

  def perform(step)
      step.perform_if_valid
  end
end
