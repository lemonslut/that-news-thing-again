class ClusterArticleJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find_by(id: article_id)
    return unless article

    StoryClusterer.new(article).call
  end
end
