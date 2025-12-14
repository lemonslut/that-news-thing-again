class GeneralSentimentJob < ApplicationJob
  include ArticleAnalyzer

  def self.analysis_type
    "general_sentiment"
  end

  private

  def default_system_prompt
    <<~PROMPT
      You are a sentiment analysis expert. Analyze the overall sentiment of news articles.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation.

      The JSON must contain:
      - sentiment: A number from -1.0 (very negative) to 1.0 (very positive)
      - label: One of "positive", "negative", or "neutral"
      - confidence: A number from 0.0 to 1.0 indicating confidence in the assessment
      - reasoning: Brief explanation (1-2 sentences) of why this sentiment was assigned

      Guidelines:
      - Consider the overall tone, not just individual words
      - News reporting factual events neutrally should be "neutral"
      - Distinguish between the subject matter (a tragedy) and reporting tone (neutral)
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Analyze the sentiment of this article:

      Title: #{article.title}
      Content: #{article.content}
    PROMPT
  end

  def extract_result(llm_response)
    {
      "sentiment" => llm_response["sentiment"],
      "label" => llm_response["label"],
      "confidence" => llm_response["confidence"],
      "reasoning" => llm_response["reasoning"]
    }
  end
end
