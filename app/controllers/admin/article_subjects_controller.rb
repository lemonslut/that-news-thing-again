module Admin
  class ArticleSubjectsController < BaseController
    def index
      article_subjects = ArticleSubject.includes(:article, :concept).order(created_at: :desc)

      render_index(
        component: "ArticleSubjects/Index",
        records: article_subjects,
        serializer: method(:serialize_article_subject)
      )
    end

    def destroy
      ArticleSubject.find(params[:id]).destroy
      redirect_to admin_article_subjects_path, notice: "Article-subject link deleted"
    end

    private

    def serialize_article_subject(as)
      {
        id: as.id,
        article: { id: as.article.id, title: as.article.title },
        concept: { id: as.concept.id, label: as.concept.label, concept_type: as.concept.concept_type }
      }
    end
  end
end
