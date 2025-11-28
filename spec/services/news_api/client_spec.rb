require "rails_helper"

RSpec.describe NewsApi::Client do
  let(:client) { described_class.new }

  describe "#top_headlines", :vcr do
    it "fetches top headlines with country filter", vcr: { cassette_name: "news_api/top_headlines_us" } do
      result = client.top_headlines(country: "us")

      expect(result["status"]).to eq("ok")
      expect(result["articles"]).to be_an(Array)
      expect(result["totalResults"]).to be_a(Integer)
    end

    it "fetches top headlines with category filter", vcr: { cassette_name: "news_api/top_headlines_technology" } do
      result = client.top_headlines(category: "technology", country: "us")

      expect(result["status"]).to eq("ok")
      expect(result["articles"]).to be_an(Array)
    end

    it "fetches top headlines with search query", vcr: { cassette_name: "news_api/top_headlines_query" } do
      result = client.top_headlines(q: "bitcoin", country: "us")

      expect(result["status"]).to eq("ok")
    end

    it "supports pagination", vcr: { cassette_name: "news_api/top_headlines_paginated" } do
      result = client.top_headlines(country: "us", page_size: 5, page: 1)

      expect(result["status"]).to eq("ok")
      expect(result["articles"].size).to be <= 5
    end

    it "supports sources filter", vcr: { cassette_name: "news_api/top_headlines_sources" } do
      result = client.top_headlines(sources: "bbc-news")

      expect(result["status"]).to eq("ok")
    end
  end

  describe "#top_headlines error handling" do
    let(:client) { described_class.new(api_key: "bad-key") }

    it "raises AuthenticationError on 401" do
      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" })
        .to_return(
          status: 401,
          body: { "status" => "error", "message" => "Invalid API key" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.top_headlines(country: "us") }
        .to raise_error(NewsApi::Client::AuthenticationError, "Invalid API key")
    end

    it "raises RateLimitError on 429" do
      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" })
        .to_return(
          status: 429,
          body: { "status" => "error", "message" => "Rate limit exceeded" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.top_headlines(country: "us") }
        .to raise_error(NewsApi::Client::RateLimitError)
    end

    it "raises RateLimitError on 426 (upgrade required for dev keys)" do
      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" })
        .to_return(
          status: 426,
          body: { "status" => "error", "message" => "Upgrade required" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.top_headlines(country: "us") }
        .to raise_error(NewsApi::Client::RateLimitError)
    end

    it "raises ApiError on other errors" do
      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" })
        .to_return(
          status: 500,
          body: { "status" => "error", "message" => "Server error" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.top_headlines(country: "us") }
        .to raise_error(NewsApi::Client::ApiError, "Server error")
    end

    it "raises ApiError when status is ok but body indicates error" do
      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" })
        .to_return(
          status: 200,
          body: { "status" => "error", "message" => "Parameter error" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect { client.top_headlines(country: "us") }
        .to raise_error(NewsApi::Client::ApiError, "Parameter error")
    end
  end

  describe "api key configuration" do
    it "uses provided api_key" do
      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" }, headers: { "X-Api-Key" => "custom-key" })
        .to_return(
          status: 200,
          body: { "status" => "ok", "articles" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client = described_class.new(api_key: "custom-key")
      client.top_headlines(country: "us")
    end

    it "falls back to NEWS_API_KEY env var" do
      allow(ENV).to receive(:fetch).with("NEWS_API_KEY").and_return("env-key")

      stub_request(:get, "https://newsapi.org/v2/top-headlines")
        .with(query: { country: "us" }, headers: { "X-Api-Key" => "env-key" })
        .to_return(
          status: 200,
          body: { "status" => "ok", "articles" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client = described_class.new
      client.top_headlines(country: "us")
    end
  end
end
