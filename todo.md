# TODO

## Story Clustering
- [ ] Show common subjects on story display page (the subjects articles share)
- [ ] Require at least 2 subjects in common AND 50% overlap for clustering
- [ ] Investigate: embeddings on factual summaries for clustering (vs subject overlap)
- [ ] Add "verb/action" concept type (dies, wins, indicted, pays tribute, etc.)
  - Subject + verb together captures the actual story (e.g. "Rob Reiner" + "dies" vs "pays tribute")

## Source Quality
- [ ] Add up-vote/down-vote for sources (source_name, source_id from NewsAPI)
- [ ] Track bad:good ratio per source
- [ ] Skip processing for low-quality sources (save LLM costs)

## Article Detail Page
- [ ] Edit & save summaries in-place
- [ ] Regenerate buttons for all derivatives (summaries, NER, sentiment)
- [ ] Store full messages array for LLM completions (system, user, response)
- [ ] Regenerate with feedback: append user notes to conversation and re-run

## Pipeline Improvements
- [ ] Minimum content length check before generating summaries
- [x] Remove calm summaries - consolidate to factual summaries only
- [ ] Duplicate article detection (AP syndicated articles showing up multiple times)
- [ ] UI to collapse/group duplicates together
