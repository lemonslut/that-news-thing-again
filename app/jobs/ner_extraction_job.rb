class NerExtractionJob < ApplicationJob
  include ArticleAnalyzer

  def self.analysis_type
    "ner_extraction"
  end

  private

  def default_system_prompt
    <<~PROMPT
      You are a named entity recognition expert. Extract entities from news articles.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation.

      The JSON must contain:
      - entities: An object with arrays for each entity type:
        - people: Array of person names mentioned
        - organizations: Array of organization/company names
        - locations: Array of place names (cities, countries, regions)
        - topics: Array of key topics/subjects (e.g., "artificial intelligence", "climate change")

      Guidelines:
      - Extract actual named entities, not generic terms
      - Normalize names to their full form when possible
      - Include only entities actually mentioned in the article
      - For people, use their full name as it appears
      - For organizations, use official names
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Extract named entities from this article:

      Title: #{article.title}
      Content: #{article.content}
    PROMPT
  end

  def extract_result(llm_response)
    { "entities" => llm_response["entities"] }
  end

  def post_process(result)
    entities = result.dig("entities") || {}
    create_concepts_from_entities(entities)
  end

  def create_concepts_from_entities(entities)
    type_mapping = {
      "people" => "person",
      "organizations" => "org",
      "locations" => "loc",
      "topics" => "wiki"
    }

    type_mapping.each do |json_key, concept_type|
      (entities[json_key] || []).each do |label|
        next if label.blank?

        concept = find_or_create_concept(label, concept_type)
        link_article_to_concept(concept) if concept
      end
    end
  end

  def find_or_create_concept(label, concept_type)
    normalized_label = label.strip
    uri = generate_uri(normalized_label, concept_type)

    Concept.find_or_create_by!(uri: uri) do |c|
      c.concept_type = concept_type
      c.label = normalized_label
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "[NerExtractionJob] Failed to create concept: #{e.message}"
    nil
  end

  def generate_uri(label, concept_type)
    slug = label.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
    "llm://#{concept_type}/#{slug}"
  end

  def link_article_to_concept(concept)
    ArticleConcept.find_or_create_by!(article: article, concept: concept) do |ac|
      ac.score = 3
    end
  rescue ActiveRecord::RecordInvalid
    # Already linked
  end
end
