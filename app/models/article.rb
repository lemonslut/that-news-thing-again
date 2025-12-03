class Article < ApplicationRecord
  has_many :entity_extractions, class_name: "ArticleEntityExtraction", dependent: :destroy
  has_many :calm_summaries, class_name: "ArticleCalmSummary", dependent: :destroy

  has_many :article_entities, dependent: :destroy
  has_many :entities, through: :article_entities

  validates :source_name, :title, :url, :published_at, presence: true
  validates :url, uniqueness: true

  scope :with_entities, -> { joins(:entity_extractions).distinct }
  scope :without_entities, -> { left_joins(:entity_extractions).where(article_entity_extractions: { id: nil }) }
  scope :with_summary, -> { joins(:calm_summaries).distinct }
  scope :without_summary, -> { left_joins(:calm_summaries).where(article_calm_summaries: { id: nil }) }

  scope :recent, -> { order(published_at: :desc) }
  scope :from_source, ->(name) { where(source_name: name) }
  scope :published_after, ->(time) { where("published_at > ?", time) }
  scope :published_before, ->(time) { where("published_at < ?", time) }
  scope :in_category, ->(cat) { joins(:entities).where(entities: { entity_type: "category", name: cat.downcase }) }

  def calm_summary
    calm_summaries.order(created_at: :desc).first
  end

  def category
    entities.find_by(entity_type: "category")
  end

  def tags
    entities.where(entity_type: "tag")
  end

  def people
    entities.where(entity_type: "person")
  end

  def organizations
    entities.where(entity_type: "organization")
  end

  def places
    entities.where(entity_type: "place")
  end

  def latest_extraction
    entity_extractions.order(created_at: :desc).first
  end

  def self.from_news_api(article_hash)
    new(
      source_id: article_hash.dig("source", "id"),
      source_name: article_hash.dig("source", "name"),
      author: article_hash["author"],
      title: article_hash["title"],
      description: article_hash["description"],
      url: article_hash["url"],
      image_url: article_hash["urlToImage"],
      published_at: article_hash["publishedAt"],
      content: article_hash["content"],
      raw_payload: article_hash
    )
  end

  def self.upsert_from_news_api(article_hash)
    article = from_news_api(article_hash)
    existing = find_by(url: article.url)

    if existing
      existing.update(raw_payload: article_hash)
      existing
    else
      article.save!
      article
    end
  end
end
