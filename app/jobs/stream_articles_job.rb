class StreamArticlesJob < ApplicationJob
  queue_as :default

  def perform
    after_uri = Article.recent.first&.uri
    client = NewsApiAi::Client.new

    result = client.minute_stream_articles(
      after_uri: after_uri,
      source_location_uri: "http://en.wikipedia.org/wiki/United_States"
    )

    articles = result.dig("recentActivityArticles", "activity") || []
    stored = 0

    articles.each do |article_data|
      next if article_data["title"].blank? || article_data["url"].blank?

      Article.upsert_from_news_api_ai(article_data)
      stored += 1
    rescue ActiveRecord::RecordNotUnique
      # Already have it, that's fine
    end

    Rails.logger.info "[StreamArticlesJob] Stored #{stored} articles" if stored > 0
  end
end
