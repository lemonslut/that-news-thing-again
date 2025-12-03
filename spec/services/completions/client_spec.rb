require "rails_helper"

RSpec.describe Completions::Client do
  let(:client) { described_class.new }

  let(:analysis_response) do
    {
      "category" => "politics",
      "tags" => [ "election", "senate", "voting" ],
      "entities" => {
        "people" => [ "John Smith" ],
        "organizations" => [ "Congress" ],
        "places" => [ "Washington DC" ]
      },
      "political_lean" => "center",
      "calm_summary" => "Congress is debating new election legislation."
    }
  end

  let(:openai_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => analysis_response.to_json
          }
        }
      ]
    }
  end

  before do
    allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(openai_response)
  end

  describe "#complete" do
    it "sends messages to OpenRouter and returns content" do
      result = client.complete([ { role: "user", content: "Hello" } ])

      expect(result).to eq(analysis_response.to_json)
    end

    it "parses JSON when json: true" do
      result = client.complete([ { role: "user", content: "Hello" } ], json: true)

      expect(result).to eq(analysis_response)
    end

    it "raises error on API error" do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return({
        "error" => { "message" => "Rate limit exceeded" }
      })

      expect { client.complete([ "test" ]) }.to raise_error(Completions::Client::Error, "Rate limit exceeded")
    end
  end

  describe "model selection" do
    it "uses default model" do
      expect(described_class::DEFAULT_MODEL).to eq("anthropic/claude-3-haiku")
    end

    it "allows custom model" do
      client = described_class.new(model: "openai/gpt-4o-mini")

      expect_any_instance_of(OpenAI::Client).to receive(:chat).with(
        hash_including(parameters: hash_including(model: "openai/gpt-4o-mini"))
      ).and_return(openai_response)

      client.complete([ "test" ])
    end
  end
end
