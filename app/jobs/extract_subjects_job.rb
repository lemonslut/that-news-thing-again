class ExtractSubjectsJob < ApplicationJob
  queue_as :default

  DEFAULT_MODEL = "anthropic/claude-3-haiku".freeze

  def perform(article_id, model: nil)
    article = Article.find(article_id)
    return if article.factual_summary.blank?
    return if article.article_subjects.any?

    model ||= DEFAULT_MODEL
    result = call_llm(article, model)

    create_subjects(article, result["subjects"])
    Rails.logger.info "[ExtractSubjectsJob] Extracted #{result['subjects'].size} subjects for article #{article_id}"

    # Chain to clustering
    ClusterArticleJob.perform_later(article_id)
  end

  private

  def call_llm(article, model)
    client = Completions::Client.new(model: model)
    client.complete([
      { role: "system", content: system_prompt },
      { role: "user", content: article.factual_summary }
    ], json: true)
  end

  def system_prompt
    <<~PROMPT
      Extract the key subjects from this news summary. Subjects are the main entities the story is ABOUT.

      IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation, just the JSON object.

      The JSON must contain:
      - subjects: Array of objects, each with:
        - label: The canonical name (e.g., "Donald Trump", "Apple Inc.", "New York City")
        - type: One of "person", "org", "loc", "event"

      Guidelines:
      - Only extract 2-5 most important subjects
      - Use full proper names, not pronouns or abbreviations
      - "person" for individuals
      - "org" for companies, government agencies, sports teams, political parties
      - "loc" for cities, countries, regions, landmarks
      - "event" for named events (elections, conferences, disasters)
      - DO NOT include generic concepts like "news", "report", "announcement"
    PROMPT
  end

  def create_subjects(article, subjects)
    subjects.each do |subject|
      concept = find_or_create_concept(subject)
      article.article_subjects.find_or_create_by!(concept: concept)
    end
  end

  def find_or_create_concept(subject)
    label = subject["label"].strip
    concept_type = subject["type"]
    uri = "llm://#{concept_type}/#{label.downcase.gsub(/\s+/, '-')}"

    Concept.find_or_create_by!(uri: uri) do |c|
      c.concept_type = concept_type
      c.label = label
    end
  end
end
