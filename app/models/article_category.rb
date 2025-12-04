class ArticleCategory < ApplicationRecord
  belongs_to :article
  belongs_to :category

  validates :article_id, uniqueness: { scope: :category_id }

  scope :primary, -> { where("weight >= 70") }
  scope :by_weight, -> { order(weight: :desc) }
end
