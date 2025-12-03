# How to Analyze Articles

Analysis is split into two independent jobs: entity extraction and calm summary generation.

## Extract Entities from a Single Article

```ruby
article = Article.without_entities.first
ExtractEntitiesJob.perform_now(article.id)
```

## Generate Calm Summary for a Single Article

```ruby
article = Article.without_summary.first
GenerateCalmSummaryJob.perform_now(article.id)
```

## Run Both on an Article

```ruby
article = Article.first
ExtractEntitiesJob.perform_now(article.id)
GenerateCalmSummaryJob.perform_now(article.id)
```

## Process All Unprocessed Articles

```ruby
# Extract entities for all articles that need it
Article.without_entities.find_each do |article|
  ExtractEntitiesJob.perform_now(article.id)
end

# Generate summaries for all articles that need it
Article.without_summary.find_each do |article|
  GenerateCalmSummaryJob.perform_now(article.id)
end
```

## Process Asynchronously

Queue for Sidekiq:

```ruby
Article.without_entities.find_each do |article|
  ExtractEntitiesJob.perform_later(article.id)
  GenerateCalmSummaryJob.perform_later(article.id)
end
```

## Use a Different Model

The default model is `anthropic/claude-3-haiku`. Override it:

```ruby
ExtractEntitiesJob.perform_now(article.id, model: "openai/gpt-4o-mini")
GenerateCalmSummaryJob.perform_now(article.id, model: "anthropic/claude-3-sonnet")
```

Available models depend on your OpenRouter account. Popular options:

- `anthropic/claude-3-haiku` — Fast, cheap, good for extraction
- `anthropic/claude-3-sonnet` — Better quality, slower
- `openai/gpt-4o-mini` — OpenAI alternative

## Re-analyze an Article

You can run extraction/summary multiple times. Each run creates a new record:

```ruby
article = Article.find(123)

# Run entity extraction again (creates new ArticleEntityExtraction)
ExtractEntitiesJob.perform_now(article.id)

# Run summary again (creates new ArticleCalmSummary)
GenerateCalmSummaryJob.perform_now(article.id)
```

The UI shows the latest extraction and summary.

## Check Extraction Results

```ruby
article = Article.find(123)

# Direct entity access (canonical relationship)
puts article.category&.name      # "politics"
puts article.tags.pluck(:name)   # ["election", "senate"]
puts article.people.pluck(:name) # ["joe biden", "nancy pelosi"]

# Calm summary
puts article.calm_summary&.summary  # "Congress debates new legislation."

# Extraction audit trail
extraction = article.latest_extraction
puts extraction.model_used       # "anthropic/claude-3-haiku"
puts extraction.prompt&.version  # 1
puts extraction.entities.count   # 8
```

## Batch Processing with Progress

```ruby
total = Article.without_entities.count
Article.without_entities.find_each.with_index do |article, i|
  ExtractEntitiesJob.perform_now(article.id)
  GenerateCalmSummaryJob.perform_now(article.id)
  puts "#{i + 1}/#{total}" if (i + 1) % 10 == 0
end
```

## Handle Errors

The jobs will raise on API errors. For resilience:

```ruby
Article.without_entities.find_each do |article|
  begin
    ExtractEntitiesJob.perform_now(article.id)
    GenerateCalmSummaryJob.perform_now(article.id)
  rescue Completions::Client::Error => e
    puts "Failed to analyze #{article.id}: #{e.message}"
  end
end
```
