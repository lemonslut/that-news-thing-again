class CalmSummaryAnalysisJob < ApplicationJob
  include ArticleAnalyzer

  def self.analysis_type
    "calm_summary"
  end

  private

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

  def user_prompt
    <<~PROMPT
      Summarize this article calmly:

      Source: #{article.source_name}
      Title: #{article.title}
      Description: #{article.description}
      Content: #{article.content}
      Published: #{article.published_at}
    PROMPT
  end

  def extract_result(llm_response)
    { "calm_summary" => llm_response["calm_summary"] }
  end
end
