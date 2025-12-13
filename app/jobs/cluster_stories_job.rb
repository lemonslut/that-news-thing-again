class ClusterStoriesJob < ApplicationJob
  queue_as :default

  LOCK_KEY = "cluster_stories_job_running"
  LOCK_TTL = 4.hours

  def perform
    unless acquire_lock
      Rails.logger.info "[ClusterStoriesJob] Skipping - another instance is already running"
      return
    end

    begin
      clusterer = StoryClusterer.new
      clusterer.call

      Rails.logger.info "[ClusterStoriesJob] Clustered articles. " \
        "Stories: #{Story.count}, Multi-article stories: #{Story.multi_source.count}"
    ensure
      release_lock
    end
  end

  private

  def acquire_lock
    redis.set(LOCK_KEY, Time.current.to_s, nx: true, ex: LOCK_TTL.to_i)
  end

  def release_lock
    redis.del(LOCK_KEY)
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  end
end
