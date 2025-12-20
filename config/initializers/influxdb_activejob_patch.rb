# Patch influxdb-rails to correctly detect failed ActiveJob jobs
# The gem checks payload[:aborted] but ActiveJob uses payload[:exception]

module InfluxDB
  module Rails
    module Middleware
      class ActiveJobSubscriber < Subscriber
        private

        def failed?
          payload[:exception].present? || payload[:aborted]
        end

        def tags
          base_tags = {
            hook:  short_hook_name,
            state: job_state,
            job:   job.class.name,
            queue: job.queue_name,
          }

          # Add exception class if failed
          if failed? && payload[:exception]
            base_tags[:class_name] = payload[:exception].first
          end

          base_tags
        end
      end
    end
  end
end
