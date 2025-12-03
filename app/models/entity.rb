class Entity < ApplicationRecord
  TYPES = %w[person organization place publisher author tag category].freeze

  has_many :article_analysis_entities, dependent: :destroy
  has_many :article_analyses, through: :article_analysis_entities

  validates :entity_type, presence: true, inclusion: { in: TYPES }
  validates :name, presence: true, uniqueness: { scope: :entity_type }

  scope :of_type, ->(type) { where(entity_type: type) }
  scope :people, -> { of_type("person") }
  scope :organizations, -> { of_type("organization") }
  scope :places, -> { of_type("place") }
  scope :tags, -> { of_type("tag") }
  scope :categories, -> { of_type("category") }

  def self.find_or_create(type, name)
    find_or_create_by!(entity_type: type, name: name.to_s.strip)
  end

  def to_s
    name
  end
end
