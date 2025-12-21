module NewsApiAi
  class Client
    BASE_URL = "https://eventregistry.org".freeze

    Error = Class.new(StandardError)
    ApiError = Class.new(Error)
    AuthenticationError = Class.new(Error)
    RateLimitError = Class.new(Error)

    def initialize(api_key: nil)
      @api_key = api_key || Rails.application.credentials.dig(:news_api_ai, :key)
    end

    # Fetch articles matching search criteria
    #
    # @param keyword [String, Array<String>] Keywords to search for
    # @param lang [String] Language code (default: "eng")
    # @param date_start [String, Date] Start date for articles
    # @param date_end [String, Date] End date for articles
    # @param source_location_uri [String] Filter by source country (e.g., "http://en.wikipedia.org/wiki/United_States")
    # @param count [Integer] Number of articles to return (default: 50, max: 100)
    # @param page [Integer] Page number for pagination (default: 1)
    # @param sort_by [String] Sort order: date, rel, sourceImportance, sourceAlexaGlobalRank (default: date)
    # @return [Hash] Response with articles array and pagination info
    def get_articles(
      keyword: nil,
      lang: "eng",
      date_start: nil,
      date_end: nil,
      source_location_uri: nil,
      count: 50,
      page: 1,
      sort_by: "date"
    )
      params = {
        apiKey: api_key,
        resultType: "articles",
        articlesCount: count,
        articlesPage: page,
        articlesSortBy: sort_by,
        articleBodyLen: -1, # Full body
        lang: lang,
        includeArticleBody: true,
        includeArticleSentiment: true,
        includeArticleLocation: true,
        includeArticleImage: true,
        includeSourceTitle: true,
        includeSourceDescription: true
      }

      params[:keyword] = keyword if keyword.present?
      params[:dateStart] = format_date(date_start) if date_start
      params[:dateEnd] = format_date(date_end) if date_end
      params[:sourceLocationUri] = source_location_uri if source_location_uri

      get("/api/v1/article/getArticles", params)
    end

    # Convenience method to get recent US news (similar to NewsAPI.org top_headlines)
    #
    # @param count [Integer] Number of articles
    # @return [Hash] Response with articles
    def top_headlines(country: "us", count: 50)
      location_uri = country_to_location_uri(country)

      get_articles(
        source_location_uri: location_uri,
        count: count,
        date_start: 1.day.ago.to_date,
        sort_by: "date"
      )
    end

    # Fetch articles from the minute stream (incremental updates)
    #
    # @param after_uri [String] Only return articles added after this URI
    # @param lang [String] Language code (default: "eng")
    # @param source_location_uri [String] Filter by source country
    # @param count [Integer] Max articles to return (default: 100, max: 2000)
    # @return [Hash] Response with articles in recentActivityArticles
    def minute_stream_articles(after_uri: nil, lang: "eng", source_location_uri: nil, count: 100)
      params = {
        apiKey: api_key,
        recentActivityArticlesMaxArticleCount: count,
        lang: lang,
        articleBodyLen: -1,
        includeArticleBody: true,
        includeArticleSentiment: true,
        includeArticleLocation: true,
        includeArticleImage: true,
        includeSourceTitle: true
      }

      params[:recentActivityArticlesNewsUpdatesAfterUri] = after_uri if after_uri.present?
      params[:sourceLocationUri] = source_location_uri if source_location_uri.present?

      get("/api/v1/minuteStreamArticles", params)
    end

    private

    attr_reader :api_key

    def get(path, params = {})
      response = connection.get(path, params)
      handle_response(response)
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :url_encoded
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      body = response.body

      case response.status
      when 200
        if body.is_a?(Hash) && body["error"]
          raise ApiError, body["error"]
        end
        body
      when 401, 403
        raise AuthenticationError, body["error"] || "Invalid API key"
      when 429
        raise RateLimitError, body["error"] || "Rate limit exceeded"
      else
        raise ApiError, body["error"] || "Request failed with status #{response.status}"
      end
    end

    def format_date(date)
      return date if date.is_a?(String)

      date.to_date.iso8601
    end

    def country_to_location_uri(country_code)
      # Map common country codes to Wikipedia URIs
      # Event Registry uses Wikipedia URIs for locations
      mapping = {
        "us" => "http://en.wikipedia.org/wiki/United_States",
        "gb" => "http://en.wikipedia.org/wiki/United_Kingdom",
        "uk" => "http://en.wikipedia.org/wiki/United_Kingdom",
        "ca" => "http://en.wikipedia.org/wiki/Canada",
        "au" => "http://en.wikipedia.org/wiki/Australia",
        "de" => "http://en.wikipedia.org/wiki/Germany",
        "fr" => "http://en.wikipedia.org/wiki/France"
      }

      mapping[country_code.to_s.downcase] || raise(ArgumentError, "Unknown country code: #{country_code}")
    end
  end
end
