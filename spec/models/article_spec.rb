require "rails_helper"

RSpec.describe Article do
  let(:api_ai_hash) do
    {
      "uri" => "8985357961",
      "title" => "Test Article Title",
      "url" => "https://example.com/article",
      "body" => "Full article body content goes here.",
      "dateTimePub" => "2025-12-04T08:07:28Z",
      "dateTime" => "2025-12-04T08:08:08Z",
      "source" => { "uri" => "example.com", "title" => "Example News" },
      "authors" => [{ "name" => "Jane Doe", "type" => "author" }],
      "image" => "https://example.com/image.jpg",
      "sentiment" => 0.35,
      "lang" => "eng",
      "isDuplicate" => false
    }
  end

  describe ".from_news_api_ai" do
    it "builds an article from NewsAPI.ai hash" do
      article = described_class.from_news_api_ai(api_ai_hash)

      expect(article.source_id).to eq("example.com")
      expect(article.source_name).to eq("Example News")
      expect(article.author).to eq("Jane Doe")
      expect(article.title).to eq("Test Article Title")
      expect(article.url).to eq("https://example.com/article")
      expect(article.image_url).to eq("https://example.com/image.jpg")
      expect(article.published_at).to eq(Time.parse("2025-12-04T08:07:28Z"))
      expect(article.content).to eq("Full article body content goes here.")
      expect(article.sentiment).to eq(0.35)
      expect(article.language).to eq("eng")
      expect(article.is_duplicate).to eq(false)
      expect(article.raw_payload).to eq(api_ai_hash)
    end

    it "falls back to dateTime if dateTimePub is missing" do
      article = described_class.from_news_api_ai(api_ai_hash.except("dateTimePub"))
      expect(article.published_at).to eq(Time.parse("2025-12-04T08:08:08Z"))
    end

    it "falls back to source uri if title is missing" do
      hash = api_ai_hash.merge("source" => { "uri" => "example.com" })
      article = described_class.from_news_api_ai(hash)
      expect(article.source_name).to eq("example.com")
    end

    it "truncates body for description" do
      long_body = "x" * 600
      article = described_class.from_news_api_ai(api_ai_hash.merge("body" => long_body))
      expect(article.description.length).to be <= 500
    end
  end

  describe ".upsert_from_news_api_ai" do
    it "creates a new article" do
      expect {
        described_class.upsert_from_news_api_ai(api_ai_hash)
      }.to change(described_class, :count).by(1)
    end

    it "updates existing article by URL" do
      described_class.upsert_from_news_api_ai(api_ai_hash)

      updated_hash = api_ai_hash.merge("body" => "Updated body", "sentiment" => 0.8)

      expect {
        described_class.upsert_from_news_api_ai(updated_hash)
      }.not_to change(described_class, :count)

      article = described_class.find_by(url: api_ai_hash["url"])
      expect(article.content).to eq("Updated body")
      expect(article.sentiment).to eq(0.8)
    end
  end

  describe "validations" do
    it "requires source_name" do
      article = described_class.from_news_api_ai(api_ai_hash.merge("source" => { "uri" => nil, "title" => nil }))
      expect(article).not_to be_valid
      expect(article.errors[:source_name]).to include("can't be blank")
    end

    it "requires title" do
      article = described_class.from_news_api_ai(api_ai_hash.merge("title" => nil))
      expect(article).not_to be_valid
    end

    it "requires url" do
      article = described_class.from_news_api_ai(api_ai_hash.merge("url" => nil))
      expect(article).not_to be_valid
    end

    it "requires published_at" do
      article = described_class.from_news_api_ai(api_ai_hash.merge("dateTimePub" => nil, "dateTime" => nil))
      expect(article).not_to be_valid
    end

    it "requires unique url" do
      described_class.upsert_from_news_api_ai(api_ai_hash)

      duplicate = described_class.from_news_api_ai(api_ai_hash)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:url]).to include("has already been taken")
    end
  end

  describe "scopes" do
    before do
      described_class.upsert_from_news_api_ai(api_ai_hash)
      described_class.upsert_from_news_api_ai(
        api_ai_hash.merge(
          "uri" => "8985357962",
          "url" => "https://cnn.com/article",
          "source" => { "uri" => "cnn.com", "title" => "CNN" },
          "dateTimePub" => "2025-12-03T10:00:00Z",
          "sentiment" => -0.5,
          "lang" => "deu"
        )
      )
    end

    it ".recent orders by published_at desc" do
      articles = described_class.recent
      expect(articles.first.source_name).to eq("Example News")
    end

    it ".from_source filters by source name" do
      articles = described_class.from_source("CNN")
      expect(articles.count).to eq(1)
      expect(articles.first.source_name).to eq("CNN")
    end

    it ".published_after filters by time" do
      articles = described_class.published_after(Time.parse("2025-12-03T12:00:00Z"))
      expect(articles.count).to eq(1)
    end

    it ".positive_sentiment filters positive" do
      expect(described_class.positive_sentiment.count).to eq(1)
    end

    it ".negative_sentiment filters negative" do
      expect(described_class.negative_sentiment.count).to eq(1)
    end

    it ".in_language filters by language" do
      expect(described_class.in_language("eng").count).to eq(1)
      expect(described_class.in_language("deu").count).to eq(1)
    end
  end

  describe "concept associations" do
    let(:article) { described_class.upsert_from_news_api_ai(api_ai_hash) }
    let!(:person) { Concept.create!(uri: "http://wiki/person", concept_type: "person", label: "John Doe") }
    let!(:org) { Concept.create!(uri: "http://wiki/org", concept_type: "org", label: "Acme Corp") }
    let!(:location) { Concept.create!(uri: "http://wiki/loc", concept_type: "loc", label: "New York") }
    let!(:topic) { Concept.create!(uri: "http://wiki/topic", concept_type: "wiki", label: "Technology") }

    before do
      article.article_concepts.create!(concept: person, score: 5)
      article.article_concepts.create!(concept: org, score: 4)
      article.article_concepts.create!(concept: location, score: 3)
      article.article_concepts.create!(concept: topic, score: 2)
    end

    it "#people returns person concepts" do
      expect(article.people.pluck(:label)).to eq(["John Doe"])
    end

    it "#organizations returns org concepts" do
      expect(article.organizations.pluck(:label)).to eq(["Acme Corp"])
    end

    it "#locations returns loc concepts" do
      expect(article.locations.pluck(:label)).to eq(["New York"])
    end

    it "#topics returns wiki concepts" do
      expect(article.topics.pluck(:label)).to eq(["Technology"])
    end
  end

  describe "category associations" do
    let(:article) { described_class.upsert_from_news_api_ai(api_ai_hash) }
    let!(:cat1) { Category.create!(uri: "news/Business", label: "news/Business") }
    let!(:cat2) { Category.create!(uri: "dmoz/Tech", label: "dmoz/Tech") }

    before do
      article.article_categories.create!(category: cat1, weight: 100)
      article.article_categories.create!(category: cat2, weight: 50)
    end

    it "#primary_category returns highest weight category" do
      expect(article.primary_category).to eq(cat1)
    end

    it "#categories returns all categories" do
      expect(article.categories.count).to eq(2)
    end
  end
end
