module Completions
  class Client
    DEFAULT_MODEL = "anthropic/claude-3-haiku".freeze

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

    def analyze_article(article)
      complete([
        { role: "system", content: system_prompt },
        { role: "user", content: article_prompt(article) }
      ], json: true)
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
      # Try direct parse first
      JSON.parse(content)
    rescue JSON::ParserError
      # Extract JSON from markdown code blocks or surrounding text
      if content =~ /```(?:json)?\s*(\{.*?\})\s*```/m
        JSON.parse($1)
      elsif content =~ /(\{.*\})/m
        JSON.parse($1)
      else
        raise Error, "Could not extract JSON from response: #{content[0..100]}"
      end
    end

    def system_prompt
      <<~PROMPT
        You are a calm, measured news analyst. Your job is to categorize and summarize news articles.

        IMPORTANT: Respond with ONLY valid JSON. No preamble, no explanation, just the JSON object.

        The JSON must contain:
        - category: One of [politics, business, technology, health, science, entertainment, sports, world, environment, other]
        - tags: Array of 3-5 lowercase tags for trend tracking (e.g., ["election", "senate", "voting-rights"])
        - entities: Object with arrays for "people", "organizations", and "places" mentioned
        - political_lean: One of [left, center-left, center, center-right, right, null] - only if clearly detectable, otherwise null
        - calm_summary: A single calm, simple sentence describing what happened. No sensationalism. Present tense. Like you're whispering the news to a friend. Max 20 words.

        Example calm_summary: "A fire in Hong Kong has killed several people and rescue efforts continue."
      PROMPT
    end

    def article_prompt(article)
      <<~PROMPT
        Analyze this article:

        Source: #{article.source_name}
        Title: #{article.title}
        Description: #{article.description}
        Content: #{article.content}
        Published: #{article.published_at}
      PROMPT
    end
  end
end
