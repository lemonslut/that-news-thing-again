# InfluxDB 3 instrumentation via influxdb-rails
# Uses v2 API compatibility layer for writes
InfluxDB::Rails.configure do |config|
  # InfluxDB 3 uses "database" but v2 API calls it "bucket"
  config.client.bucket = "rails_metrics"

  # InfluxDB 3 doesn't use org, but v2 API requires it - use any string
  config.client.org = "news-digest"

  # Token from credentials (create with: influxdb3 create token --admin)
  config.client.token = Rails.application.credentials.dig(:influxdb, :token)

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

  # Add environment tag to all metrics
  config.tags_middleware = lambda do |tags|
    tags.merge(env: Rails.env)
  end
end
