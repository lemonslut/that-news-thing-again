module Admin
  class CategoriesController < BaseController
    def index
      categories = Category.order(:label)
      categories = categories.where("label ILIKE ? OR uri ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?

      render_index(
        component: "Categories/Index",
        records: categories,
        serializer: method(:serialize_category)
      )
    end

    def show
      category = Category.find(params[:id])

      render inertia: "Categories/Show", props: {
        category: serialize_category_detail(category)
      }
    end

    def edit
      category = Category.find(params[:id])

      render inertia: "Categories/Form", props: {
        category: serialize_category(category)
      }
    end

    def update
      category = Category.find(params[:id])

      if category.update(category_params)
        redirect_to admin_category_path(category), notice: "Category updated"
      else
        redirect_to edit_admin_category_path(category), alert: category.errors.full_messages.join(", ")
      end
    end

    def destroy
      Category.find(params[:id]).destroy
      redirect_to admin_categories_path, notice: "Category deleted"
    end

    private

    def category_params
      params.require(:category).permit(:label, :uri)
    end

    def serialize_category(category)
      {
        id: category.id,
        label: category.label,
        uri: category.uri
      }
    end

    def serialize_category_detail(category)
      serialize_category(category).merge(
        articles_count: category.articles.count,
        recent_articles: category.articles.recent.limit(10).map do |a|
          { id: a.id, title: a.title, published_at: a.published_at&.iso8601 }
        end
      )
    end
  end
end
