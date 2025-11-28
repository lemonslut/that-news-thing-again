# How to Analyze Articles

## Analyze a Single Article

```ruby
article = Article.unanalyzed.first
AnalyzeArticleJob.perform_now(article.id)
```

## Analyze All Unanalyzed Articles

```ruby
Article.unanalyzed.find_each do |article|
  AnalyzeArticleJob.perform_now(article.id)
end
```

## Analyze Asynchronously

Queue for Sidekiq:

```ruby
Article.unanalyzed.find_each do |article|
  AnalyzeArticleJob.perform_later(article.id)
end
```

## Use a Different Model

The default model is `anthropic/claude-3-haiku`. Override it:

```ruby
AnalyzeArticleJob.perform_now(article.id, model: "openai/gpt-4o-mini")
```

Available models depend on your OpenRouter account. Popular options:

- `anthropic/claude-3-haiku` — Fast, cheap, good for categorization
- `anthropic/claude-3-sonnet` — Better quality, slower
- `openai/gpt-4o-mini` — OpenAI alternative

## Re-analyze an Article

Delete the existing analysis first:

```ruby
article = Article.find(123)
article.analysis&.destroy
AnalyzeArticleJob.perform_now(article.id)
```

## Check Analysis Results

```ruby
article = Article.find(123)
analysis = article.analysis

puts analysis.category        # "politics"
puts analysis.tags            # ["election", "senate"]
puts analysis.calm_summary    # "Congress debates new legislation."
puts analysis.political_lean  # "center" or nil
puts analysis.entities        # {"people" => [...], "organizations" => [...]}
```

## Batch Processing with Progress

```ruby
total = Article.unanalyzed.count
Article.unanalyzed.find_each.with_index do |article, i|
  AnalyzeArticleJob.perform_now(article.id)
  puts "#{i + 1}/#{total}" if (i + 1) % 10 == 0
end
```

## Handle Errors

The job will raise on API errors. For resilience:

```ruby
Article.unanalyzed.find_each do |article|
  begin
    AnalyzeArticleJob.perform_now(article.id)
  rescue Completions::Client::Error => e
    puts "Failed to analyze #{article.id}: #{e.message}"
  end
end
```
