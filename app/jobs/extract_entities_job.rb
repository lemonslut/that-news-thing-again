class ExtractEntitiesJob < ApplicationJob
  queue_as :default

  DEFAULT_MODEL = "anthropic/claude-3-haiku".freeze

  def perform(article_id, model: nil, prompt: nil)
    article = Article.find(article_id)
    model ||= DEFAULT_MODEL

    prompt_record = prompt || Prompt.current("entity_extraction") rescue nil
    result = call_llm(article, model, prompt_record)

    extraction = ArticleEntityExtraction.create!(
      article: article,
      prompt: prompt_record,
      model_used: model,
      raw_response: result
    )

    extraction.link_entities_from_result(result)

    Rails.logger.info "[ExtractEntitiesJob] Extracted entities for article #{article_id}"
  end

  private

  def call_llm(article, model, prompt_record)
    client = Completions::Client.new(model: model)
    client.complete([
      { role: "system", content: system_prompt(prompt_record) },
      { role: "user", content: article_prompt(article) }
    ], json: true)
  end

  def system_prompt(prompt_record)
    prompt_record&.body || default_system_prompt
  end

  def default_system_prompt
    <<~PROMPT
      You are an entity extraction system. Extract entities from news articles.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation, just the JSON object.

      The JSON must contain:
      - category: One of [politics, business, technology, health, science, entertainment, sports, world, environment, other]
      - tags: Array of 3-5 lowercase tags for trend tracking (e.g., ["election", "senate", "voting-rights"])
      - entities: Object with arrays for "people", "organizations", and "places" mentioned in the story

      Use consistent naming:
      - People: "firstname lastname" format, lowercase (e.g., "tim cook", "joe biden")
      - Organizations: lowercase (e.g., "apple", "united nations")
      - Places: lowercase (e.g., "new york", "hong kong")
    PROMPT
  end

  def article_prompt(article)
    <<~PROMPT
      Extract entities from this article:

      Source: #{article.source_name}
      Title: #{article.title}
      Description: #{article.description}
      Content: #{article.content}
      Published: #{article.published_at}
    PROMPT
  end
end
