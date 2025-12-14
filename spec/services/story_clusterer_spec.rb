require "rails_helper"

RSpec.describe StoryClusterer do
  def create_article(attrs = {})
    defaults = {
      title: "Test Article #{SecureRandom.hex(4)}",
      url: "https://example.com/#{SecureRandom.hex(8)}",
      source_name: "Test Source",
      published_at: Time.current
    }
    Article.create!(defaults.merge(attrs))
  end

  def create_concept(attrs = {})
    defaults = {
      uri: "http://wiki/#{SecureRandom.hex(4)}",
      concept_type: "wiki",
      label: "Test Concept"
    }
    Concept.create!(defaults.merge(attrs))
  end

  def create_story(attrs = {})
    defaults = { title: "Test Story #{SecureRandom.hex(4)}" }
    Story.create!(defaults.merge(attrs))
  end

  describe "#cluster_by_event_uri" do
    it "creates stories from articles with the same event_uri" do
      create_article(event_uri: "event-123", title: "First Article")
      create_article(event_uri: "event-123", title: "Second Article")
      create_article(event_uri: "event-456", title: "Third Article")

      expect { described_class.new.cluster_by_event_uri }.to change(Story, :count).by(2)

      story = Story.find_by(event_uri: "event-123")
      expect(story.articles.count).to eq(2)
      expect(story.articles_count).to eq(2)
    end

    it "adds articles to existing stories" do
      story = create_story(event_uri: "event-123")
      article = create_article(event_uri: "event-123", story: nil)

      described_class.new.cluster_by_event_uri

      expect(article.reload.story).to eq(story)
    end

    it "updates story timestamps" do
      create_article(event_uri: "event-123", published_at: 2.days.ago)
      create_article(event_uri: "event-123", published_at: 1.day.ago)

      described_class.new.cluster_by_event_uri

      story = Story.find_by(event_uri: "event-123")
      expect(story.first_published_at).to be_within(1.second).of(2.days.ago)
      expect(story.last_published_at).to be_within(1.second).of(1.day.ago)
    end
  end

end
