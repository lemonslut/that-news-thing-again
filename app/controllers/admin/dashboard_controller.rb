module Admin
  class DashboardController < BaseController
    def index
      render inertia: "Dashboard/Index", props: {
        stats: {
          articles_count: Article.count,
          stories_count: Story.count,
          concepts_count: Concept.count,
          categories_count: Category.count,
          articles_today: Article.where("created_at >= ?", Time.current.beginning_of_day).count,
          trending_stories: TrendSnapshot.for_type("Story").for_period(Time.current.beginning_of_hour, "hour").count
        },
        recent_articles: Article.recent.limit(10).map do |article|
          {
            id: article.id,
            title: article.title,
            source_name: article.source_name,
            published_at: article.published_at.iso8601
          }
        end
      }
    end
  end
end
