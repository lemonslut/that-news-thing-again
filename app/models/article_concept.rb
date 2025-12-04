class ArticleConcept < ApplicationRecord
  belongs_to :article
  belongs_to :concept

  validates :article_id, uniqueness: { scope: :concept_id }

  scope :high_relevance, -> { where("score >= 4") }
  scope :by_relevance, -> { order(score: :desc) }
end
