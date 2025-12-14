class FetchArticlesJob < ApplicationJob
  queue_as :default

  def perform(country: "us", count: 50)
    client = NewsApiAi::Client.new
    result = client.top_headlines(country: country, count: count)

    articles = result.dig("articles", "results") || []
    stored = 0
    skipped = 0

    articles.each do |article_data|
      next if article_data["title"].blank? || article_data["url"].blank?

      begin
        article = Article.upsert_from_news_api_ai(article_data)
        enqueue_analysis_pipeline(article)
        stored += 1
      rescue ActiveRecord::RecordNotUnique
        skipped += 1
      end
    end

    Rails.logger.info "[FetchArticlesJob] Stored #{stored}, skipped #{skipped} (country=#{country})"

    { stored: stored, skipped: skipped, total: articles.size }
  end

  private

  def enqueue_analysis_pipeline(article)
    # Phase 1: Independent analyses (can run in parallel)
    CalmSummaryAnalysisJob.perform_later(article.id)
    GeneralSentimentJob.perform_later(article.id)
    NerExtractionJob.perform_later(article.id)

    # Phase 2: Dependent analyses (entity_sentiment needs NER first)
    EntitySentimentJob.set(wait: 30.seconds).perform_later(article.id)
  end
end
