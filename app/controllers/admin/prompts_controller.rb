module Admin
  class PromptsController < BaseController
    def index
      prompts = Prompt.order(name: :asc, version: :desc)
      prompts = prompts.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

      render_index(
        component: "Prompts/Index",
        records: prompts,
        serializer: method(:serialize_prompt)
      )
    end

    def show
      prompt = Prompt.find(params[:id])

      render inertia: "Prompts/Show", props: {
        prompt: serialize_prompt_detail(prompt)
      }
    end

    def new
      render inertia: "Prompts/Form", props: {
        prompt: nil
      }
    end

    def create
      prompt = Prompt.new(prompt_params)

      if prompt.save
        redirect_to admin_prompt_path(prompt), notice: "Prompt created"
      else
        redirect_to new_admin_prompt_path, alert: prompt.errors.full_messages.join(", ")
      end
    end

    def edit
      prompt = Prompt.find(params[:id])

      render inertia: "Prompts/Form", props: {
        prompt: serialize_prompt(prompt)
      }
    end

    def update
      prompt = Prompt.find(params[:id])

      if prompt.update(prompt_params)
        redirect_to admin_prompt_path(prompt), notice: "Prompt updated"
      else
        redirect_to edit_admin_prompt_path(prompt), alert: prompt.errors.full_messages.join(", ")
      end
    end

    def destroy
      Prompt.find(params[:id]).destroy
      redirect_to admin_prompts_path, notice: "Prompt deleted"
    end

    def activate
      prompt = Prompt.find(params[:id])

      Prompt.where(name: prompt.name).update_all(active: false)
      prompt.update!(active: true)

      redirect_to admin_prompt_path(prompt), notice: "Prompt activated"
    end

    private

    def prompt_params
      params.require(:prompt).permit(:name, :body, :version, :active)
    end

    def serialize_prompt(prompt)
      {
        id: prompt.id,
        name: prompt.name,
        version: prompt.version,
        active: prompt.active,
        created_at: prompt.created_at.iso8601
      }
    end

    def serialize_prompt_detail(prompt)
      serialize_prompt(prompt).merge(
        body: prompt.body
      )
    end
  end
end
