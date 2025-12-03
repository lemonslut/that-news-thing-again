class ArticleAnalysis < ApplicationRecord
  belongs_to :article
  belongs_to :prompt, optional: true

  has_many :article_analysis_entities, dependent: :destroy
  has_many :linked_entities, through: :article_analysis_entities, source: :entity

  CATEGORIES = %w[
    politics business technology health science
    entertainment sports world environment other
  ].freeze

  POLITICAL_LEANS = %w[left center-left center center-right right].freeze

  validates :article, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :calm_summary, presence: true
  validates :model_used, presence: true
  validates :political_lean, inclusion: { in: POLITICAL_LEANS }, allow_nil: true

  scope :by_category, ->(cat) { where(category: cat) }
  scope :with_tag, ->(tag) { where("tags @> ?", [tag].to_json) }
  scope :leaning, ->(lean) { where(political_lean: lean) }
  scope :recent, -> { joins(:article).order("articles.published_at DESC") }

  def self.tag_counts(since: nil)
    scope = since ? joins(:article).where("articles.published_at > ?", since) : all
    scope.pluck(:tags).flatten.tally.sort_by { |_, v| -v }
  end

  def self.category_counts(since: nil)
    scope = since ? joins(:article).where("articles.published_at > ?", since) : all
    scope.group(:category).count.sort_by { |_, v| -v }
  end

  def link_entities_from_result(result, article)
    # People from LLM extraction
    Array(result.dig("entities", "people")).each do |name|
      link_entity("person", name) if name.present?
    end

    # Organizations from LLM extraction
    Array(result.dig("entities", "organizations")).each do |name|
      link_entity("organization", name) if name.present?
    end

    # Places from LLM extraction
    Array(result.dig("entities", "places")).each do |name|
      link_entity("place", name) if name.present?
    end

    # Tags from LLM extraction
    Array(result["tags"]).each do |name|
      link_entity("tag", name) if name.present?
    end

    # Category from LLM extraction
    link_entity("category", result["category"]) if result["category"].present?

    # Publisher and author from article metadata
    link_entity("publisher", article.source_name) if article.source_name.present?
    article.author.to_s.split(/,\s*/).each do |author|
      link_entity("author", author.strip) if author.strip.present?
    end
  end

  def entities_of_type(type)
    linked_entities.of_type(type)
  end

  private

  def link_entity(type, name)
    entity = Entity.find_or_create(type, name)
    linked_entities << entity unless linked_entities.include?(entity)
  rescue ActiveRecord::RecordNotUnique
    # Already linked, ignore
  end
end
