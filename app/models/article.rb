class Article < ApplicationRecord
  has_one :analysis, class_name: "ArticleAnalysis", dependent: :destroy

  validates :source_name, :title, :url, :published_at, presence: true
  validates :url, uniqueness: true

  scope :analyzed, -> { joins(:analysis) }
  scope :unanalyzed, -> { left_joins(:analysis).where(article_analyses: { id: nil }) }

  scope :recent, -> { order(published_at: :desc) }
  scope :from_source, ->(name) { where(source_name: name) }
  scope :published_after, ->(time) { where("published_at > ?", time) }
  scope :published_before, ->(time) { where("published_at < ?", time) }

  def self.from_news_api(article_hash)
    new(
      source_id: article_hash.dig("source", "id"),
      source_name: article_hash.dig("source", "name"),
      author: article_hash["author"],
      title: article_hash["title"],
      description: article_hash["description"],
      url: article_hash["url"],
      image_url: article_hash["urlToImage"],
      published_at: article_hash["publishedAt"],
      content: article_hash["content"],
      raw_payload: article_hash
    )
  end

  def self.upsert_from_news_api(article_hash)
    article = from_news_api(article_hash)
    existing = find_by(url: article.url)

    if existing
      existing.update(raw_payload: article_hash)
      existing
    else
      article.save!
      article
    end
  end
end
