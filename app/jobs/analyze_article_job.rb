class AnalyzeArticleJob < ApplicationJob
  queue_as :default

  def perform(article_id, model: nil, prompt: nil)
    article = Article.find(article_id)

    return if article.analysis.present?

    prompt ||= Prompt.current("article_analysis") rescue nil
    client = Completions::Client.new(model: model, prompt: prompt)
    response = client.analyze_article(article)
    result = response[:result]

    political_lean = result["political_lean"]
    political_lean = nil if political_lean.nil? || political_lean == "null" || !ArticleAnalysis::POLITICAL_LEANS.include?(political_lean)

    analysis = ArticleAnalysis.create!(
      article: article,
      prompt: response[:prompt],
      category: result["category"],
      tags: result["tags"] || [],
      entities: result["entities"] || {},
      political_lean: political_lean,
      calm_summary: result["calm_summary"],
      model_used: model || Completions::Client::DEFAULT_MODEL,
      raw_response: result
    )

    analysis.link_entities_from_result(result, article)

    Rails.logger.info "[AnalyzeArticleJob] Analyzed article #{article_id}: #{result['category']} - #{result['calm_summary']}"
  end
end
