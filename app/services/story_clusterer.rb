# Story clustering is currently disabled.
# The old event_uri-based clustering from NewsAPI.ai produced poor results.
# TODO: Implement concept-based clustering using LLM-extracted entities.
class StoryClusterer
  def call
    # No-op for now
    Rails.logger.info "[StoryClusterer] Clustering disabled - no implementation"
  end
end
