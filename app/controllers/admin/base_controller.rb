module Admin
  class BaseController < ApplicationController
    include Pagy::Backend

    protected

    def pagy_metadata(pagy)
      {
        current_page: pagy.page,
        per_page: pagy.limit,
        total_count: pagy.count,
        total_pages: pagy.pages
      }
    end

    def render_index(component:, records:, serializer:, **extra_props)
      pagy, paginated = pagy(records)

      render inertia: component, props: {
        records: paginated.map { |r| serializer.call(r) },
        pagination: pagy_metadata(pagy),
        **extra_props
      }
    end
  end
end
