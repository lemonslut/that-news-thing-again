class ArticleAnalysis < ApplicationRecord
  belongs_to :article

  CATEGORIES = %w[
    politics business technology health science
    entertainment sports world environment other
  ].freeze

  POLITICAL_LEANS = %w[left center-left center center-right right].freeze

  validates :article, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :calm_summary, presence: true
  validates :model_used, presence: true
  validates :political_lean, inclusion: { in: POLITICAL_LEANS }, allow_nil: true

  scope :by_category, ->(cat) { where(category: cat) }
  scope :with_tag, ->(tag) { where("tags @> ?", [tag].to_json) }
  scope :leaning, ->(lean) { where(political_lean: lean) }
  scope :recent, -> { joins(:article).order("articles.published_at DESC") }

  def self.tag_counts(since: nil)
    scope = since ? joins(:article).where("articles.published_at > ?", since) : all
    scope.pluck(:tags).flatten.tally.sort_by { |_, v| -v }
  end

  def self.category_counts(since: nil)
    scope = since ? joins(:article).where("articles.published_at > ?", since) : all
    scope.group(:category).count.sort_by { |_, v| -v }
  end
end
