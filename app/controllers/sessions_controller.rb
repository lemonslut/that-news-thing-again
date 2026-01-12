class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }

  def new
    render inertia: "Auth/Login"
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "Signed in successfully"
    else
      redirect_to login_path, alert: "Invalid email or password"
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, notice: "Signed out"
  end
end
