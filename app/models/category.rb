class Category < ApplicationRecord
  has_many :article_categories, dependent: :destroy
  has_many :articles, through: :article_categories

  validates :uri, presence: true, uniqueness: true
  validates :label, presence: true

  scope :news, -> { where("uri LIKE 'news/%'") }
  scope :dmoz, -> { where("uri LIKE 'dmoz/%'") }

  def self.find_or_create_from_api(category_hash)
    uri = category_hash["uri"]
    return nil if uri.blank?

    find_or_create_by!(uri: uri) do |cat|
      cat.label = category_hash["label"] || uri
    end
  end

  # Returns the leaf name (e.g., "news/Business" -> "Business")
  def short_name
    label.split("/").last
  end

  def to_s
    short_name
  end
end
