class ArticleEntityExtraction < ApplicationRecord
  belongs_to :article
  belongs_to :prompt, optional: true

  has_many :article_entity_extraction_entities, dependent: :destroy
  has_many :entities, through: :article_entity_extraction_entities

  validates :model_used, presence: true

  def link_entities_from_result(result)
    Array(result.dig("entities", "people")).each do |name|
      link_entity("person", name)
    end

    Array(result.dig("entities", "organizations")).each do |name|
      link_entity("organization", name)
    end

    Array(result.dig("entities", "places")).each do |name|
      link_entity("place", name)
    end

    Array(result["tags"]).each do |name|
      link_entity("tag", name)
    end

    link_entity("category", result["category"]) if result["category"].present?

    link_entity("publisher", article.source_name) if article.source_name.present?
    article.author.to_s.split(/,\s*/).each do |author_name|
      link_entity("author", author_name.strip)
    end
  end

  private

  def link_entity(type, name)
    entity = Entity.find_or_create(type, name)
    return unless entity

    # Link to extraction (provenance)
    entities << entity unless entities.include?(entity)

    # Link to article (canonical relationship)
    article.entities << entity unless article.entities.include?(entity)
  rescue ActiveRecord::RecordNotUnique
    # Already linked, ignore
  end
end
