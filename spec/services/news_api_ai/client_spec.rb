require "rails_helper"

RSpec.describe NewsApiAi::Client do
  let(:client) { described_class.new }

  describe "#get_articles", :vcr do
    it "fetches articles with keyword search", vcr: { cassette_name: "news_api_ai/get_articles_technology" } do
      result = client.get_articles(keyword: "technology", count: 5)

      expect(result["articles"]["results"]).to be_an(Array)
      expect(result["articles"]["totalResults"]).to be > 0
    end

    it "includes concepts in the response", vcr: { cassette_name: "news_api_ai/get_articles_technology" } do
      result = client.get_articles(keyword: "technology", count: 5)

      article = result["articles"]["results"].first
      expect(article["concepts"]).to be_an(Array)
    end

    it "includes categories in the response", vcr: { cassette_name: "news_api_ai/get_articles_technology" } do
      result = client.get_articles(keyword: "technology", count: 5)

      article = result["articles"]["results"].first
      expect(article["categories"]).to be_an(Array)
    end

    it "includes sentiment in the response", vcr: { cassette_name: "news_api_ai/get_articles_technology" } do
      result = client.get_articles(keyword: "technology", count: 5)

      article = result["articles"]["results"].first
      expect(article["sentiment"]).to be_a(Numeric)
    end

    it "includes full article body", vcr: { cassette_name: "news_api_ai/get_articles_technology" } do
      result = client.get_articles(keyword: "technology", count: 5)

      article = result["articles"]["results"].first
      expect(article["body"]).to be_present
      expect(article["body"].length).to be > 200 # Not truncated like NewsAPI.org
    end

    it "supports pagination", vcr: { cassette_name: "news_api_ai/get_articles_paginated" } do
      result = client.get_articles(keyword: "news", page: 2, count: 5)

      expect(result["articles"]["page"]).to eq(2)
    end
  end

  describe "#top_headlines", :vcr do
    it "fetches recent articles from US sources", vcr: { cassette_name: "news_api_ai/top_headlines_us" } do
      result = client.top_headlines(country: "us", count: 5)

      expect(result["articles"]["results"]).to be_an(Array)
      expect(result["articles"]["totalResults"]).to be > 0
    end

    it "raises ArgumentError for unknown country code" do
      expect { client.top_headlines(country: "zz") }
        .to raise_error(ArgumentError, /Unknown country code/)
    end
  end

  describe "error handling", :vcr_off do
    def stub_articles_api(status:, body:)
      stub_request(:get, /eventregistry\.org\/api\/v1\/article\/getArticles/)
        .to_return(
          status: status,
          body: body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "raises AuthenticationError on 401" do
      stub_articles_api(status: 401, body: { "error" => "Invalid API key" })

      expect { client.get_articles(keyword: "test") }
        .to raise_error(NewsApiAi::Client::AuthenticationError, "Invalid API key")
    end

    it "raises AuthenticationError on 403" do
      stub_articles_api(status: 403, body: { "error" => "Forbidden" })

      expect { client.get_articles(keyword: "test") }
        .to raise_error(NewsApiAi::Client::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      stub_articles_api(status: 429, body: { "error" => "Rate limit exceeded" })

      expect { client.get_articles(keyword: "test") }
        .to raise_error(NewsApiAi::Client::RateLimitError)
    end

    it "raises ApiError on 500" do
      stub_articles_api(status: 500, body: { "error" => "Internal server error" })

      expect { client.get_articles(keyword: "test") }
        .to raise_error(NewsApiAi::Client::ApiError)
    end

    it "raises ApiError when response contains error field" do
      stub_articles_api(status: 200, body: { "error" => "Invalid parameter" })

      expect { client.get_articles(keyword: "test") }
        .to raise_error(NewsApiAi::Client::ApiError, "Invalid parameter")
    end
  end

  describe "api key configuration", :vcr_off do
    def stub_articles_api
      stub_request(:get, /eventregistry\.org\/api\/v1\/article\/getArticles/)
        .to_return(
          status: 200,
          body: { "articles" => { "results" => [], "totalResults" => 0 } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "uses provided api_key" do
      stub = stub_articles_api

      client = described_class.new(api_key: "custom-key")
      client.get_articles(keyword: "test")

      expect(stub.with(query: hash_including("apiKey" => "custom-key"))).to have_been_requested
    end

    it "falls back to credentials" do
      stub = stub_articles_api
      expected_key = Rails.application.credentials.dig(:news_api_ai, :key)

      client = described_class.new
      client.get_articles(keyword: "test")

      expect(stub.with(query: hash_including("apiKey" => expected_key))).to have_been_requested
    end
  end
end
