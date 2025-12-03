require "rails_helper"

RSpec.describe FetchHeadlinesJob do
  let(:article_data) do
    {
      "source" => { "id" => "bbc-news", "name" => "BBC News" },
      "author" => "BBC Reporter",
      "title" => "Breaking news headline",
      "description" => "A short description",
      "url" => "https://bbc.com/news/article-123",
      "urlToImage" => "https://bbc.com/image.jpg",
      "publishedAt" => "2024-01-15T10:00:00Z",
      "content" => "Article content..."
    }
  end

  let(:api_response) do
    {
      "status" => "ok",
      "totalResults" => 1,
      "articles" => [article_data]
    }
  end

  before do
    allow_any_instance_of(NewsApi::Client).to receive(:top_headlines).and_return(api_response)
  end

  it "fetches headlines and stores articles" do
    expect {
      described_class.new.perform(country: "us")
    }.to change(Article, :count).by(1)
  end

  it "enqueues analysis job for each article" do
    expect {
      described_class.new.perform(country: "us")
    }.to have_enqueued_job(AnalyzeArticleJob)
  end

  it "skips articles with blank titles" do
    api_response["articles"] << article_data.merge("title" => "", "url" => "https://other.com")

    expect {
      described_class.new.perform(country: "us")
    }.to change(Article, :count).by(1)
  end

  it "skips articles with blank urls" do
    api_response["articles"] << article_data.merge("url" => "", "title" => "Other")

    expect {
      described_class.new.perform(country: "us")
    }.to change(Article, :count).by(1)
  end

  it "handles duplicate articles gracefully" do
    Article.upsert_from_news_api(article_data)

    expect {
      described_class.new.perform(country: "us")
    }.not_to change(Article, :count)
  end

  it "returns stats" do
    result = described_class.new.perform(country: "us")

    expect(result[:stored]).to eq(1)
    expect(result[:skipped]).to eq(0)
    expect(result[:total]).to eq(1)
  end

  it "does nothing when status is not ok" do
    allow_any_instance_of(NewsApi::Client).to receive(:top_headlines).and_return({ "status" => "error" })

    expect {
      described_class.new.perform(country: "us")
    }.not_to change(Article, :count)
  end

  it "passes category to the client" do
    expect_any_instance_of(NewsApi::Client).to receive(:top_headlines)
      .with(country: "us", category: "technology")
      .and_return(api_response)

    described_class.new.perform(country: "us", category: "technology")
  end
end
