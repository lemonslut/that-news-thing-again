class TestFailureJob < ApplicationJob
  queue_as :default

  def perform
    raise "Intentional failure for metrics testing"
  end
end
