class ArticleEntityExtractionEntity < ApplicationRecord
  belongs_to :article_entity_extraction
  belongs_to :entity

  validates :article_entity_extraction_id, uniqueness: { scope: :entity_id }
end
