require "rails_helper"

RSpec.describe Story do
  def create_article(attrs = {})
    defaults = {
      title: "Test Article #{SecureRandom.hex(4)}",
      url: "https://example.com/#{SecureRandom.hex(8)}",
      source_name: "Test Source",
      published_at: Time.current
    }
    Article.create!(defaults.merge(attrs))
  end

  def create_story(attrs = {})
    defaults = { title: "Test Story #{SecureRandom.hex(4)}" }
    Story.create!(defaults.merge(attrs))
  end

  describe "validations" do
    it "requires title" do
      story = Story.new(title: nil)
      expect(story).not_to be_valid
      expect(story.errors[:title]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "has many articles" do
      story = create_story
      article = create_article(story: story)

      expect(story.articles).to include(article)
    end

    it "nullifies articles on destroy" do
      story = create_story
      article = create_article(story: story)

      story.destroy

      expect(article.reload.story_id).to be_nil
    end
  end

  describe "#update_timestamps!" do
    it "sets first and last published times from articles" do
      story = create_story
      create_article(story: story, published_at: 3.days.ago)
      create_article(story: story, published_at: 1.day.ago)

      story.update_timestamps!

      expect(story.first_published_at).to be_within(1.second).of(3.days.ago)
      expect(story.last_published_at).to be_within(1.second).of(1.day.ago)
    end

    it "handles no articles gracefully" do
      story = create_story

      expect { story.update_timestamps! }.not_to raise_error
    end
  end

  describe "#duration" do
    it "returns nil when timestamps missing" do
      story = Story.new(title: "Test", first_published_at: nil, last_published_at: nil)
      expect(story.duration).to be_nil
    end

    it "returns duration in seconds" do
      story = Story.new(title: "Test", first_published_at: 2.days.ago, last_published_at: Time.current)
      expect(story.duration).to be_within(1).of(2.days.to_i)
    end
  end

  describe "#sources" do
    it "returns unique source names" do
      story = create_story
      create_article(story: story, source_name: "CNN")
      create_article(story: story, source_name: "BBC")
      create_article(story: story, source_name: "CNN")

      expect(story.sources).to contain_exactly("CNN", "BBC")
    end
  end

  describe "scopes" do
    describe ".multi_source" do
      it "returns stories with more than one article" do
        multi = create_story(articles_count: 3)
        single = create_story(articles_count: 1)

        expect(described_class.multi_source).to include(multi)
        expect(described_class.multi_source).not_to include(single)
      end
    end

    describe ".active" do
      it "returns stories updated in the last 7 days" do
        active = create_story(last_published_at: 2.days.ago)
        stale = create_story(last_published_at: 10.days.ago)

        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(stale)
      end
    end
  end
end
