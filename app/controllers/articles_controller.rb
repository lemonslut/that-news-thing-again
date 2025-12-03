class ArticlesController < ApplicationController
  def index
    @articles = Article.analyzed.recent.includes(:analysis)
    @articles = @articles.joins(:analysis).where(article_analyses: { category: params[:category] }) if params[:category].present?
  end

  def show
    @article = Article.find(params[:id])
    @prompts = Prompt.where(name: "article_analysis").order(version: :desc)
  end

  def reanalyze
    @article = Article.find(params[:id])
    @article.analysis&.destroy

    prompt = if params[:prompt_id].present?
      Prompt.find(params[:prompt_id])
    elsif params[:custom_prompt].present?
      Prompt.create!(
        name: "article_analysis",
        version: (Prompt.where(name: "article_analysis").maximum(:version) || 0) + 1,
        body: params[:custom_prompt],
        active: false
      )
    else
      Prompt.current("article_analysis") rescue nil
    end

    AnalyzeArticleJob.perform_now(@article.id, prompt: prompt)

    redirect_to @article, notice: "Article re-analyzed with #{prompt&.to_s || 'default prompt'}"
  rescue StandardError => e
    redirect_to @article, alert: "Analysis failed: #{e.message}"
  end
end
