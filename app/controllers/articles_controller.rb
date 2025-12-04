class ArticlesController < ApplicationController
  def index
    @articles = Article.recent.includes(:concepts, :categories, :calm_summaries)
    @articles = @articles.in_category(params[:category]) if params[:category].present?
    @articles = @articles.with_concept_type(params[:concept_type]) if params[:concept_type].present?
    @articles = @articles.in_language(params[:language]) if params[:language].present?
  end

  def show
    @article = Article.includes(:concepts, :categories, :calm_summaries).find(params[:id])
    @summary_prompts = Prompt.where(name: "calm_summary").order(version: :desc)
  end

  def reanalyze
    @article = Article.find(params[:id])
    rerun_summary_generation
    redirect_to @article, notice: "Re-analysis started"
  rescue StandardError => e
    redirect_to @article, alert: "Analysis failed: #{e.message}"
  end

  private

  def rerun_summary_generation
    prompt = resolve_prompt("calm_summary", params[:summary_prompt_id], params[:custom_summary_prompt])
    GenerateCalmSummaryJob.perform_now(@article.id, prompt: prompt)
  end

  def resolve_prompt(name, prompt_id, custom_body)
    if prompt_id.present?
      Prompt.find(prompt_id)
    elsif custom_body.present?
      Prompt.create!(
        name: name,
        version: (Prompt.where(name: name).maximum(:version) || 0) + 1,
        body: custom_body,
        active: false
      )
    else
      Prompt.current(name) rescue nil
    end
  end
end
