# InfluxDB 3 instrumentation via influxdb-rails
# Uses v2 API compatibility layer for writes

influxdb_token = Rails.application.credentials.dig(:influxdb, :token)

InfluxDB::Rails.configure do |config|
  # InfluxDB 3 uses "database" but v2 API calls it "bucket"
  config.client.bucket = "rails_metrics"

  # InfluxDB 3 doesn't use org, but v2 API requires it - use any string
  config.client.org = "news-digest"

  # Token from credentials (create with: influxdb3 create token --admin)
  config.client.token = influxdb_token

  # URL differs between environments (InfluxDB 3 uses port 8181)
  if Rails.env.production?
    config.client.url = "http://news-digest-influxdb:8181"
  else
    config.client.url = "http://localhost:8181"
  end

  # Use millisecond precision (default)
  config.client.precision = InfluxDB2::WritePrecision::MILLISECOND

  # Don't block on writes
  config.client.async = true

  # Need at least 1 retry for async writes
  config.client.max_retries = 3

  # Disable in environments without token configured
  if influxdb_token.blank?
    config.ignored_environments = [Rails.env]
  end

  # Add environment tag to all metrics
  config.tags_middleware = lambda do |tags|
    tags.merge(env: Rails.env)
  end
end
