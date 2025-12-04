# Services Reference

## NewsApiAi::Client

HTTP client for the NewsAPI.ai (Event Registry) API. Provides full article bodies and pre-extracted entities.

### Location

`app/services/news_api_ai/client.rb`

### Constructor

```ruby
NewsApiAi::Client.new(api_key: nil)
```

- `api_key` — Optional. Defaults to credentials `news_api_ai.key`

### Methods

#### get_articles

Fetch articles with search criteria.

```ruby
client.get_articles(
  keyword: nil,           # Keywords to search for
  lang: "eng",            # Language code
  date_start: nil,        # Start date
  date_end: nil,          # End date
  source_location_uri: nil, # Filter by source country (Wikipedia URI)
  count: 50,              # Number of articles (max 100)
  page: 1,                # Page number
  sort_by: "date"         # Sort order: date, rel, sourceImportance
)
```

Returns parsed JSON response:

```ruby
{
  "articles" => {
    "results" => [...],
    "totalResults" => 500
  }
}
```

#### top_headlines

Convenience method for recent news by country.

```ruby
client.top_headlines(country: "us", count: 50)
```

Supported country codes: `us`, `gb`, `uk`, `ca`, `au`, `de`, `fr`

### Response Fields

Each article includes:

- `title`, `body`, `url`, `image` — Article content
- `dateTime`, `dateTimePub` — Timestamps
- `source` — `{ uri, title, description }`
- `authors` — Array of `{ name, type }`
- `concepts` — Pre-extracted entities with types (`person`, `org`, `loc`, `wiki`)
- `categories` — Article categories (e.g., `news/Business`)
- `sentiment` — Sentiment score (-1 to 1)

### Errors

- `NewsApiAi::Client::Error` — Base error class
- `NewsApiAi::Client::ApiError` — General API errors
- `NewsApiAi::Client::AuthenticationError` — Invalid API key (401, 403)
- `NewsApiAi::Client::RateLimitError` — Rate limit exceeded (429)

### Example

```ruby
client = NewsApiAi::Client.new
result = client.top_headlines(country: "us", count: 10)

result["articles"]["results"].each do |article|
  puts article["title"]
  puts "Sentiment: #{article["sentiment"]}"
  puts "Entities: #{article["concepts"].map { |c| c.dig("label", "eng") }.join(", ")}"
end
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
