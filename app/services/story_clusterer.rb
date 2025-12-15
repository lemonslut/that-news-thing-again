# Clusters articles into stories based on concept overlap.
#
# Algorithm:
# 1. For each unclustered article with concepts:
#    a. Find active stories (last 7 days) with 50%+ concept overlap → assign to best match
#    b. If no story match, find unclustered articles (last 24h, then 7d) with 50%+ overlap → create new story
#    c. If no match → leave unclustered (may seed a story later)
#
class StoryClusterer
  OVERLAP_THRESHOLD = 0.5
  STORY_WINDOW = 7.days
  ARTICLE_SEARCH_WINDOWS = [1.day, 7.days].freeze

  def call
    clustered = 0
    articles_to_cluster.find_each do |article|
      if cluster_article(article)
        clustered += 1
      end
    end
    Rails.logger.info "[StoryClusterer] Clustered #{clustered} articles"
    clustered
  end

  def cluster_article(article)
    return false if article.concepts.empty?

    # Try to match to existing active story
    story = find_matching_story(article)
    if story
      assign_to_story(article, story)
      return true
    end

    # Try to match to another unclustered article
    match = find_matching_article(article)
    if match
      story = create_story_from_articles(article, match)
      Rails.logger.info "[StoryClusterer] Created story '#{story.title}' with articles #{article.id}, #{match.id}"
      return true
    end

    false
  end

  private

  def articles_to_cluster
    Article.where(story_id: nil)
           .joins(:article_concepts)
           .where("articles.published_at > ?", STORY_WINDOW.ago)
           .distinct
           .order(published_at: :desc)
  end

  def find_matching_story(article)
    article_concept_ids = article.concept_ids.to_set
    return nil if article_concept_ids.empty?

    active_stories.find do |story|
      story_concept_ids = story_concept_ids_cached(story)
      overlap_ratio(article_concept_ids, story_concept_ids) >= OVERLAP_THRESHOLD
    end
  end

  def find_matching_article(article)
    article_concept_ids = article.concept_ids.to_set
    return nil if article_concept_ids.empty?

    ARTICLE_SEARCH_WINDOWS.each do |window|
      candidates = unclustered_articles_in_window(article, window)
      match = candidates.find do |candidate|
        candidate_concept_ids = candidate.concept_ids.to_set
        overlap_ratio(article_concept_ids, candidate_concept_ids) >= OVERLAP_THRESHOLD
      end
      return match if match
    end

    nil
  end

  def active_stories
    @active_stories ||= Story.active.includes(:articles).to_a
  end

  def story_concept_ids_cached(story)
    @story_concepts ||= {}
    @story_concepts[story.id] ||= story.articles.joins(:article_concepts)
                                        .pluck("article_concepts.concept_id")
                                        .to_set
  end

  def unclustered_articles_in_window(article, window)
    Article.where(story_id: nil)
           .where.not(id: article.id)
           .joins(:article_concepts)
           .where("articles.published_at > ?", window.ago)
           .where("articles.published_at <= ?", article.published_at)
           .distinct
           .includes(:article_concepts)
  end

  def overlap_ratio(set_a, set_b)
    return 0.0 if set_a.empty? || set_b.empty?

    intersection = (set_a & set_b).size
    min_size = [set_a.size, set_b.size].min
    intersection.to_f / min_size
  end

  def assign_to_story(article, story)
    article.update!(story: story)
    story.update_timestamps!
    Rails.logger.info "[StoryClusterer] Added article #{article.id} to story #{story.id} '#{story.title}'"
  end

  def create_story_from_articles(article, match)
    # Use earliest article's title as story title
    first_article = [article, match].min_by(&:published_at)

    story = Story.create!(title: first_article.title)
    article.update!(story: story)
    match.update!(story: story)
    story.update_timestamps!
    story
  end
end
