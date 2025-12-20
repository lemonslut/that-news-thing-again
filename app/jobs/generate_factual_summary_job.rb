class GenerateFactualSummaryJob < ApplicationJob
  queue_as :default

  DEFAULT_MODEL = "openai/gpt-oss-120b".freeze

  def perform(article_id, model: nil)
    article = Article.find(article_id)
    return if article.factual_summary.present?

    model ||= DEFAULT_MODEL
    summary = call_llm(article, model)

    article.update!(factual_summary: summary.strip)
    Rails.logger.info "[GenerateFactualSummaryJob] Generated summary for article #{article_id}"

    # Chain to subject extraction
    ExtractSubjectsJob.perform_later(article_id)
  end

  private

  def call_llm(article, model)
    client = Completions::Client.new(model: model)
    client.complete([
      { role: "system", content: system_prompt },
      { role: "user", content: article_prompt(article) }
    ])
  end

  def system_prompt
    <<~PROMPT
      You are a neutral news summarizer. Respond with ONLY the summary - no preamble, labels, or explanation.

      Guidelines:
      - Write two factual sentences describing the key event and main actors involved (max 90 words)
      - Use past tense for events that happened, present for ongoing situations
      - Include specific names of people, organizations, and places central to the story
      - No opinions or sensationalism
      - Focus on WHO did WHAT, WHY, WHEN, WHERE, and WITH WHOM
    PROMPT
  end

  def article_prompt(article)
    <<~PROMPT
      Summarize this article in two factual sentences (max 90 words):

      Title: #{article.title}
      Content: #{article.content.presence || article.description}
    PROMPT
  end
end
