class Concept < ApplicationRecord
  TYPES = %w[person org loc wiki].freeze

  has_many :article_concepts, dependent: :destroy
  has_many :articles, through: :article_concepts

  validates :uri, presence: true, uniqueness: true
  validates :concept_type, presence: true, inclusion: { in: TYPES }
  validates :label, presence: true

  scope :people, -> { where(concept_type: "person") }
  scope :organizations, -> { where(concept_type: "org") }
  scope :locations, -> { where(concept_type: "loc") }
  scope :topics, -> { where(concept_type: "wiki") }
  scope :of_type, ->(type) { where(concept_type: type) }

  def self.find_or_create_from_api(concept_hash)
    uri = concept_hash["uri"]
    return nil if uri.blank?

    find_or_create_by!(uri: uri) do |concept|
      concept.concept_type = concept_hash["type"]
      concept.label = concept_hash.dig("label", "eng") || uri.split("/").last
    end
  end

  def person?
    concept_type == "person"
  end

  def organization?
    concept_type == "org"
  end

  def location?
    concept_type == "loc"
  end

  def topic?
    concept_type == "wiki"
  end

  def to_s
    label
  end
end
