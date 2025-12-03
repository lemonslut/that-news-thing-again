class Entity < ApplicationRecord
  TYPES = %w[person organization place publisher author tag category].freeze

  has_many :article_entities, dependent: :destroy
  has_many :articles, through: :article_entities

  has_many :article_entity_extraction_entities, dependent: :destroy
  has_many :extractions, through: :article_entity_extraction_entities, source: :article_entity_extraction

  validates :entity_type, presence: true, inclusion: { in: TYPES }
  validates :name, presence: true, uniqueness: { scope: :entity_type }

  scope :of_type, ->(type) { where(entity_type: type) }
  scope :people, -> { of_type("person") }
  scope :organizations, -> { of_type("organization") }
  scope :places, -> { of_type("place") }
  scope :publishers, -> { of_type("publisher") }
  scope :authors, -> { of_type("author") }
  scope :tags, -> { of_type("tag") }
  scope :categories, -> { of_type("category") }

  def self.find_or_create(type, name)
    normalized = normalize_name(name)
    return nil if normalized.blank?

    find_or_create_by!(entity_type: type, name: normalized)
  end

  def self.normalize_name(name)
    name.to_s.strip.downcase.presence
  end

  def to_s
    name
  end
end
