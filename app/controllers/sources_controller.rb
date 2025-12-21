class SourcesController < ApplicationController
  allow_unauthenticated_access only: %i[index show] if Rails.env.development?

  def index
    @sources = Article.group(:source_name)
                      .select("source_name, COUNT(*) as article_count, MAX(published_at) as latest_article_at")
                      .order("article_count DESC")
                      .page(params[:page]).per(50)
  end

  def show
    @source_name = params[:name]
    @articles = Article.from_source(@source_name)
                       .recent
                       .includes(:concepts, :categories, :calm_summaries)
                       .page(params[:page]).per(25)
  end
end
