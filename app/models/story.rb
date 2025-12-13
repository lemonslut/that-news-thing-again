class Story < ApplicationRecord
  has_many :articles, dependent: :nullify

  validates :title, presence: true

  scope :recent, -> { order(last_published_at: :desc) }
  scope :active, -> { where("last_published_at > ?", 7.days.ago) }
  scope :multi_source, -> { where("articles_count > 1") }

  def update_timestamps!
    times = articles.pluck(:published_at).compact
    return if times.empty?

    update!(
      first_published_at: times.min,
      last_published_at: times.max
    )
  end

  def duration
    return nil unless first_published_at && last_published_at
    last_published_at - first_published_at
  end

  def sources
    articles.distinct.pluck(:source_name)
  end

  def primary_concepts
    Concept.joins(:article_concepts)
           .where(article_concepts: { article_id: articles.select(:id) })
           .group(:id)
           .order("COUNT(*) DESC")
           .limit(5)
  end
end
