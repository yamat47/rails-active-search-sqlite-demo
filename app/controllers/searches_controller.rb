class SearchesController < ApplicationController
  # Each one shows a different gap between the three tokenizers (see the README).
  SAMPLE_QUERIES = %w[ごん ゴーシュ 蜘蛛の糸 料理店 泣いた 月].freeze

  def show
    @query = params[:q].to_s.strip
    @author = params[:author].presence
    @authors = Work.distinct.order(:author).pluck(:author)
    @sample_queries = SAMPLE_QUERIES
    @columns = @query.present? ? SearchStrategy.all.map { |strategy| Column.new(strategy, @query, @author) } : []
  end

  # One strategy's results for the page, with the failure kept to its own column: FTS5 refuses
  # some inputs that Active Search cannot sanitize away, and the other two columns still answer.
  Column = Struct.new(:strategy, :query, :author) do
    def results
      @results ||= strategy.search(query, author: author)
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
