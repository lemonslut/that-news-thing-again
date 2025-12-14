class ArticleCorrelation
  TIME_DECAY_DAYS = 7

  attr_reader :article_a, :article_b

  def initialize(article_a, article_b)
    @article_a = article_a
    @article_b = article_b
  end

  def score
    return 1.0 if same_event?

    time_proximity_score
  end

  def same_event?
    article_a.event_uri.present? &&
      article_a.event_uri == article_b.event_uri
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
    return Article.none unless article.event_uri.present?

    Article.where.not(id: article.id)
           .where(event_uri: article.event_uri)
           .limit(100)
  end
end
