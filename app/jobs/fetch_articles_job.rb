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
        extract_concepts(article, article_data)
        extract_categories(article, article_data)
        GenerateCalmSummaryJob.perform_later(article.id)
        stored += 1
      rescue ActiveRecord::RecordNotUnique
        skipped += 1
      end
    end

    Rails.logger.info "[FetchArticlesJob] Stored #{stored}, skipped #{skipped} (country=#{country})"

    { stored: stored, skipped: skipped, total: articles.size }
  end

  private

  def extract_concepts(article, article_data)
    concepts = article_data["concepts"] || []

    concepts.each do |concept_hash|
      concept = Concept.find_or_create_from_api(concept_hash)
      next unless concept

      score = concept_hash["score"]
      article.article_concepts.find_or_create_by!(concept: concept) do |ac|
        ac.score = score
      end
    end
  end

  def extract_categories(article, article_data)
    categories = article_data["categories"] || []

    categories.each do |category_hash|
      category = Category.find_or_create_from_api(category_hash)
      next unless category

      weight = category_hash["wgt"]
      article.article_categories.find_or_create_by!(category: category) do |ac|
        ac.weight = weight
      end
    end
  end
end
