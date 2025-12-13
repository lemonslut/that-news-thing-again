class ArticleCorrelation
  CONCEPT_WEIGHT = 0.7
  CATEGORY_WEIGHT = 0.2
  TIME_WEIGHT = 0.1
  TIME_DECAY_DAYS = 7

  attr_reader :article_a, :article_b

  def initialize(article_a, article_b)
    @article_a = article_a
    @article_b = article_b
  end

  def score
    return 1.0 if same_event?

    concept_score * CONCEPT_WEIGHT +
      category_score * CATEGORY_WEIGHT +
      time_proximity_score * TIME_WEIGHT
  end

  def same_event?
    article_a.event_uri.present? &&
      article_a.event_uri == article_b.event_uri
  end

  def concept_score
    jaccard_similarity(concept_uris_a, concept_uris_b)
  end

  def category_score
    jaccard_similarity(category_uris_a, category_uris_b)
  end

  def time_proximity_score
    return 0.0 unless article_a.published_at && article_b.published_at

    days_apart = (article_a.published_at - article_b.published_at).abs / 1.day
    [1.0 - (days_apart / TIME_DECAY_DAYS), 0.0].max
  end

  def self.find_related(article, threshold: 0.3, limit: 10)
    candidates = candidate_articles(article)
    scored = candidates.map do |candidate|
      [candidate, new(article, candidate).score]
    end

    scored.select { |_, s| s >= threshold }
          .sort_by { |_, s| -s }
          .first(limit)
          .map(&:first)
  end

  def self.candidate_articles(article)
    scope = Article.where.not(id: article.id)

    conditions = []
    conditions << Article.where(event_uri: article.event_uri) if article.event_uri.present?

    concept_ids = article.concept_ids
    if concept_ids.any?
      conditions << Article.joins(:article_concepts)
                           .where(article_concepts: { concept_id: concept_ids })
    end

    return Article.none if conditions.empty?

    combined = conditions.reduce { |memo, cond| memo.or(cond) }
    scope.merge(combined).distinct.limit(100)
  end

  private

  def concept_uris_a
    @concept_uris_a ||= article_a.concepts.pluck(:uri)
  end

  def concept_uris_b
    @concept_uris_b ||= article_b.concepts.pluck(:uri)
  end

  def category_uris_a
    @category_uris_a ||= article_a.categories.pluck(:uri)
  end

  def category_uris_b
    @category_uris_b ||= article_b.categories.pluck(:uri)
  end

  def jaccard_similarity(set_a, set_b)
    return 0.0 if set_a.empty? && set_b.empty?

    intersection = (set_a & set_b).size
    union = (set_a | set_b).size

    intersection.to_f / union
  end
end
