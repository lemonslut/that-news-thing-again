module Completions
  class Client
    DEFAULT_MODEL = "openai/gpt-oss-120b".freeze

    Error = Class.new(StandardError)

    def initialize(model: nil)
      @model = model || DEFAULT_MODEL
      @client = OpenAI::Client.new
    end

    def complete(messages, json: false)
      params = {
        model: @model,
        messages: normalize_messages(messages)
      }

      response = @client.chat(parameters: params)

      if response["error"]
        raise Error, response["error"]["message"]
      end

      content = response.dig("choices", 0, "message", "content")
      json ? extract_json(content) : content
    end

    private

    attr_reader :model, :client

    def normalize_messages(messages)
      messages.map do |msg|
        case msg
        when Hash then msg.transform_keys(&:to_s)
        when String then { "role" => "user", "content" => msg }
        else raise ArgumentError, "Invalid message format"
        end
      end
    end

    def extract_json(content)
      JSON.parse(content)
    rescue JSON::ParserError
      if content =~ /```(?:json)?\s*(\{.*?\})\s*```/m
        JSON.parse($1)
      elsif content =~ /(\{.*\})/m
        JSON.parse($1)
      else
        raise Error, "Could not extract JSON from response: #{content[0..100]}"
      end
    end
  end
end
