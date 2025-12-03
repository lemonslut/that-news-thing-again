class EntitiesController < ApplicationController
  def index
    @entities = Entity.all
    @entities = @entities.of_type(params[:type]) if params[:type].present?
    @entities = @entities.joins(:article_entities)
                         .group(:id)
                         .select("entities.*, COUNT(article_entities.id) as articles_count")
                         .order(Arel.sql("COUNT(article_entities.id) DESC"))
  end

  def show
    @entity = Entity.find(params[:id])
    @articles = @entity.articles
                       .includes(:entities, :calm_summaries)
                       .order(published_at: :desc)
  end
end
