module ArticleAnalyzer
  extend ActiveSupport::Concern

  included do
    queue_as :analysis
  end

  class_methods do
    def analysis_type
      raise NotImplementedError, "Subclass must define analysis_type"
    end

    def default_model
      "openai/gpt-oss-120b"
    end

    def prompt_name
      analysis_type
    end
  end

  def perform(article_id, model: nil, prompt: nil, **options)
    @article = Article.find(article_id)
    @model = model || self.class.default_model
    @prompt_record = prompt || fetch_prompt
    @options = options

    result = call_llm
    record_analysis(result)
    post_process(result)

    Rails.logger.info "[#{self.class.name}] Completed #{self.class.analysis_type} for article #{article_id}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[#{self.class.name}] Article #{article_id} not found, skipping"
  end

  private

  attr_reader :article, :model, :prompt_record, :options

  def fetch_prompt
    Prompt.current(self.class.prompt_name)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def call_llm
    client = Completions::Client.new(model: model)
    client.complete(messages, json: true)
  end

  def messages
    [
      { role: "system", content: system_prompt },
      { role: "user", content: user_prompt }
    ]
  end

  def system_prompt
    prompt_record&.body || default_system_prompt
  end

  def default_system_prompt
    raise NotImplementedError, "Subclass must define default_system_prompt"
  end

  def user_prompt
    raise NotImplementedError, "Subclass must define user_prompt"
  end

  def extract_result(_llm_response)
    raise NotImplementedError, "Subclass must define extract_result"
  end

  def post_process(_result)
    # Default: no-op. Override in subclass for side effects.
  end

  def record_analysis(llm_response)
    ArticleAnalysis.create!(
      article: article,
      prompt: prompt_record,
      analysis_type: self.class.analysis_type,
      model_used: model,
      result: extract_result(llm_response),
      raw_response: llm_response
    )
  end
end
