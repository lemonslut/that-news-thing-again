# How to Fetch Articles

## Basic Fetch

Fetch articles from a country:

```ruby
FetchArticlesJob.perform_now(country: "us")
```

## Control Article Count

Specify how many articles to fetch (max 100):

```ruby
FetchArticlesJob.perform_now(country: "us", count: 25)
```

## Available Countries

Supported 2-letter codes: `us`, `gb`, `uk`, `ca`, `au`, `de`, `fr`

```ruby
FetchArticlesJob.perform_now(country: "gb")
```

## Fetch from Multiple Countries

Run multiple jobs:

```ruby
%w[us gb ca au].each do |country|
  FetchArticlesJob.perform_now(country: country, count: 25)
end
```

## Run Asynchronously

Queue jobs for Sidekiq:

```ruby
FetchArticlesJob.perform_later(country: "us")
```

Make sure Sidekiq is running:

```bash
bundle exec sidekiq
```

## Schedule Regular Fetches

Articles are fetched hourly via sidekiq-scheduler (see `config/sidekiq.yml`).

## Check Results

```ruby
# How many articles do we have?
Article.count

# Recent articles
Article.recent.limit(5).pluck(:title)

# Articles from today
Article.published_after(Time.current.beginning_of_day).count

# Articles with entities (all new articles have them)
Article.joins(:article_entities).distinct.count
```

## Direct Client Access

For exploration, use the client directly:

```ruby
client = NewsApiAi::Client.new
result = client.top_headlines(country: "us", count: 10)
result["articles"]["results"].each { |a| puts a["title"] }
```

Or use the rake task:

```bash
bundle exec rake news_api:console
# Then: client.top_headlines(country: "us")
```

## Keyword Search

Search for specific topics:

```ruby
client = NewsApiAi::Client.new
result = client.get_articles(keyword: "artificial intelligence", count: 20)
```
