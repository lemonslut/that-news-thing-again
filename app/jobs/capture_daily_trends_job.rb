class CaptureDailyTrendsJob < ApplicationJob
  queue_as :default

  def perform(date: nil)
    date ||= Date.yesterday
    period_start = date.beginning_of_day

    CaptureTrendsJob.perform_now(period_start: period_start, period_type: :day)

    Rails.logger.info "[CaptureDailyTrendsJob] Captured daily trends for #{date}"
  end
end
