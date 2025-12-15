require "rails_helper"

RSpec.describe StoryClusterer do
  describe "#call" do
    it "logs that clustering is disabled" do
      expect(Rails.logger).to receive(:info).with("[StoryClusterer] Clustering disabled - no implementation")
      described_class.new.call
    end
  end
end
