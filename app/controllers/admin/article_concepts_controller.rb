module Admin
  class ArticleConceptsController < BaseController
    def index
      article_concepts = ArticleConcept.includes(:article, :concept).order(created_at: :desc)

      render_index(
        component: "ArticleConcepts/Index",
        records: article_concepts,
        serializer: method(:serialize_article_concept)
      )
    end

    def destroy
      ArticleConcept.find(params[:id]).destroy
      redirect_to admin_article_concepts_path, notice: "Article-concept link deleted"
    end

    private

    def serialize_article_concept(ac)
      {
        id: ac.id,
        score: ac.score,
        article: { id: ac.article.id, title: ac.article.title },
        concept: { id: ac.concept.id, label: ac.concept.label, concept_type: ac.concept.concept_type }
      }
    end
  end
end
