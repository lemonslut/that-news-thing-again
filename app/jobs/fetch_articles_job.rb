class FetchArticlesJob < ApplicationJob
  queue_as :default

  # Legacy job - replaced by StreamArticlesJob for minute-by-minute streaming.
  # Kept for manual backfills if needed.
  def perform(country: "us", count: 50)
    client = NewsApiAi::Client.new
    result = client.top_headlines(country: country, count: count)

    articles = result.dig("articles", "results") || []
    stored = 0
    skipped = 0

    articles.each do |article_data|
      next if article_data["title"].blank? || article_data["url"].blank?

      Article.upsert_from_news_api_ai(article_data)
      stored += 1
    rescue ActiveRecord::RecordNotUnique
      skipped += 1
    end

    Rails.logger.info "[FetchArticlesJob] Stored #{stored}, skipped #{skipped} (country=#{country})"

    { stored: stored, skipped: skipped, total: articles.size }
  end
end
