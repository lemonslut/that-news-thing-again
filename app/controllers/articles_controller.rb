class ArticlesController < ApplicationController
  def index
    @articles = Article.with_entities.recent.includes(:entities, :calm_summaries)
    @articles = @articles.in_category(params[:category]) if params[:category].present?
  end

  def show
    @article = Article.includes(:entities, :calm_summaries, :entity_extractions).find(params[:id])
    @entity_prompts = Prompt.where(name: "entity_extraction").order(version: :desc)
    @summary_prompts = Prompt.where(name: "calm_summary").order(version: :desc)
  end

  def reanalyze
    @article = Article.find(params[:id])

    case params[:type]
    when "entities"
      rerun_entity_extraction
    when "summary"
      rerun_summary_generation
    else
      rerun_entity_extraction
      rerun_summary_generation
    end

    redirect_to @article, notice: "Re-analysis started"
  rescue StandardError => e
    redirect_to @article, alert: "Analysis failed: #{e.message}"
  end

  private

  def rerun_entity_extraction
    prompt = resolve_prompt("entity_extraction", params[:entity_prompt_id], params[:custom_entity_prompt])
    ExtractEntitiesJob.perform_now(@article.id, prompt: prompt)
  end

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
