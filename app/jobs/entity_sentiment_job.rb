class EntitySentimentJob < ApplicationJob
  include ArticleAnalyzer

  def self.analysis_type
    "entity_sentiment"
  end

  def perform(article_id, model: nil, prompt: nil, **options)
    @article = Article.find(article_id)

    unless article_has_entities?
      Rails.logger.info "[EntitySentimentJob] No entities for article #{article_id}, skipping"
      return
    end

    @model = model || self.class.default_model
    @prompt_record = prompt || fetch_prompt
    @options = options

    result = call_llm
    record_analysis(result)
    post_process(result)

    Rails.logger.info "[EntitySentimentJob] Completed entity_sentiment for article #{article_id}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[EntitySentimentJob] Article #{article_id} not found, skipping"
  end

  private

  def article_has_entities?
    article.concepts.any? || article.analyses.ner_extractions.any?
  end

  def entities_for_analysis
    if article.concepts.any?
      {
        "people" => article.people.pluck(:label),
        "organizations" => article.organizations.pluck(:label),
        "locations" => article.locations.pluck(:label)
      }
    else
      ner = article.analyses.ner_extractions.latest.first
      ner&.entities || {}
    end
  end

  def default_system_prompt
    <<~PROMPT
      You are a sentiment analysis expert. Analyze how specific entities are portrayed in news articles.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation.

      The JSON must contain:
      - entity_sentiments: An array of objects, each with:
        - entity: The entity name (exactly as provided)
        - type: The entity type (person, organization, location)
        - sentiment: A number from -1.0 to 1.0
        - label: One of "positive", "negative", or "neutral"
        - context: Brief description of how the entity is portrayed

      Guidelines:
      - Only analyze entities actually mentioned in the article
      - Consider the context and framing around each entity
      - A neutral mention is different from no mention
    PROMPT
  end

  def user_prompt
    entities = entities_for_analysis
    entity_list = []

    %w[people organizations locations].each do |type|
      (entities[type] || []).each do |name|
        entity_list << "- #{name} (#{type.singularize})"
      end
    end

    <<~PROMPT
      Analyze sentiment towards these entities in the article:

      Entities to analyze:
      #{entity_list.join("\n")}

      Article:
      Title: #{article.title}
      Content: #{article.content}
    PROMPT
  end

  def extract_result(llm_response)
    { "entity_sentiments" => llm_response["entity_sentiments"] }
  end
end
