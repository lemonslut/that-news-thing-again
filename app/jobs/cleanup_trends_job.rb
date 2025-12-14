class CleanupTrendsJob < ApplicationJob
  queue_as :default

  RETENTION_DAYS = 90

  def perform
    cutoff = RETENTION_DAYS.days.ago

    deleted = TrendSnapshot.where("period_start < ?", cutoff).delete_all

    Rails.logger.info "[CleanupTrendsJob] Deleted #{deleted} trend snapshots older than #{RETENTION_DAYS} days"
  end
end
