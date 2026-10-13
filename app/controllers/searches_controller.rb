class SearchesController < ApplicationController
  # Each one shows a different gap between the three tokenizers (see the README).
  SAMPLE_QUERIES = [ "callbacks", "validate", "deprecat", "has_many", "N+1", "eager loading" ].freeze

  def show
    @query = params[:q].to_s.strip
    @guides = Guide.order(:title)
    @guide = @guides.find_by(id: params[:guide]) if params[:guide].present?
    @sample_queries = SAMPLE_QUERIES
    @columns = @query.present? ? SearchStrategy.all.map { |strategy| Column.new(strategy, @query, @guide&.id) } : []
  end

  # One strategy's results for the page, with the failure kept to its own column: FTS5 refuses
  # some inputs that Active Search cannot sanitize away, and the other two columns still answer.
  Column = Struct.new(:strategy, :query, :guide_id) do
    def results
      @results ||= strategy.search(query, guide_id: guide_id)
    rescue ActiveRecord::StatementInvalid, ActiveSearch::QueryError => e
      @error = e.message
      nil
    end

    def error
      results
      @error
    end

    def tokens
      strategy.tokens(query)
    rescue ActiveRecord::StatementInvalid
      []
    end
  end
end
