class GenerateFactualSummaryJob < ApplicationJob
  queue_as :default

  DEFAULT_MODEL = "openai/gpt-oss-120b".freeze

  def perform(article_id, model: nil)
    article = Article.find(article_id)
    return if article.factual_summary.present?

    model ||= DEFAULT_MODEL
    result = call_llm(article, model)

    article.update!(factual_summary: result["summary"])
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
    ], json: true)
  end

  def system_prompt
    <<~PROMPT
      You are a neutral news summarizer. Your job is to distill articles into factual one-sentence summaries.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation, just the JSON object.

      The JSON must contain:
      - summary: A single factual sentence describing the key event, including the main actors involved. Max 30 words.

      Guidelines:
      - Use past tense for events that happened, present for ongoing situations
      - Include specific names of people, organizations, and places central to the story
      - No opinions or sensationalism
      - Focus on WHO did WHAT, WHY, WHEN, WHERE, and WITH WHOM
      - Be specific rather than vague
    PROMPT
  end

  def article_prompt(article)
    <<~PROMPT
      Summarize this article in one factual sentence:

      Title: #{article.title}
      Content: #{article.content.presence || article.description}
    PROMPT
  end
end
