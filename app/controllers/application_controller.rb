class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Inertia shared data - available to all components
  inertia_share do
    {
      auth: {
        user: current_user&.as_json(only: [:id, :email_address, :github_username, :avatar_url, :allowed]),
        authenticated: current_user.present?
      },
      flash: {
        notice: flash[:notice],
        alert: flash[:alert]
      }
    }
  end
end
