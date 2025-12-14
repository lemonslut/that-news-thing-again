class TrendsController < ApplicationController
  allow_unauthenticated_access only: %i[index] if Rails.env.development?

  def index
    @period_type = params[:period].presence_in(%w[hour day]) || "hour"
    @period_start = parse_period_start || default_period_start

    @stories = TrendSnapshot.stories_for_period(@period_start, @period_type).top(15)

    @available_periods = available_periods
  end

  private

  def parse_period_start
    return nil unless params[:at].present?

    Time.zone.parse(params[:at])
  rescue ArgumentError
    nil
  end

  def default_period_start
    case @period_type
    when "hour"
      Time.current.beginning_of_hour
    when "day"
      Date.current.beginning_of_day
    end
  end

  def available_periods
    TrendSnapshot.where(period_type: @period_type)
                 .distinct
                 .order(period_start: :desc)
                 .limit(24)
                 .pluck(:period_start)
  end
end
