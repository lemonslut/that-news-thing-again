module Admin
  class ConceptsController < BaseController
    def index
      concepts = Concept.order(:label)
      concepts = concepts.of_type(params[:type]) if params[:type].present?
      concepts = concepts.where("label ILIKE ?", "%#{params[:q]}%") if params[:q].present?

      render_index(
        component: "Concepts/Index",
        records: concepts,
        serializer: method(:serialize_concept),
        types: Concept::TYPES
      )
    end

    def show
      concept = Concept.find(params[:id])

      render inertia: "Concepts/Show", props: {
        concept: serialize_concept_detail(concept)
      }
    end

    def edit
      concept = Concept.find(params[:id])

      render inertia: "Concepts/Form", props: {
        concept: serialize_concept(concept),
        types: Concept::TYPES
      }
    end

    def update
      concept = Concept.find(params[:id])

      if concept.update(concept_params)
        redirect_to admin_concept_path(concept), notice: "Concept updated"
      else
        redirect_to edit_admin_concept_path(concept), alert: concept.errors.full_messages.join(", ")
      end
    end

    def destroy
      Concept.find(params[:id]).destroy
      redirect_to admin_concepts_path, notice: "Concept deleted"
    end

    private

    def concept_params
      params.require(:concept).permit(:label, :concept_type, :uri)
    end

    def serialize_concept(concept)
      {
        id: concept.id,
        label: concept.label,
        concept_type: concept.concept_type,
        uri: concept.uri
      }
    end

    def serialize_concept_detail(concept)
      serialize_concept(concept).merge(
        articles_count: concept.articles.count,
        recent_articles: concept.articles.recent.limit(10).map do |a|
          { id: a.id, title: a.title, published_at: a.published_at&.iso8601 }
        end
      )
    end
  end
end
