class ArticleSubject < ApplicationRecord
  belongs_to :article
  belongs_to :concept
end
