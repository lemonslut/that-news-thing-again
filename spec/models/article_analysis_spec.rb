require "rails_helper"

RSpec.describe ArticleAnalysis do
  let(:article) do
    Article.create!(
      source_name: "BBC News",
      title: "Test headline",
      url: "https://bbc.com/test",
      published_at: Time.current
    )
  end

  let(:valid_attributes) do
    {
      article: article,
      category: "politics",
      tags: ["election", "senate"],
      entities: { "people" => ["John Doe"], "organizations" => [], "places" => ["DC"] },
      political_lean: "center",
      calm_summary: "A calm summary of events.",
      model_used: "anthropic/claude-3-haiku",
      raw_response: {}
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      analysis = described_class.new(valid_attributes)
      expect(analysis).to be_valid
    end

    it "requires category" do
      analysis = described_class.new(valid_attributes.merge(category: nil))
      expect(analysis).not_to be_valid
    end

    it "requires valid category" do
      analysis = described_class.new(valid_attributes.merge(category: "invalid"))
      expect(analysis).not_to be_valid
    end

    it "requires calm_summary" do
      analysis = described_class.new(valid_attributes.merge(calm_summary: nil))
      expect(analysis).not_to be_valid
    end

    it "requires model_used" do
      analysis = described_class.new(valid_attributes.merge(model_used: nil))
      expect(analysis).not_to be_valid
    end

    it "allows nil political_lean" do
      analysis = described_class.new(valid_attributes.merge(political_lean: nil))
      expect(analysis).to be_valid
    end

    it "requires valid political_lean if present" do
      analysis = described_class.new(valid_attributes.merge(political_lean: "far-left"))
      expect(analysis).not_to be_valid
    end

    it "enforces one analysis per article" do
      described_class.create!(valid_attributes)

      duplicate = described_class.new(valid_attributes)
      expect(duplicate).not_to be_valid
    end
  end

  describe "scopes" do
    before do
      @politics = described_class.create!(valid_attributes)
      @tech = described_class.create!(
        valid_attributes.merge(
          article: Article.create!(source_name: "TechCrunch", title: "Tech news", url: "https://tc.com/1", published_at: 1.day.ago),
          category: "technology",
          tags: ["ai", "startups"],
          political_lean: nil
        )
      )
    end

    it ".by_category filters by category" do
      expect(described_class.by_category("politics")).to include(@politics)
      expect(described_class.by_category("politics")).not_to include(@tech)
    end

    it ".with_tag finds by tag" do
      expect(described_class.with_tag("election")).to include(@politics)
      expect(described_class.with_tag("ai")).to include(@tech)
      expect(described_class.with_tag("election")).not_to include(@tech)
    end

    it ".leaning filters by political lean" do
      expect(described_class.leaning("center")).to include(@politics)
      expect(described_class.leaning("center")).not_to include(@tech)
    end
  end

  describe ".tag_counts" do
    before do
      described_class.create!(valid_attributes.merge(tags: ["election", "senate"]))
      described_class.create!(
        valid_attributes.merge(
          article: Article.create!(source_name: "CNN", title: "More news", url: "https://cnn.com/1", published_at: Time.current),
          tags: ["election", "house"]
        )
      )
    end

    it "returns tag frequency counts" do
      counts = described_class.tag_counts

      expect(counts.to_h["election"]).to eq(2)
      expect(counts.to_h["senate"]).to eq(1)
    end
  end

  describe ".category_counts" do
    before do
      described_class.create!(valid_attributes)
      described_class.create!(
        valid_attributes.merge(
          article: Article.create!(source_name: "CNN", title: "More politics", url: "https://cnn.com/2", published_at: Time.current),
          category: "politics"
        )
      )
      described_class.create!(
        valid_attributes.merge(
          article: Article.create!(source_name: "TC", title: "Tech", url: "https://tc.com/2", published_at: Time.current),
          category: "technology"
        )
      )
    end

    it "returns category frequency counts" do
      counts = described_class.category_counts.to_h

      expect(counts["politics"]).to eq(2)
      expect(counts["technology"]).to eq(1)
    end
  end
end
