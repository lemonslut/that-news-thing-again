require "rails_helper"

RSpec.describe FetchArticlesJob, type: :job do
  let(:client) { instance_double(NewsApiAi::Client) }

  before do
    allow(NewsApiAi::Client).to receive(:new).and_return(client)
  end

  def stub_top_headlines(articles)
    allow(client).to receive(:top_headlines).and_return({
      "articles" => {
        "results" => articles,
        "totalResults" => articles.size
      }
    })
  end

  def build_article_data(overrides = {})
    {
      "uri" => "123456",
      "title" => "Test Article",
      "url" => "https://example.com/article",
      "body" => "Full article body content here.",
      "dateTimePub" => "2025-12-04T08:00:00Z",
      "source" => { "uri" => "example.com", "title" => "Example News" },
      "authors" => [{ "name" => "Jane Doe", "type" => "author" }],
      "concepts" => [],
      "categories" => [],
      "sentiment" => 0.5,
      "lang" => "eng",
      "isDuplicate" => false,
      "image" => "https://example.com/image.jpg"
    }.merge(overrides)
  end

  describe "#perform" do
    it "fetches articles from NewsAPI.ai and stores them" do
      stub_top_headlines([build_article_data])

      expect { described_class.new.perform }
        .to change(Article, :count).by(1)
    end

    it "skips articles without title" do
      stub_top_headlines([build_article_data("title" => nil)])

      expect { described_class.new.perform }
        .not_to change(Article, :count)
    end

    it "skips articles without url" do
      stub_top_headlines([build_article_data("url" => nil)])

      expect { described_class.new.perform }
        .not_to change(Article, :count)
    end

    it "stores full article body as content" do
      body = "This is a much longer article body with full content."
      stub_top_headlines([build_article_data("body" => body)])

      described_class.new.perform

      expect(Article.last.content).to eq(body)
    end

    it "stores sentiment" do
      stub_top_headlines([build_article_data("sentiment" => 0.75)])

      described_class.new.perform

      expect(Article.last.sentiment).to eq(0.75)
    end

    it "stores language" do
      stub_top_headlines([build_article_data("lang" => "deu")])

      described_class.new.perform

      expect(Article.last.language).to eq("deu")
    end

    it "enqueues GenerateCalmSummaryJob for each article" do
      stub_top_headlines([build_article_data])

      expect { described_class.new.perform }
        .to have_enqueued_job(GenerateCalmSummaryJob)
    end

    it "returns stats about stored and skipped articles" do
      stub_top_headlines([
        build_article_data,
        build_article_data("title" => nil)
      ])

      result = described_class.new.perform

      expect(result[:stored]).to eq(1)
      expect(result[:total]).to eq(2)
    end

    it "upserts existing articles" do
      stub_top_headlines([build_article_data])
      described_class.new.perform

      stub_top_headlines([build_article_data("body" => "Updated body")])

      expect { described_class.new.perform }
        .not_to change(Article, :count)

      expect(Article.last.content).to eq("Updated body")
    end
  end

  describe "concept extraction" do
    it "extracts person concepts" do
      article_data = build_article_data(
        "concepts" => [
          { "uri" => "http://wiki/brad", "type" => "person", "label" => { "eng" => "Brad Garlinghouse" }, "score" => 5 }
        ]
      )
      stub_top_headlines([article_data])

      expect { described_class.new.perform }
        .to change(Concept, :count).by(1)

      article = Article.last
      expect(article.people.pluck(:label)).to include("Brad Garlinghouse")
    end

    it "extracts organization concepts" do
      article_data = build_article_data(
        "concepts" => [
          { "uri" => "http://wiki/binance", "type" => "org", "label" => { "eng" => "Binance" }, "score" => 5 }
        ]
      )
      stub_top_headlines([article_data])

      described_class.new.perform

      article = Article.last
      expect(article.organizations.pluck(:label)).to include("Binance")
    end

    it "extracts location concepts" do
      article_data = build_article_data(
        "concepts" => [
          { "uri" => "http://wiki/dubai", "type" => "loc", "label" => { "eng" => "Dubai" }, "score" => 2 }
        ]
      )
      stub_top_headlines([article_data])

      described_class.new.perform

      article = Article.last
      expect(article.locations.pluck(:label)).to include("Dubai")
    end

    it "extracts wiki/topic concepts" do
      article_data = build_article_data(
        "concepts" => [
          { "uri" => "http://wiki/blockchain", "type" => "wiki", "label" => { "eng" => "Blockchain" }, "score" => 5 }
        ]
      )
      stub_top_headlines([article_data])

      described_class.new.perform

      article = Article.last
      expect(article.topics.pluck(:label)).to include("Blockchain")
    end

    it "stores concept scores" do
      article_data = build_article_data(
        "concepts" => [
          { "uri" => "http://wiki/test", "type" => "person", "label" => { "eng" => "Test Person" }, "score" => 4 }
        ]
      )
      stub_top_headlines([article_data])

      described_class.new.perform

      article = Article.last
      expect(article.article_concepts.first.score).to eq(4)
    end

    it "reuses existing concepts by URI" do
      Concept.create!(uri: "http://wiki/existing", concept_type: "person", label: "Existing Person")

      article_data = build_article_data(
        "concepts" => [
          { "uri" => "http://wiki/existing", "type" => "person", "label" => { "eng" => "Existing Person" }, "score" => 5 }
        ]
      )
      stub_top_headlines([article_data])

      expect { described_class.new.perform }
        .not_to change(Concept, :count)
    end
  end

  describe "category extraction" do
    it "extracts categories" do
      article_data = build_article_data(
        "categories" => [
          { "uri" => "news/Business", "label" => "news/Business", "wgt" => 70 }
        ]
      )
      stub_top_headlines([article_data])

      expect { described_class.new.perform }
        .to change(Category, :count).by(1)

      article = Article.last
      expect(article.categories.pluck(:uri)).to include("news/Business")
    end

    it "stores category weights" do
      article_data = build_article_data(
        "categories" => [
          { "uri" => "news/Business", "label" => "news/Business", "wgt" => 100 }
        ]
      )
      stub_top_headlines([article_data])

      described_class.new.perform

      article = Article.last
      expect(article.article_categories.first.weight).to eq(100)
    end

    it "extracts multiple categories" do
      article_data = build_article_data(
        "categories" => [
          { "uri" => "news/Business", "label" => "news/Business", "wgt" => 100 },
          { "uri" => "dmoz/Investing", "label" => "dmoz/Investing", "wgt" => 50 }
        ]
      )
      stub_top_headlines([article_data])

      described_class.new.perform

      article = Article.last
      expect(article.categories.count).to eq(2)
    end

    it "reuses existing categories by URI" do
      Category.create!(uri: "news/Business", label: "news/Business")

      article_data = build_article_data(
        "categories" => [
          { "uri" => "news/Business", "label" => "news/Business", "wgt" => 70 }
        ]
      )
      stub_top_headlines([article_data])

      expect { described_class.new.perform }
        .not_to change(Category, :count)
    end
  end
end
