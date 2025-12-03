class Prompt < ApplicationRecord
  has_many :article_entity_extractions, dependent: :nullify
  has_many :article_calm_summaries, dependent: :nullify

  validates :name, presence: true
  validates :body, presence: true
  validates :version, presence: true, uniqueness: { scope: :name }

  scope :active, -> { where(active: true) }

  def self.current(name)
    active.find_by!(name: name)
  end

  def activate!
    transaction do
      Prompt.where(name: name).update_all(active: false)
      update!(active: true)
    end
  end

  def to_s
    "#{name} v#{version}"
  end
end
