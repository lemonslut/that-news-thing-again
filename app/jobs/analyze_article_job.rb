class AnalyzeArticleJob < ApplicationJob
  queue_as :default

  def perform(article_id, model: nil)
    article = Article.find(article_id)

    return if article.analysis.present?

    client = Completions::Client.new(model: model)
    result = client.analyze_article(article)

    ArticleAnalysis.create!(
      article: article,
      category: result["category"],
      tags: result["tags"] || [],
      entities: result["entities"] || {},
      political_lean: result["political_lean"],
      calm_summary: result["calm_summary"],
      model_used: model || Completions::Client::DEFAULT_MODEL,
      raw_response: result
    )

    Rails.logger.info "[AnalyzeArticleJob] Analyzed article #{article_id}: #{result['category']} - #{result['calm_summary']}"
  end
end
