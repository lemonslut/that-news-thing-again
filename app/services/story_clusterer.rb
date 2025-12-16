# Clusters a single article into a story based on subject overlap.
#
# Algorithm:
# 1. Find active stories (last 7 days) with 50%+ subject overlap → assign to best match
# 2. If no story match, find unclustered articles (last 24h, then 7d) with 50%+ overlap → create new story
# 3. If no match → leave unclustered (may seed a story later)
#
# Subjects are extracted from the article's factual summary via NER.
# This gives more focused matching than using all mentioned concepts.
#
# Usage:
#   StoryClusterer.new(article).call
#
class StoryClusterer
  OVERLAP_THRESHOLD = 0.5
  STORY_WINDOW = 7.days
  ARTICLE_SEARCH_WINDOWS = [1.day, 7.days].freeze

  def initialize(article)
    @article = article
  end

  def call
    return false if @article.story_id.present?
    return false if @article.subjects.empty?

    # Try to match to existing active story
    story = find_matching_story
    if story
      assign_to_story(story)
      return true
    end

    # Try to match to another unclustered article
    match = find_matching_article
    if match
      create_story_from_articles(match)
      return true
    end

    false
  end

  private

  def find_matching_story
    article_subject_ids = subject_ids(@article)
    return nil if article_subject_ids.empty?

    active_stories.find do |story|
      story_subject_ids = story.articles
                               .joins(:article_subjects)
                               .pluck("article_subjects.concept_id")
                               .to_set
      overlap_ratio(article_subject_ids, story_subject_ids) >= OVERLAP_THRESHOLD
    end
  end

  def find_matching_article
    article_subject_ids = subject_ids(@article)
    return nil if article_subject_ids.empty?

    ARTICLE_SEARCH_WINDOWS.each do |window|
      candidates = unclustered_articles_in_window(window)
      match = candidates.find do |candidate|
        candidate_subject_ids = subject_ids(candidate)
        overlap_ratio(article_subject_ids, candidate_subject_ids) >= OVERLAP_THRESHOLD
      end
      return match if match
    end

    nil
  end

  def subject_ids(article)
    article.subjects.pluck(:id).to_set
  end

  def active_stories
    Story.where("last_published_at > ?", STORY_WINDOW.ago)
         .includes(:articles)
  end

  def unclustered_articles_in_window(window)
    Article.where(story_id: nil)
           .where.not(id: @article.id)
           .joins(:article_subjects)
           .where("articles.published_at > ?", window.ago)
           .where("articles.published_at <= ?", @article.published_at)
           .distinct
           .includes(:article_subjects)
  end

  def overlap_ratio(set_a, set_b)
    return 0.0 if set_a.empty? || set_b.empty?

    intersection = (set_a & set_b).size
    min_size = [set_a.size, set_b.size].min
    intersection.to_f / min_size
  end

  def assign_to_story(story)
    @article.update!(story: story)
    story.update_timestamps!
    Rails.logger.info "[StoryClusterer] Added article #{@article.id} to story #{story.id} '#{story.title}'"
  end

  def create_story_from_articles(match)
    # Use earliest article's title as story title
    first_article = [@article, match].min_by(&:published_at)

    story = Story.create!(title: first_article.title)
    @article.update!(story: story)
    match.update!(story: story)
    story.update_timestamps!
    Rails.logger.info "[StoryClusterer] Created story '#{story.title}' with articles #{@article.id}, #{match.id}"
    story
  end
end
