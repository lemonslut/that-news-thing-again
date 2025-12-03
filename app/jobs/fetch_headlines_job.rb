class FetchHeadlinesJob < ApplicationJob
  queue_as :default

  def perform(country: "us", category: nil)
    client = NewsApi::Client.new
    result = client.top_headlines(country: country, category: category)

    return if result["status"] != "ok"

    articles = result["articles"] || []
    stored = 0
    skipped = 0

    articles.each do |article_data|
      next if article_data["title"].blank? || article_data["url"].blank?

      begin
        article = Article.upsert_from_news_api(article_data)
        AnalyzeArticleJob.perform_later(article.id)
        stored += 1
      rescue ActiveRecord::RecordNotUnique
        skipped += 1
      end
    end

    Rails.logger.info "[FetchHeadlinesJob] Stored #{stored}, skipped #{skipped} (country=#{country}, category=#{category})"

    { stored: stored, skipped: skipped, total: articles.size }
  end
end
