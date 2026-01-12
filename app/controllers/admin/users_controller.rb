module Admin
  class UsersController < BaseController
    def index
      users = User.order(:created_at)
      users = users.where("email_address ILIKE ? OR github_username ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?

      render_index(
        component: "Users/Index",
        records: users,
        serializer: method(:serialize_user)
      )
    end

    def show
      user = User.find(params[:id])

      render inertia: "Users/Show", props: {
        user: serialize_user_detail(user)
      }
    end

    def edit
      user = User.find(params[:id])

      render inertia: "Users/Form", props: {
        user: serialize_user(user)
      }
    end

    def update
      user = User.find(params[:id])

      if user.update(user_params)
        redirect_to admin_user_path(user), notice: "User updated"
      else
        redirect_to edit_admin_user_path(user), alert: user.errors.full_messages.join(", ")
      end
    end

    def destroy
      user = User.find(params[:id])

      if user.id == current_user.id
        redirect_to admin_users_path, alert: "Cannot delete yourself"
        return
      end

      user.destroy
      redirect_to admin_users_path, notice: "User deleted"
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :allowed)
    end

    def serialize_user(user)
      {
        id: user.id,
        email_address: user.email_address,
        github_username: user.github_username,
        avatar_url: user.avatar_url,
        provider: user.provider,
        allowed: user.allowed,
        created_at: user.created_at.iso8601
      }
    end

    def serialize_user_detail(user)
      serialize_user(user).merge(
        api_token: user.api_token,
        sessions_count: user.sessions.count
      )
    end
  end
end
