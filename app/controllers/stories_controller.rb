class StoriesController < ApplicationController
  allow_unauthenticated_access only: %i[index show] if Rails.env.development?

  def index
    stories = Story.includes(:articles)
                   .multi_source
                   .recent

    stories = stories.active if params[:active] == "1"
    @stories = stories.page(params[:page]).per(25)
  end

  def show
    @story = Story.includes(articles: [:concepts, :categories, :calm_summaries]).find(params[:id])
    @articles = @story.articles.order(published_at: :asc)
  end
end
