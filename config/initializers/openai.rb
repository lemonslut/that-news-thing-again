OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openrouter, :api_key)
  config.uri_base = "https://openrouter.ai/api/v1"
  config.extra_headers = {
    "HTTP-Referer" => ENV.fetch("APP_URL", "http://localhost:3000"),
    "X-Title" => "NewsDigest"
  }
end
