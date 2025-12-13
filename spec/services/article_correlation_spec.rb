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

  def create_concept(attrs = {})
    defaults = {
      uri: "http://wiki/#{SecureRandom.hex(4)}",
      concept_type: "wiki",
      label: "Test Concept"
    }
    Concept.create!(defaults.merge(attrs))
  end

  describe "#score" do
    context "when articles share the same event_uri" do
      it "returns 1.0" do
        article_a = create_article(event_uri: "event-123")
        article_b = create_article(event_uri: "event-123")

        expect(described_class.new(article_a, article_b).score).to eq(1.0)
      end
    end

    context "when articles have no overlap" do
      it "returns a low score" do
        article_a = create_article(event_uri: nil)
        article_b = create_article(event_uri: nil)

        expect(described_class.new(article_a, article_b).score).to be < 0.2
      end
    end

    context "when articles share concepts" do
      it "returns a higher score" do
        article_a = create_article(event_uri: nil)
        article_b = create_article(event_uri: nil)
        concept = create_concept

        article_a.concepts << concept
        article_b.concepts << concept

        score = described_class.new(article_a, article_b).score
        expect(score).to be > 0.3
      end
    end
  end

  describe "#concept_score" do
    it "returns 0 when neither article has concepts" do
      article_a = create_article
      article_b = create_article

      expect(described_class.new(article_a, article_b).concept_score).to eq(0.0)
    end

    context "with shared concepts" do
      it "calculates Jaccard similarity" do
        article_a = create_article
        article_b = create_article
        shared_concept = create_concept(uri: "shared")
        unique_concept = create_concept(uri: "unique")

        article_a.concepts << [shared_concept, unique_concept]
        article_b.concepts << shared_concept

        # 1 shared / 2 union = 0.5
        expect(described_class.new(article_a, article_b).concept_score).to eq(0.5)
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
  end
end
