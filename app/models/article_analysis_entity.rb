class ArticleAnalysisEntity < ApplicationRecord
  belongs_to :article_analysis
  belongs_to :entity

  validates :entity_id, uniqueness: { scope: :article_analysis_id }
end
