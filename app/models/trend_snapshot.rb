class TrendSnapshot < ApplicationRecord
  belongs_to :trendable, polymorphic: true

  enum :period_type, { hour: 0, day: 1 }

  validates :period_start, presence: true
  validates :article_count, numericality: { greater_than_or_equal_to: 0 }

  scope :for_period, ->(start_time, type = :hour) {
    where(period_start: start_time, period_type: type)
  }
  scope :for_type, ->(type) { where(trendable_type: type) }
  scope :ranked, -> { where.not(rank: nil).order(:rank) }
  scope :top, ->(n = 10) { ranked.limit(n) }
  scope :recent, -> { order(period_start: :desc) }

  def rising?
    previous_rank.present? && rank.present? && rank < previous_rank
  end

  def falling?
    previous_rank.present? && rank.present? && rank > previous_rank
  end

  def new_entry?
    previous_rank.nil? && rank.present?
  end

  def rank_change
    return nil unless previous_rank.present? && rank.present?
    previous_rank - rank
  end

  def self.stories_for_period(period_start, period_type = :hour)
    for_period(period_start, period_type).for_type("Story").ranked.includes(:trendable)
  end
end
