class StoryClusterer
  def call
    cluster_by_event_uri
  end

  def cluster_by_event_uri
    Article.where.not(event_uri: nil)
           .where(story_id: nil)
           .group(:event_uri)
           .count
           .each do |event_uri, _count|
      articles = Article.where(event_uri: event_uri, story_id: nil)
      next if articles.empty?

      story = find_or_create_story_for_event(event_uri, articles)
      articles.each { |a| a.update!(story: story) }
      story.update_timestamps!
    end
  end

  private

  def find_or_create_story_for_event(event_uri, articles)
    existing = Story.find_by(event_uri: event_uri)
    return existing if existing

    title = articles.first.title
    Story.create!(
      title: title,
      event_uri: event_uri
    )
  end
end
