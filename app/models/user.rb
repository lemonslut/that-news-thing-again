class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_create :generate_api_token

  def regenerate_api_token!
    update!(api_token: self.class.generate_token)
  end

  def self.find_by_api_token(token)
    return nil if token.blank?

    find_by(api_token: token)
  end

  def self.generate_token
    SecureRandom.hex(32)
  end

  private

  def generate_api_token
    self.api_token ||= self.class.generate_token
  end
end
