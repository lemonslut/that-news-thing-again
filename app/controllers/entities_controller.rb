class EntitiesController < ApplicationController
  def index
    @entities = Entity.all
    @entities = @entities.of_type(params[:type]) if params[:type].present?
    @entities = @entities.joins(:article_analysis_entities)
                         .group(:id)
                         .select("entities.*, COUNT(article_analysis_entities.id) as articles_count")
                         .order(Arel.sql("COUNT(article_analysis_entities.id) DESC"))
  end

  def show
    @entity = Entity.find(params[:id])
    @articles = Article.joins(analysis: :linked_entities)
                       .where(entities: { id: @entity.id })
                       .includes(:analysis)
                       .order(published_at: :desc)
  end
end
