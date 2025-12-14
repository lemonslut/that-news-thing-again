class CaptureTrendsJob < ApplicationJob
  queue_as :default

  TOP_STORIES = 30

  def perform(period_start: nil, period_type: :hour)
    period_start ||= beginning_of_current_period(period_type)
    period_end = end_of_period(period_start, period_type)
    previous_period = previous_period_start(period_start, period_type)

    previous_rankings = load_previous_rankings(previous_period, period_type)

    capture_stories(period_start, period_end, period_type, previous_rankings)

    Rails.logger.info "[CaptureTrendsJob] Captured #{period_type} trends for #{period_start}"
  end

  private

  def beginning_of_current_period(period_type)
    case period_type.to_sym
    when :hour
      Time.current.beginning_of_hour
    when :day
      Time.current.beginning_of_day
    end
  end

  def end_of_period(period_start, period_type)
    case period_type.to_sym
    when :hour
      period_start + 1.hour
    when :day
      period_start + 1.day
    end
  end

  def previous_period_start(period_start, period_type)
    case period_type.to_sym
    when :hour
      period_start - 1.hour
    when :day
      period_start - 1.day
    end
  end

  def load_previous_rankings(previous_period, period_type)
    TrendSnapshot.for_period(previous_period, period_type)
                 .pluck(:trendable_type, :trendable_id, :rank, :article_count)
                 .each_with_object({}) do |(type, id, rank, count), hash|
      hash["#{type}-#{id}"] = { rank: rank, article_count: count }
    end
  end

  def articles_in_period(period_start, period_end)
    Article.where(published_at: period_start...period_end)
  end

  def capture_stories(period_start, period_end, period_type, previous_rankings)
    article_ids = articles_in_period(period_start, period_end).select(:id)

    counts = Article.where(id: article_ids)
                    .where.not(story_id: nil)
                    .group(:story_id)
                    .order(Arel.sql("COUNT(*) DESC"))
                    .limit(TOP_STORIES)
                    .count

    create_snapshots("Story", counts, period_start, period_type, previous_rankings)
  end

  def create_snapshots(trendable_type, counts, period_start, period_type, previous_rankings)
    counts.each_with_index do |(id, count), index|
      rank = index + 1
      key = "#{trendable_type}-#{id}"
      prev = previous_rankings[key]

      previous_rank = prev&.fetch(:rank, nil)
      previous_count = prev&.fetch(:article_count, 0) || 0
      velocity = previous_count > 0 ? ((count - previous_count).to_f / previous_count * 100).round(1) : 0.0

      TrendSnapshot.upsert(
        {
          trendable_type: trendable_type,
          trendable_id: id,
          period_start: period_start,
          period_type: TrendSnapshot.period_types[period_type],
          article_count: count,
          rank: rank,
          previous_rank: previous_rank,
          velocity: velocity,
          created_at: Time.current,
          updated_at: Time.current
        },
        unique_by: :idx_trend_snapshots_unique
      )
    end
  end
end
