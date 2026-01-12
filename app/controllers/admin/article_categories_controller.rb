module Admin
  class ArticleCategoriesController < BaseController
    def index
      article_categories = ArticleCategory.includes(:article, :category).order(created_at: :desc)

      render_index(
        component: "ArticleCategories/Index",
        records: article_categories,
        serializer: method(:serialize_article_category)
      )
    end

    def destroy
      ArticleCategory.find(params[:id]).destroy
      redirect_to admin_article_categories_path, notice: "Article-category link deleted"
    end

    private

    def serialize_article_category(ac)
      {
        id: ac.id,
        weight: ac.weight,
        article: { id: ac.article.id, title: ac.article.title },
        category: { id: ac.category.id, label: ac.category.label }
      }
    end
  end
end
