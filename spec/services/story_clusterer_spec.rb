require "rails_helper"

RSpec.describe StoryClusterer do
  # Helper to create an article with concepts
  def create_article_with_concepts(concepts:, published_at: Time.current)
    article = Article.create!(
      source_name: "Test Source",
      title: "Test Article #{rand(1000)}",
      url: "https://example.com/#{SecureRandom.hex(8)}",
      published_at: published_at
    )
    concepts.each do |concept|
      article.article_concepts.create!(concept: concept, score: 1)
    end
    article
  end

  describe "#call" do
    let!(:person1) { Concept.create!(uri: "llm://person/john-doe", concept_type: "person", label: "John Doe") }
    let!(:person2) { Concept.create!(uri: "llm://person/jane-smith", concept_type: "person", label: "Jane Smith") }
    let!(:org1) { Concept.create!(uri: "llm://org/acme-corp", concept_type: "org", label: "Acme Corp") }
    let!(:org2) { Concept.create!(uri: "llm://org/globex", concept_type: "org", label: "Globex") }
    let!(:loc1) { Concept.create!(uri: "llm://loc/new-york", concept_type: "loc", label: "New York") }

    it "creates a story from two articles with 50%+ concept overlap" do
      article1 = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: 1.hour.ago
      )
      article2 = create_article_with_concepts(
        concepts: [person1, org2],
        published_at: Time.current
      )

      expect { described_class.new(article2).call }.to change(Story, :count).by(1)

      story = Story.last
      expect(story.articles).to contain_exactly(article1, article2)
      expect(story.title).to eq(article1.title) # earliest article's title
    end

    it "does not cluster articles below 50% overlap" do
      article1 = create_article_with_concepts(
        concepts: [person1, org1, loc1],
        published_at: 1.hour.ago
      )
      article2 = create_article_with_concepts(
        concepts: [person2, org2, loc1], # only loc1 shared = 33%
        published_at: Time.current
      )

      expect { described_class.new(article2).call }.not_to change(Story, :count)
      expect(article1.reload.story_id).to be_nil
      expect(article2.reload.story_id).to be_nil
    end

    it "adds article to existing story with matching concepts" do
      article1 = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: 2.hours.ago
      )
      article2 = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: 1.hour.ago
      )

      # Create initial story
      described_class.new(article2).call
      story = Story.last
      expect(story.articles.count).to eq(2)

      # New article with matching concepts
      article3 = create_article_with_concepts(
        concepts: [person1, org1, loc1],
        published_at: Time.current
      )

      expect { described_class.new(article3).call }.not_to change(Story, :count)
      expect(article3.reload.story).to eq(story)
      expect(story.reload.articles.count).to eq(3)
    end

    it "ignores articles older than 7 days when looking for matches" do
      old_article = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: 8.days.ago
      )
      recent_article = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: Time.current
      )

      result = described_class.new(recent_article).call

      expect(result).to be false
      expect(old_article.reload.story_id).to be_nil
      expect(recent_article.reload.story_id).to be_nil
    end

    it "returns false for articles without concepts" do
      article = Article.create!(
        source_name: "Test",
        title: "No concepts",
        url: "https://example.com/no-concepts",
        published_at: Time.current
      )

      expect(described_class.new(article).call).to be false
    end

    it "returns false if article already has a story" do
      story = Story.create!(title: "Existing story")
      article = create_article_with_concepts(concepts: [person1, org1], published_at: Time.current)
      article.update!(story: story)

      expect(described_class.new(article).call).to be false
    end

    it "returns true when article is clustered" do
      article1 = create_article_with_concepts(concepts: [person1, org1], published_at: 1.hour.ago)
      article2 = create_article_with_concepts(concepts: [person1, org1], published_at: Time.current)

      expect(described_class.new(article2).call).to be true
      expect(Story.count).to eq(1)
      expect(Story.last.articles.count).to eq(2)
    end
  end

  describe "overlap calculation" do
    let!(:c1) { Concept.create!(uri: "llm://1", concept_type: "person", label: "C1") }
    let!(:c2) { Concept.create!(uri: "llm://2", concept_type: "person", label: "C2") }
    let!(:c3) { Concept.create!(uri: "llm://3", concept_type: "person", label: "C3") }
    let!(:c4) { Concept.create!(uri: "llm://4", concept_type: "person", label: "C4") }

    it "clusters at exactly 50% overlap" do
      # Article with 2 concepts, one shared = 50%
      article1 = create_article_with_concepts(concepts: [c1, c2], published_at: 1.hour.ago)
      article2 = create_article_with_concepts(concepts: [c1, c3], published_at: Time.current)

      described_class.new(article2).call
      expect(article1.reload.story_id).to eq(article2.reload.story_id)
    end

    it "uses smaller set for ratio calculation" do
      # Article1 has 4 concepts, Article2 has 2
      # 2 shared = 100% of smaller set
      article1 = create_article_with_concepts(concepts: [c1, c2, c3, c4], published_at: 1.hour.ago)
      article2 = create_article_with_concepts(concepts: [c1, c2], published_at: Time.current)

      described_class.new(article2).call
      expect(article1.reload.story_id).to eq(article2.reload.story_id)
    end
  end
end
