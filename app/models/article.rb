class Article < ApplicationRecord
  has_many :calm_summaries, class_name: "ArticleCalmSummary", dependent: :destroy

  has_many :article_concepts, dependent: :destroy
  has_many :concepts, through: :article_concepts

  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories

  validates :source_name, :title, :url, :published_at, presence: true
  validates :url, uniqueness: true

  scope :recent, -> { order(published_at: :desc) }
  scope :from_source, ->(name) { where(source_name: name) }
  scope :published_after, ->(time) { where("published_at > ?", time) }
  scope :published_before, ->(time) { where("published_at < ?", time) }
  scope :with_summary, -> { joins(:calm_summaries).distinct }
  scope :without_summary, -> { left_joins(:calm_summaries).where(article_calm_summaries: { id: nil }) }
  scope :in_language, ->(lang) { where(language: lang) }
  scope :positive_sentiment, -> { where("sentiment > 0") }
  scope :negative_sentiment, -> { where("sentiment < 0") }
  scope :duplicates, -> { where(is_duplicate: true) }
  scope :originals, -> { where(is_duplicate: false) }

  # Concept-based scopes
  scope :with_concept, ->(uri) { joins(:concepts).where(concepts: { uri: uri }) }
  scope :with_concept_type, ->(type) { joins(:concepts).where(concepts: { concept_type: type }).distinct }
  scope :with_person, ->(label) { joins(:concepts).where(concepts: { concept_type: "person", label: label }) }
  scope :with_organization, ->(label) { joins(:concepts).where(concepts: { concept_type: "org", label: label }) }
  scope :with_location, ->(label) { joins(:concepts).where(concepts: { concept_type: "loc", label: label }) }

  # Category-based scopes
  scope :in_category, ->(uri) { joins(:categories).where(categories: { uri: uri }) }

  def calm_summary
    calm_summaries.order(created_at: :desc).first
  end

  def people
    concepts.where(concept_type: "person")
  end

  def organizations
    concepts.where(concept_type: "org")
  end

  def locations
    concepts.where(concept_type: "loc")
  end

  def topics
    concepts.where(concept_type: "wiki")
  end

  def primary_category
    article_categories.order(weight: :desc).first&.category
  end

  def self.from_news_api_ai(article_hash)
    new(
      source_id: article_hash.dig("source", "uri"),
      source_name: article_hash.dig("source", "title") || article_hash.dig("source", "uri"),
      author: article_hash.dig("authors", 0, "name"),
      title: article_hash["title"],
      description: article_hash["body"]&.truncate(500),
      url: article_hash["url"],
      image_url: article_hash["image"],
      published_at: article_hash["dateTimePub"] || article_hash["dateTime"],
      content: article_hash["body"],
      sentiment: article_hash["sentiment"],
      language: article_hash["lang"],
      event_uri: article_hash["eventUri"],
      is_duplicate: article_hash["isDuplicate"] || false,
      raw_payload: article_hash
    )
  end

  def self.upsert_from_news_api_ai(article_hash)
    article = from_news_api_ai(article_hash)
    existing = find_by(url: article.url)

    if existing
      existing.update(
        raw_payload: article_hash,
        content: article.content,
        sentiment: article.sentiment,
        language: article.language,
        event_uri: article.event_uri,
        is_duplicate: article.is_duplicate
      )
      existing
    else
      article.save!
      article
    end
  end
end
