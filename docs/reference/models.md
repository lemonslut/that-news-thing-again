# Models Reference

## Article

Stores articles fetched from NewsAPI.

### Schema

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| id | bigint | no | Primary key |
| source_id | string | yes | NewsAPI source identifier |
| source_name | string | no | Source display name |
| author | string | yes | Article author |
| title | string | no | Article headline |
| description | text | yes | Short description |
| url | string | no | Original article URL (unique) |
| image_url | string | yes | Featured image URL |
| published_at | datetime | no | Publication timestamp |
| content | text | yes | Truncated content (200 chars from NewsAPI) |
| raw_payload | jsonb | no | Complete NewsAPI response |
| created_at | datetime | no | Record creation time |
| updated_at | datetime | no | Record update time |

### Associations

- `has_one :analysis` — ArticleAnalysis

### Scopes

- `recent` — Order by published_at DESC
- `from_source(name)` — Filter by source_name
- `published_after(time)` — Articles after timestamp
- `published_before(time)` — Articles before timestamp
- `analyzed` — Articles with analysis
- `unanalyzed` — Articles without analysis

### Class Methods

- `from_news_api(hash)` — Build Article from NewsAPI response hash
- `upsert_from_news_api(hash)` — Create or update by URL

---

## ArticleAnalysis

Stores LLM-generated analysis for articles.

### Schema

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| id | bigint | no | Primary key |
| article_id | bigint | no | Foreign key to articles |
| category | string | no | Article category |
| tags | jsonb | no | Array of lowercase tags |
| entities | jsonb | no | Extracted entities object |
| political_lean | string | yes | Political lean assessment |
| calm_summary | text | no | Whispered-style summary |
| model_used | string | no | LLM model identifier |
| raw_response | jsonb | no | Complete LLM response |
| created_at | datetime | no | Record creation time |
| updated_at | datetime | no | Record update time |

### Constants

```ruby
CATEGORIES = %w[
  politics business technology health science
  entertainment sports world environment other
]

POLITICAL_LEANS = %w[left center-left center center-right right]
```

### Associations

- `belongs_to :article`

### Scopes

- `by_category(cat)` — Filter by category
- `with_tag(tag)` — Filter by tag (uses GIN index)
- `leaning(lean)` — Filter by political_lean
- `recent` — Order by article.published_at DESC

### Class Methods

- `tag_counts(since: nil)` — Returns array of [tag, count] sorted by frequency
- `category_counts(since: nil)` — Returns array of [category, count] sorted by frequency

### Entities Structure

```json
{
  "people": ["John Smith", "Jane Doe"],
  "organizations": ["Congress", "FBI"],
  "places": ["Washington DC", "New York"]
}
```
