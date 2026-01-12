module Admin
  class ArticlesController < BaseController
    def index
      articles = Article.recent.includes(:story, :categories)
      articles = apply_filters(articles)

      render_index(
        component: "Articles/Index",
        records: articles,
        serializer: method(:serialize_article),
        filters: filter_options
      )
    end

    def show
      article = Article.includes(:story, :analyses, :concepts, :categories).find(params[:id])

      render inertia: "Articles/Show", props: {
        article: serialize_article_detail(article)
      }
    end

    def edit
      article = Article.find(params[:id])

      render inertia: "Articles/Form", props: {
        article: serialize_article(article),
        stories: Story.recent.limit(100).pluck(:title, :id).map { |t, id| { label: t, value: id } }
      }
    end

    def update
      article = Article.find(params[:id])

      if article.update(article_params)
        redirect_to admin_article_path(article), notice: "Article updated"
      else
        redirect_to edit_admin_article_path(article), alert: article.errors.full_messages.join(", ")
      end
    end

    def destroy
      Article.find(params[:id]).destroy
      redirect_to admin_articles_path, notice: "Article deleted"
    end

    def reanalyze
      article = Article.find(params[:id])
      GenerateFactualSummaryJob.perform_later(article.id)
      redirect_to admin_article_path(article), notice: "Re-analysis queued"
    end

    private

    def article_params
      params.require(:article).permit(:title, :description, :content, :story_id, :factual_summary)
    end

    def apply_filters(scope)
      scope = scope.from_source(params[:source]) if params[:source].present?
      scope = scope.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      scope
    end

    def filter_options
      {
        sources: Article.distinct.pluck(:source_name).compact.sort
      }
    end

    def serialize_article(article)
      {
        id: article.id,
        title: article.title,
        source_name: article.source_name,
        published_at: article.published_at&.iso8601,
        story: article.story&.slice(:id, :title),
        categories: article.categories.limit(3).map { |c| { id: c.id, label: c.short_name } },
        has_summary: article.factual_summary.present?
      }
    end

    def serialize_article_detail(article)
      serialize_article(article).merge(
        description: article.description,
        content: article.content,
        factual_summary: article.factual_summary,
        url: article.url,
        image_url: article.image_url,
        sentiment: article.sentiment&.to_f,
        language: article.language,
        is_duplicate: article.is_duplicate,
        analyses: article.analyses.map { |a| serialize_analysis(a) },
        concepts: article.concepts.map { |c| serialize_concept(c) },
        categories: article.categories.map { |c| { id: c.id, label: c.label, uri: c.uri } }
      )
    end

    def serialize_analysis(analysis)
      {
        id: analysis.id,
        analysis_type: analysis.analysis_type,
        model_used: analysis.model_used,
        created_at: analysis.created_at.iso8601
      }
    end

    def serialize_concept(concept)
      {
        id: concept.id,
        label: concept.label,
        concept_type: concept.concept_type,
        uri: concept.uri
      }
    end
  end
end
