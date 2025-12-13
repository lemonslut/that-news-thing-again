class ConceptsController < ApplicationController
  allow_unauthenticated_access only: %i[index show] if Rails.env.development?

  def index
    concepts = Concept.left_joins(:articles)
                      .group(:id)
                      .select("concepts.*, COUNT(articles.id) as articles_count")
                      .order("articles_count DESC")

    concepts = concepts.of_type(params[:type]) if params[:type].present?
    @concepts = concepts.page(params[:page]).per(50)
  end

  def show
    @concept = Concept.find(params[:id])
    @articles = @concept.articles.recent.includes(:categories, :calm_summaries).page(params[:page]).per(25)
  end
end
