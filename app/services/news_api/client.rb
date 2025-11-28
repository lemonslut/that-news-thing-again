module NewsApi
  class Client
    BASE_URL = "https://newsapi.org/v2/".freeze

    Error = Class.new(StandardError)
    ApiError = Class.new(Error)
    AuthenticationError = Class.new(Error)
    RateLimitError = Class.new(Error)

    def initialize(api_key: nil)
      @api_key = api_key || ENV.fetch("NEWS_API_KEY")
    end

    def top_headlines(country: nil, category: nil, sources: nil, q: nil, page_size: nil, page: nil)
      params = {
        country: country,
        category: category,
        sources: sources,
        q: q,
        pageSize: page_size,
        page: page
      }.compact

      get("top-headlines", params)
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
        f.headers["X-Api-Key"] = api_key
      end
    end

    def handle_response(response)
      body = response.body

      case response.status
      when 200
        raise ApiError, body["message"] if body["status"] == "error"
        body
      when 401
        raise AuthenticationError, body["message"] || "Invalid API key"
      when 426
        raise RateLimitError, body["message"] || "Rate limit exceeded"
      when 429
        raise RateLimitError, body["message"] || "Rate limit exceeded"
      else
        raise ApiError, body["message"] || "Request failed with status #{response.status}"
      end
    end
  end
end
