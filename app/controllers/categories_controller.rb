class CategoriesController < ApplicationController
  allow_unauthenticated_access only: %i[index show] if Rails.env.development?

  def index
    categories = Category.left_joins(:articles)
                         .group(:id)
                         .select("categories.*, COUNT(articles.id) as articles_count")
                         .order("articles_count DESC")

    categories = categories.news if params[:taxonomy] == "news"
    categories = categories.dmoz if params[:taxonomy] == "dmoz"
    @categories = categories.page(params[:page]).per(50)
  end

  def show
    @category = Category.find(params[:id])
    @articles = @category.articles.recent.includes(:concepts, :calm_summaries).page(params[:page]).per(25)
  end
end
