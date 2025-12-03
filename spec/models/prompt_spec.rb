require "rails_helper"

RSpec.describe Prompt do
  describe "validations" do
    it "requires name" do
      prompt = Prompt.new(body: "body", version: 1)
      expect(prompt).not_to be_valid
      expect(prompt.errors[:name]).to include("can't be blank")
    end

    it "requires body" do
      prompt = Prompt.new(name: "test", version: 1)
      expect(prompt).not_to be_valid
      expect(prompt.errors[:body]).to include("can't be blank")
    end

    it "requires version" do
      prompt = Prompt.new(name: "test", body: "body", version: nil)
      expect(prompt).not_to be_valid
      expect(prompt.errors[:version]).to include("can't be blank")
    end

    it "requires unique name+version combo" do
      Prompt.create!(name: "test", body: "body", version: 1)
      dupe = Prompt.new(name: "test", body: "other", version: 1)

      expect(dupe).not_to be_valid
      expect(dupe.errors[:version]).to include("has already been taken")
    end
  end

  describe ".current" do
    it "returns the active prompt for a name" do
      Prompt.create!(name: "test", body: "v1", version: 1, active: false)
      active = Prompt.create!(name: "test", body: "v2", version: 2, active: true)

      expect(Prompt.current("test")).to eq(active)
    end

    it "raises if no active prompt" do
      Prompt.create!(name: "test", body: "v1", version: 1, active: false)

      expect { Prompt.current("test") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#activate!" do
    it "deactivates other versions and activates self" do
      v1 = Prompt.create!(name: "test", body: "v1", version: 1, active: true)
      v2 = Prompt.create!(name: "test", body: "v2", version: 2, active: false)

      v2.activate!

      expect(v1.reload.active).to be false
      expect(v2.reload.active).to be true
    end
  end
end
