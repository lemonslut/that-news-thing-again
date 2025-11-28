# Design Decisions

## Why PostgreSQL with JSONB?

**Decision:** Use PostgreSQL with JSONB columns for raw payloads instead of a dedicated document store.

**Rationale:**
- One less service to manage
- JSONB is genuinely good for document storage
- We already need Postgres for structured data
- GIN indexes make tag queries fast
- Can query JSONB with SQL when needed
- Easy to extract columns later if patterns emerge

**Trade-offs:**
- JSONB can cause issues at very high write volume with GIN indexes
- Not as flexible as a true document store for schema-less data

**When to revisit:** If write volume exceeds thousands of articles per hour, or if JSONB queries become a bottleneck.

---

## Why Separate Article and ArticleAnalysis?

**Decision:** Keep Article as the pristine source data, store LLM analysis in a separate table.

**Rationale:**
- Clean separation of concerns (source data vs derived data)
- Can re-run analysis with different models/prompts
- Migrations are cheap, can add columns to analysis freely
- Don't pollute source records with derived fields

**Trade-offs:**
- Extra join for queries that need both
- Slightly more complex data model

---

## Why OpenRouter Instead of Direct OpenAI/Anthropic?

**Decision:** Use OpenRouter as an LLM proxy instead of calling providers directly.

**Rationale:**
- Single API, multiple models
- Easy to switch models without code changes
- OpenAI-compatible API means standard tooling works
- No vendor lock-in
- Can optimize cost/quality per use case

**Trade-offs:**
- Additional service dependency
- Slightly higher latency (extra hop)
- OpenRouter's availability becomes a dependency

---

## Why Claude Haiku as Default?

**Decision:** Default to `anthropic/claude-3-haiku` for article analysis.

**Rationale:**
- Fast (low latency)
- Cheap (good for batch processing)
- Good enough for categorization and summarization
- Can upgrade to Sonnet/Opus for quality-critical uses

**Trade-offs:**
- Less capable than larger models
- May miss nuance in complex articles

---

## Why Sidekiq?

**Decision:** Use Sidekiq for background jobs instead of Solid Queue.

**Rationale:**
- Battle-tested at scale
- Redis is already needed, lightweight
- Good monitoring (Sidekiq Web)
- Easy worker scaling

**Trade-offs:**
- Requires Redis (Solid Queue uses the database)
- Another service to manage

**Alternative considered:** Solid Queue (Rails 8 default) — would eliminate Redis dependency but less proven at scale.

---

## Why Store Raw Payloads?

**Decision:** Store the complete NewsAPI response in `raw_payload` JSONB column.

**Rationale:**
- Audit trail (what did we actually receive?)
- Future-proofing (can extract new fields later)
- Debugging (compare raw vs processed)
- No data loss

**Trade-offs:**
- Storage overhead (mitigated: articles are small)
- JSONB overhead

---

## Why "Calm Summary" Format?

**Decision:** Generate short, whispered-style summaries instead of traditional article summaries.

**Rationale:**
- Project goal: reduce news anxiety
- Short format forces focus on "what happened"
- Present tense feels immediate but calm
- No sensationalism by design (enforced by prompt)

**Trade-offs:**
- Loses detail and nuance
- May oversimplify complex stories

---

## Why Tags as Array Instead of Join Table?

**Decision:** Store tags as a JSONB array on ArticleAnalysis instead of a separate tags table with join.

**Rationale:**
- Simpler schema
- GIN index makes array queries fast
- Tags are generated, not user-managed
- No need for tag metadata

**Trade-offs:**
- Can't easily query "all articles for tag X" with eager loading
- No tag normalization (LLM might generate "election" and "elections")

**When to revisit:** If tag normalization becomes important, or if we need tag metadata (descriptions, hierarchies).

---

## Why No Frontend Yet?

**Decision:** Build the data pipeline first, skip the web UI.

**Rationale:**
- Prove the concept before investing in UI
- CLI/runner interface sufficient for exploration
- Can add API endpoints when needed
- Avoid premature abstraction

**Next step:** Add JSON API for querying articles and trends when ready to build a frontend or integrate with other tools.
