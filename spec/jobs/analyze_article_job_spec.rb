require "rails_helper"

RSpec.describe AnalyzeArticleJob do
  let(:article) do
    Article.create!(
      source_name: "BBC News",
      title: "Test headline",
      description: "Test description",
      url: "https://bbc.com/test-job",
      published_at: Time.current,
      content: "Article content"
    )
  end

  let(:analysis_result) do
    {
      "category" => "politics",
      "tags" => ["election", "senate"],
      "entities" => { "people" => [], "organizations" => [], "places" => [] },
      "political_lean" => "center",
      "calm_summary" => "A calm summary."
    }
  end

  before do
    allow_any_instance_of(Completions::Client).to receive(:analyze_article).and_return(analysis_result)
  end

  it "creates an ArticleAnalysis" do
    expect {
      described_class.new.perform(article.id)
    }.to change(ArticleAnalysis, :count).by(1)
  end

  it "stores the analysis data correctly" do
    described_class.new.perform(article.id)

    analysis = article.reload.analysis
    expect(analysis.category).to eq("politics")
    expect(analysis.tags).to eq(["election", "senate"])
    expect(analysis.calm_summary).to eq("A calm summary.")
    expect(analysis.model_used).to eq(Completions::Client::DEFAULT_MODEL)
  end

  it "skips if article already has analysis" do
    ArticleAnalysis.create!(
      article: article,
      category: "politics",
      tags: [],
      entities: {},
      calm_summary: "Existing",
      model_used: "test"
    )

    expect_any_instance_of(Completions::Client).not_to receive(:analyze_article)

    described_class.new.perform(article.id)
  end

  it "allows custom model" do
    expect(Completions::Client).to receive(:new)
      .with(model: "openai/gpt-4o")
      .and_call_original

    described_class.new.perform(article.id, model: "openai/gpt-4o")
  end

  it "handles nil values in response" do
    allow_any_instance_of(Completions::Client).to receive(:analyze_article).and_return({
      "category" => "other",
      "tags" => nil,
      "entities" => nil,
      "political_lean" => nil,
      "calm_summary" => "Something happened."
    })

    described_class.new.perform(article.id)

    analysis = article.reload.analysis
    expect(analysis.tags).to eq([])
    expect(analysis.entities).to eq({})
    expect(analysis.political_lean).to be_nil
  end
end
