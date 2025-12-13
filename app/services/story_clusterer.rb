class StoryClusterer
  CORRELATION_THRESHOLD = 0.35

  def call
    cluster_by_event_uri
    cluster_by_concepts
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

  def cluster_by_concepts
    Article.where(story_id: nil, event_uri: nil)
           .includes(:concepts)
           .find_each do |article|
      next if article.concepts.empty?

      best_story = find_best_matching_story(article)
      if best_story
        article.update!(story_id: best_story.id)
        best_story.update_timestamps!
      else
        create_story_for_article(article)
      end
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

  def find_best_matching_story(article)
    best_score = 0.0
    best_story = nil

    Story.includes(articles: :concepts).find_each do |story|
      representative = story.articles.first
      next unless representative

      score = ArticleCorrelation.new(article, representative).score
      if score > best_score && score >= CORRELATION_THRESHOLD
        best_score = score
        best_story = story
      end
    end

    best_story
  end

  def create_story_for_article(article)
    story = Story.create!(title: article.title)
    article.update!(story_id: story.id)
    story.update_timestamps!
    story
  end
end
