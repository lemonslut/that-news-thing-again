class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 8 },
            if: -> { provider == "email" && password_digest_changed? }
  validates :github_uid, uniqueness: true, allow_nil: true

  before_create :generate_api_token

  scope :allowed, -> { where(allowed: true) }

  def self.from_omniauth(auth)
    user = find_by(github_uid: auth.uid) || find_by(email_address: auth.info.email&.downcase)

    if user
      # Update existing user with GitHub info
      user.update!(
        github_uid: auth.uid,
        github_username: auth.info.nickname,
        avatar_url: auth.info.image,
        provider: "github"
      )
    else
      # Create new user (not allowed by default)
      user = create!(
        github_uid: auth.uid,
        github_username: auth.info.nickname,
        email_address: auth.info.email,
        avatar_url: auth.info.image,
        provider: "github",
        allowed: false
      )
    end

    user
  end

  def oauth_user?
    provider == "github"
  end

  def allowed?
    allowed
  end

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
