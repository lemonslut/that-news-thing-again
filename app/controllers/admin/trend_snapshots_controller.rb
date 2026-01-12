module Admin
  class TrendSnapshotsController < BaseController
    def index
      snapshots = TrendSnapshot.order(period_start: :desc, rank: :asc)
      snapshots = snapshots.for_type(params[:type]) if params[:type].present?
      snapshots = snapshots.where(period_type: params[:period]) if params[:period].present?

      render_index(
        component: "TrendSnapshots/Index",
        records: snapshots,
        serializer: method(:serialize_snapshot),
        types: %w[Story Concept Category],
        periods: %w[hour day]
      )
    end

    private

    def serialize_snapshot(snapshot)
      {
        id: snapshot.id,
        trendable_type: snapshot.trendable_type,
        trendable_id: snapshot.trendable_id,
        trendable_label: snapshot.trendable&.respond_to?(:title) ? snapshot.trendable.title : snapshot.trendable&.label,
        period_start: snapshot.period_start.iso8601,
        period_type: snapshot.period_type,
        article_count: snapshot.article_count,
        rank: snapshot.rank,
        previous_rank: snapshot.previous_rank,
        velocity: snapshot.velocity
      }
    end
  end
end
