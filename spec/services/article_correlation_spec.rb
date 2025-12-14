require "rails_helper"

RSpec.describe ArticleCorrelation do
  def create_article(attrs = {})
    defaults = {
      title: "Test Article #{SecureRandom.hex(4)}",
      url: "https://example.com/#{SecureRandom.hex(8)}",
      source_name: "Test Source",
      published_at: Time.current
    }
    Article.create!(defaults.merge(attrs))
  end

  describe "#score" do
    context "when articles share the same event_uri" do
      it "returns 1.0" do
        article_a = create_article(event_uri: "event-123")
        article_b = create_article(event_uri: "event-123")

        expect(described_class.new(article_a, article_b).score).to eq(1.0)
      end
    end

    context "when articles have no shared event_uri" do
      it "returns time proximity score" do
        time = Time.current
        article_a = create_article(event_uri: nil, published_at: time)
        article_b = create_article(event_uri: nil, published_at: time)

        expect(described_class.new(article_a, article_b).score).to eq(1.0)
      end
    end
  end

  describe "#time_proximity_score" do
    it "returns 1.0 for articles published at the same time" do
      time = Time.current
      article_a = create_article(published_at: time)
      article_b = create_article(published_at: time)

      expect(described_class.new(article_a, article_b).time_proximity_score).to eq(1.0)
    end

    it "returns 0.0 for articles 7+ days apart" do
      article_a = create_article(published_at: 8.days.ago)
      article_b = create_article(published_at: Time.current)

      expect(described_class.new(article_a, article_b).time_proximity_score).to eq(0.0)
    end

    it "returns intermediate values for articles within 7 days" do
      article_a = create_article(published_at: 3.days.ago)
      article_b = create_article(published_at: Time.current)

      score = described_class.new(article_a, article_b).time_proximity_score
      expect(score).to be_between(0.5, 0.6)
    end
  end

  describe ".find_related" do
    it "finds related articles above threshold" do
      related = create_article(event_uri: "event-123")
      target = create_article(event_uri: "event-123")

      results = described_class.find_related(target)
      expect(results).to include(related)
    end

    it "excludes the source article" do
      target = create_article(event_uri: "event-123")
      other = create_article(event_uri: "event-123")

      results = described_class.find_related(target)
      expect(results).to include(other)
      expect(results).not_to include(target)
    end

    it "returns empty when article has no event_uri" do
      target = create_article(event_uri: nil)
      _unrelated = create_article(event_uri: nil)

      results = described_class.find_related(target)
      expect(results).to be_empty
    end
  end
end
