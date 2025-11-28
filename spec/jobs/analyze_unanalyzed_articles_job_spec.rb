require "rails_helper"

RSpec.describe AnalyzeUnanalyzedArticlesJob do
  let!(:unanalyzed_article) do
    Article.create!(
      source_name: "BBC News",
      title: "No analysis",
      description: "Test",
      url: "https://bbc.com/unanalyzed",
      published_at: Time.current
    )
  end

  let!(:analyzed_article) do
    article = Article.create!(
      source_name: "CNN",
      title: "Has analysis",
      description: "Test",
      url: "https://cnn.com/analyzed",
      published_at: Time.current
    )
    ArticleAnalysis.create!(
      article: article,
      category: "politics",
      tags: [],
      entities: {},
      calm_summary: "Already done",
      model_used: "test"
    )
    article
  end

  it "enqueues AnalyzeArticleJob for unanalyzed articles" do
    expect {
      described_class.new.perform
    }.to have_enqueued_job(AnalyzeArticleJob).with(unanalyzed_article.id)
  end

  it "does not enqueue for already analyzed articles" do
    expect {
      described_class.new.perform
    }.not_to have_enqueued_job(AnalyzeArticleJob).with(analyzed_article.id)
  end

  it "respects the limit parameter" do
    3.times do |i|
      Article.create!(
        source_name: "Test",
        title: "Article #{i}",
        url: "https://test.com/#{i}",
        published_at: Time.current
      )
    end

    result = described_class.new.perform(limit: 2)
    expect(result[:enqueued]).to eq(2)
  end
end
