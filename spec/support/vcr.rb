require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out API keys from recordings
  config.filter_sensitive_data("<NEWS_API_KEY>") { Rails.application.credentials.dig(:news_api, :key) }

  # Allow real connections when recording
  config.allow_http_connections_when_no_cassette = false

  # Match requests on method and URI
  config.default_cassette_options = {
    match_requests_on: [ :method, :uri ],
    record: :new_episodes
  }
end
