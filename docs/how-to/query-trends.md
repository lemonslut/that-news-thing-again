# How to Query Trends

## Tag Frequency

Get the most common tags:

```ruby
ArticleAnalysis.tag_counts
# => [["election", 15], ["trump", 12], ["economy", 8], ...]
```

## Tags Over Time

Tags from the last 24 hours:

```ruby
ArticleAnalysis.tag_counts(since: 24.hours.ago)
```

Tags from the last week:

```ruby
ArticleAnalysis.tag_counts(since: 1.week.ago)
```

## Category Distribution

```ruby
ArticleAnalysis.category_counts
# => [["politics", 25], ["world", 18], ["technology", 12], ...]
```

With time filter:

```ruby
ArticleAnalysis.category_counts(since: 1.day.ago)
```

## Find Articles by Tag

```ruby
ArticleAnalysis.with_tag("election").each do |analysis|
  puts analysis.article.title
end
```

## Find Articles by Category

```ruby
ArticleAnalysis.by_category("technology").recent.limit(10).each do |analysis|
  puts analysis.calm_summary
end
```

## Political Lean Distribution

```ruby
ArticleAnalysis.group(:political_lean).count
# => {"center" => 10, "center-left" => 5, nil => 20, ...}
```

## Timeline Analysis

Articles mentioning a topic over time:

```ruby
# Daily counts for "election" tag
ArticleAnalysis.with_tag("election")
  .joins(:article)
  .group("DATE(articles.published_at)")
  .count
# => {Mon, 25 Nov => 3, Tue, 26 Nov => 7, ...}
```

## Entity Queries

Find articles mentioning a person:

```ruby
ArticleAnalysis.where("entities->'people' @> ?", '["Donald Trump"]'.to_json)
```

Find articles mentioning an organization:

```ruby
ArticleAnalysis.where("entities->'organizations' @> ?", '["Congress"]'.to_json)
```

## Combine Filters

```ruby
ArticleAnalysis
  .by_category("politics")
  .with_tag("election")
  .joins(:article)
  .where("articles.published_at > ?", 1.week.ago)
  .count
```

## Export for Analysis

```ruby
data = ArticleAnalysis.recent.limit(100).map do |a|
  {
    title: a.article.title,
    category: a.category,
    tags: a.tags,
    lean: a.political_lean,
    summary: a.calm_summary,
    published: a.article.published_at
  }
end

File.write("export.json", data.to_json)
```
