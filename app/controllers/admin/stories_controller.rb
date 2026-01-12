module Admin
  class StoriesController < BaseController
    def index
      stories = Story.recent.order(articles_count: :desc)
      stories = stories.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?

      render_index(
        component: "Stories/Index",
        records: stories,
        serializer: method(:serialize_story)
      )
    end

    def show
      story = Story.includes(:articles).find(params[:id])

      render inertia: "Stories/Show", props: {
        story: serialize_story_detail(story)
      }
    end

    def edit
      story = Story.find(params[:id])

      render inertia: "Stories/Form", props: {
        story: serialize_story(story)
      }
    end

    def update
      story = Story.find(params[:id])

      if story.update(story_params)
        redirect_to admin_story_path(story), notice: "Story updated"
      else
        redirect_to edit_admin_story_path(story), alert: story.errors.full_messages.join(", ")
      end
    end

    def destroy
      Story.find(params[:id]).destroy
      redirect_to admin_stories_path, notice: "Story deleted"
    end

    private

    def story_params
      params.require(:story).permit(:title)
    end

    def serialize_story(story)
      {
        id: story.id,
        title: story.title,
        articles_count: story.articles_count,
        first_published_at: story.first_published_at&.iso8601,
        last_published_at: story.last_published_at&.iso8601
      }
    end

    def serialize_story_detail(story)
      serialize_story(story).merge(
        articles: story.articles.recent.limit(20).map do |a|
          {
            id: a.id,
            title: a.title,
            source_name: a.source_name,
            published_at: a.published_at&.iso8601
          }
        end
      )
    end
  end
end
