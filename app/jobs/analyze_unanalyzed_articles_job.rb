class AnalyzeUnanalyzedArticlesJob < ApplicationJob
  queue_as :default

  def perform(limit: 50)
    articles = Article.unanalyzed.limit(limit)
    count = 0

    articles.find_each do |article|
      AnalyzeArticleJob.perform_later(article.id)
      count += 1
    end

    Rails.logger.info "[AnalyzeUnanalyzedArticlesJob] Enqueued #{count} articles for analysis"

    { enqueued: count }
  end
end
