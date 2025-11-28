require "rails_helper"

RSpec.describe Article do
  let(:article_hash) do
    {
      "source" => { "id" => "bbc-news", "name" => "BBC News" },
      "author" => "BBC Reporter",
      "title" => "Breaking news headline",
      "description" => "A short description of the article",
      "url" => "https://bbc.com/news/article-123",
      "urlToImage" => "https://bbc.com/image.jpg",
      "publishedAt" => "2024-01-15T10:00:00Z",
      "content" => "Article content truncated..."
    }
  end

  describe ".from_news_api" do
    it "builds an article from NewsAPI hash" do
      article = described_class.from_news_api(article_hash)

      expect(article.source_id).to eq("bbc-news")
      expect(article.source_name).to eq("BBC News")
      expect(article.author).to eq("BBC Reporter")
      expect(article.title).to eq("Breaking news headline")
      expect(article.description).to eq("A short description of the article")
      expect(article.url).to eq("https://bbc.com/news/article-123")
      expect(article.image_url).to eq("https://bbc.com/image.jpg")
      expect(article.published_at).to eq(Time.parse("2024-01-15T10:00:00Z"))
      expect(article.content).to eq("Article content truncated...")
      expect(article.raw_payload).to eq(article_hash)
    end
  end

  describe ".upsert_from_news_api" do
    it "creates a new article" do
      expect {
        described_class.upsert_from_news_api(article_hash)
      }.to change(described_class, :count).by(1)
    end

    it "updates existing article by URL" do
      described_class.upsert_from_news_api(article_hash)

      updated_hash = article_hash.merge("title" => "Updated headline")

      expect {
        described_class.upsert_from_news_api(updated_hash)
      }.not_to change(described_class, :count)

      article = described_class.find_by(url: article_hash["url"])
      expect(article.raw_payload["title"]).to eq("Updated headline")
    end
  end

  describe "validations" do
    it "requires source_name" do
      article = described_class.from_news_api(article_hash.merge("source" => { "name" => nil }))
      expect(article).not_to be_valid
      expect(article.errors[:source_name]).to include("can't be blank")
    end

    it "requires title" do
      article = described_class.from_news_api(article_hash.merge("title" => nil))
      expect(article).not_to be_valid
    end

    it "requires url" do
      article = described_class.from_news_api(article_hash.merge("url" => nil))
      expect(article).not_to be_valid
    end

    it "requires published_at" do
      article = described_class.from_news_api(article_hash.merge("publishedAt" => nil))
      expect(article).not_to be_valid
    end

    it "requires unique url" do
      described_class.upsert_from_news_api(article_hash)

      duplicate = described_class.from_news_api(article_hash)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:url]).to include("has already been taken")
    end
  end

  describe "scopes" do
    before do
      described_class.upsert_from_news_api(article_hash)
      described_class.upsert_from_news_api(
        article_hash.merge(
          "url" => "https://cnn.com/article",
          "source" => { "name" => "CNN" },
          "publishedAt" => "2024-01-14T10:00:00Z"
        )
      )
    end

    it ".recent orders by published_at desc" do
      articles = described_class.recent
      expect(articles.first.source_name).to eq("BBC News")
    end

    it ".from_source filters by source name" do
      articles = described_class.from_source("CNN")
      expect(articles.count).to eq(1)
      expect(articles.first.source_name).to eq("CNN")
    end

    it ".published_after filters by time" do
      articles = described_class.published_after(Time.parse("2024-01-14T12:00:00Z"))
      expect(articles.count).to eq(1)
    end
  end
end
