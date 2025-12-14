class ArticleAnalysis < ApplicationRecord
  TYPES = %w[calm_summary ner_extraction general_sentiment entity_sentiment].freeze

  belongs_to :article
  belongs_to :prompt, optional: true

  validates :analysis_type, presence: true, inclusion: { in: TYPES }
  validates :model_used, presence: true
  validates :result, presence: true

  scope :of_type, ->(type) { where(analysis_type: type) }
  scope :calm_summaries, -> { of_type("calm_summary") }
  scope :ner_extractions, -> { of_type("ner_extraction") }
  scope :general_sentiments, -> { of_type("general_sentiment") }
  scope :entity_sentiments, -> { of_type("entity_sentiment") }
  scope :latest, -> { order(created_at: :desc) }

  def calm_summary
    result["calm_summary"] if analysis_type == "calm_summary"
  end

  def sentiment_score
    result["sentiment"] if analysis_type.include?("sentiment")
  end

  def sentiment_label
    result["label"] if analysis_type.include?("sentiment")
  end

  def entities
    result["entities"] if analysis_type == "ner_extraction"
  end

  def entity_sentiments
    result["entity_sentiments"] if analysis_type == "entity_sentiment"
  end
end
