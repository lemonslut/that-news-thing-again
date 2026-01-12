module Admin
  class ArticleAnalysesController < BaseController
    def index
      analyses = ArticleAnalysis.includes(:article).order(created_at: :desc)
      analyses = analyses.of_type(params[:type]) if params[:type].present?

      render_index(
        component: "ArticleAnalyses/Index",
        records: analyses,
        serializer: method(:serialize_analysis),
        types: ArticleAnalysis::TYPES
      )
    end

    def show
      analysis = ArticleAnalysis.includes(:article).find(params[:id])

      render inertia: "ArticleAnalyses/Show", props: {
        analysis: serialize_analysis_detail(analysis)
      }
    end

    def destroy
      ArticleAnalysis.find(params[:id]).destroy
      redirect_to admin_article_analyses_path, notice: "Analysis deleted"
    end

    private

    def serialize_analysis(analysis)
      {
        id: analysis.id,
        analysis_type: analysis.analysis_type,
        model_used: analysis.model_used,
        article: {
          id: analysis.article.id,
          title: analysis.article.title
        },
        created_at: analysis.created_at.iso8601
      }
    end

    def serialize_analysis_detail(analysis)
      serialize_analysis(analysis).merge(
        result: analysis.result,
        raw_response: analysis.raw_response
      )
    end
  end
end
