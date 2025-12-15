require "rails_helper"

RSpec.describe StoryClusterer do
  let(:clusterer) { described_class.new }

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

      expect { clusterer.call }.to change(Story, :count).by(1)

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

      expect { clusterer.call }.not_to change(Story, :count)
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
      clusterer.call
      story = Story.last
      expect(story.articles.count).to eq(2)

      # New article with matching concepts
      article3 = create_article_with_concepts(
        concepts: [person1, org1, loc1],
        published_at: Time.current
      )

      expect { described_class.new.call }.not_to change(Story, :count)
      expect(article3.reload.story).to eq(story)
      expect(story.reload.articles.count).to eq(3)
    end

    it "ignores articles older than 7 days" do
      old_article = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: 8.days.ago
      )
      recent_article = create_article_with_concepts(
        concepts: [person1, org1],
        published_at: Time.current
      )

      clusterer.call

      expect(old_article.reload.story_id).to be_nil
      expect(recent_article.reload.story_id).to be_nil # no match found
    end

    it "ignores articles without concepts" do
      Article.create!(
        source_name: "Test",
        title: "No concepts",
        url: "https://example.com/no-concepts",
        published_at: Time.current
      )

      expect { clusterer.call }.not_to change(Story, :count)
    end

    it "returns count of clustered articles" do
      create_article_with_concepts(concepts: [person1, org1], published_at: 1.hour.ago)
      create_article_with_concepts(concepts: [person1, org1], published_at: Time.current)

      # Returns 1 because only the newer article "finds" a match
      # (the older article gets added as part of story creation)
      result = clusterer.call
      expect(result).to eq(1)
      expect(Story.count).to eq(1)
      expect(Story.last.articles.count).to eq(2)
    end
  end

  describe "#cluster_article" do
    let!(:concept1) { Concept.create!(uri: "llm://person/test", concept_type: "person", label: "Test") }
    let!(:concept2) { Concept.create!(uri: "llm://org/test", concept_type: "org", label: "Test Org") }

    it "returns true when article is clustered" do
      article1 = create_article_with_concepts(concepts: [concept1, concept2], published_at: 1.hour.ago)
      article2 = create_article_with_concepts(concepts: [concept1, concept2], published_at: Time.current)

      # article1 has no match yet
      expect(clusterer.cluster_article(article1)).to be false

      # article2 should match article1
      expect(clusterer.cluster_article(article2)).to be true
    end

    it "returns false for article without concepts" do
      article = Article.create!(
        source_name: "Test",
        title: "Test",
        url: "https://example.com/test",
        published_at: Time.current
      )

      expect(clusterer.cluster_article(article)).to be false
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

      clusterer.call
      expect(article1.reload.story_id).to eq(article2.reload.story_id)
    end

    it "uses smaller set for ratio calculation" do
      # Article1 has 4 concepts, Article2 has 2
      # 2 shared = 100% of smaller set
      article1 = create_article_with_concepts(concepts: [c1, c2, c3, c4], published_at: 1.hour.ago)
      article2 = create_article_with_concepts(concepts: [c1, c2], published_at: Time.current)

      clusterer.call
      expect(article1.reload.story_id).to eq(article2.reload.story_id)
    end
  end
end
