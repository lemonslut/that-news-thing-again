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

    it "enqueues analysis jobs for each article" do
      stub_top_headlines([build_article_data])

      expect { described_class.new.perform }
        .to have_enqueued_job(GenerateFactualSummaryJob)
        .and have_enqueued_job(NerExtractionJob)
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
end
