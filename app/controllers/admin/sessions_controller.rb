module Admin
  class SessionsController < BaseController
    def index
      sessions = Session.includes(:user).order(created_at: :desc)

      render_index(
        component: "Sessions/Index",
        records: sessions,
        serializer: method(:serialize_session)
      )
    end

    def destroy
      session_record = Session.find(params[:id])

      if session_record.id == Current.session&.id
        redirect_to admin_sessions_path, alert: "Cannot delete your current session"
        return
      end

      session_record.destroy
      redirect_to admin_sessions_path, notice: "Session deleted"
    end

    private

    def serialize_session(session)
      {
        id: session.id,
        user: {
          id: session.user.id,
          email_address: session.user.email_address,
          github_username: session.user.github_username
        },
        ip_address: session.ip_address,
        user_agent: session.user_agent&.truncate(50),
        created_at: session.created_at.iso8601
      }
    end
  end
end
