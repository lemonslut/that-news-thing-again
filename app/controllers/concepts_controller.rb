class ConceptsController < ApplicationController
  allow_unauthenticated_access only: %i[index show] if Rails.env.development?

  def index
    @view = params[:view] || "concepts"

    if @view == "subjects"
      concepts = Concept.left_joins(:article_subjects)
                        .group(:id)
                        .select("concepts.*, COUNT(article_subjects.id) as articles_count")
                        .having("COUNT(article_subjects.id) > 0")
                        .order("articles_count DESC")
    else
      concepts = Concept.left_joins(:article_concepts)
                        .group(:id)
                        .select("concepts.*, COUNT(article_concepts.id) as articles_count")
                        .order("articles_count DESC")
    end

    concepts = concepts.of_type(params[:type]) if params[:type].present?
    concepts = concepts.where("label ILIKE ?", "%#{params[:q]}%") if params[:q].present?

    @concepts = concepts.page(params[:page]).per(50)
  end

  def show
    @concept = Concept.find(params[:id])
    @articles = @concept.articles.recent.includes(:categories, :calm_summaries).page(params[:page]).per(25)
  end
end
