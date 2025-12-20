# DEPRECATED: No longer generated. Factual summaries (Article#factual_summary) replaced this.
# Retained for historical data only.
class ArticleCalmSummary < ApplicationRecord
  belongs_to :article
  belongs_to :prompt, optional: true

  validates :model_used, presence: true
  validates :summary, presence: true

  scope :recent, -> { joins(:article).order("articles.published_at DESC") }
end
