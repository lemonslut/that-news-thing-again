class GenerateCalmSummaryJob < ApplicationJob
  queue_as :default

  DEFAULT_MODEL = "anthropic/claude-3-haiku".freeze

  def perform(article_id, model: nil, prompt: nil)
    article = Article.find(article_id)
    model ||= DEFAULT_MODEL

    prompt_record = prompt || Prompt.current("calm_summary") rescue nil
    result = call_llm(article, model, prompt_record)

    ArticleCalmSummary.create!(
      article: article,
      prompt: prompt_record,
      model_used: model,
      summary: result["calm_summary"],
      raw_response: result
    )

    Rails.logger.info "[GenerateCalmSummaryJob] Generated summary for article #{article_id}: #{result['calm_summary']}"
  end

  private

  def call_llm(article, model, prompt_record)
    client = Completions::Client.new(model: model)
    client.complete([
      { role: "system", content: system_prompt(prompt_record) },
      { role: "user", content: article_prompt(article) }
    ], json: true)
  end

  def system_prompt(prompt_record)
    prompt_record&.body || default_system_prompt
  end

  def default_system_prompt
    <<~PROMPT
      You are a calm news summarizer. Your job is to distill news into simple, peaceful summaries.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation, just the JSON object.

      The JSON must contain:
      - calm_summary: A single calm, simple sentence describing what happened. No sensationalism. Present tense. Like you're whispering the news to a friend. Max 20 words.

      Example calm_summary: "A fire in Hong Kong has killed several people and rescue efforts continue."

      Guidelines:
      - Use present tense
      - No dramatic language or exclamation points
      - Focus on facts, not emotions
      - Keep it under 20 words
      - Imagine you're telling a friend over coffee
    PROMPT
  end

  def article_prompt(article)
    <<~PROMPT
      Summarize this article calmly:

      Source: #{article.source_name}
      Title: #{article.title}
      Description: #{article.description}
      Content: #{article.content}
      Published: #{article.published_at}
    PROMPT
  end
end
