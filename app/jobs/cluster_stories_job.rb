class ClusterStoriesJob < ApplicationJob
  queue_as :default

  def perform
    clusterer = StoryClusterer.new
    clusterer.call

    Rails.logger.info "[ClusterStoriesJob] Clustered articles. " \
      "Stories: #{Story.count}, Multi-article stories: #{Story.multi_source.count}"
  end
end
