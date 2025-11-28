# Services Reference

## NewsApi::Client

HTTP client for the NewsAPI.org API.

### Location

`app/services/news_api/client.rb`

### Constructor

```ruby
NewsApi::Client.new(api_key: nil)
```

- `api_key` — Optional. Defaults to `ENV["NEWS_API_KEY"]`

### Methods

#### top_headlines

Fetch top headlines.

```ruby
client.top_headlines(
  country: nil,    # 2-letter ISO code (e.g., "us", "gb")
  category: nil,   # business, entertainment, general, health, science, sports, technology
  sources: nil,    # Comma-separated source IDs (cannot combine with country/category)
  q: nil,          # Search query
  page_size: nil,  # Results per page (max 100)
  page: nil        # Page number
)
```

Returns parsed JSON response:

```ruby
{
  "status" => "ok",
  "totalResults" => 35,
  "articles" => [...]
}
```

### Errors

- `NewsApi::Client::Error` — Base error class
- `NewsApi::Client::ApiError` — General API errors
- `NewsApi::Client::AuthenticationError` — Invalid API key (401)
- `NewsApi::Client::RateLimitError` — Rate limit exceeded (429, 426)

### Example

```ruby
client = NewsApi::Client.new
result = client.top_headlines(country: "us", category: "technology")
result["articles"].each { |a| puts a["title"] }
```

---

## Completions::Client

LLM client for article analysis via OpenRouter.

### Location

`app/services/completions/client.rb`

### Constructor

```ruby
Completions::Client.new(model: nil)
```

- `model` — Optional. Defaults to `"anthropic/claude-3-haiku"`

### Methods

#### complete

Send a chat completion request.

```ruby
client.complete(messages, json: false)
```

- `messages` — Array of message hashes or strings
- `json` — If true, parse response as JSON

Returns string or parsed JSON.

#### analyze_article

Analyze an Article record.

```ruby
client.analyze_article(article)
```

Returns hash:

```ruby
{
  "category" => "politics",
  "tags" => ["election", "senate"],
  "entities" => { "people" => [...], "organizations" => [...], "places" => [...] },
  "political_lean" => "center",  # or nil
  "calm_summary" => "A calm summary of the news."
}
```

### Errors

- `Completions::Client::Error` — API errors or JSON parsing failures

### Configuration

Configured in `config/initializers/openai.rb`:

```ruby
OpenAI.configure do |config|
  config.access_token = ENV["OPENROUTER_API_KEY"]
  config.uri_base = "https://openrouter.ai/api/v1"
end
```

### Example

```ruby
client = Completions::Client.new(model: "openai/gpt-4o-mini")
result = client.analyze_article(Article.first)
puts result["calm_summary"]
```
