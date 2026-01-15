class SearchController < ApplicationController
  def index
    @response = MicropostSearch.search(
      query: params[:q],
      user_id: params[:user_id],
      hashtag: params[:hashtag],
      from: params[:from],
      to: params[:to]
    )

    @docs = @response['response']['docs']
    @highlights = @response['highlighting']
  end

  def autocomplete
    response = MicropostAutocomplete.call(params[:q])
    render json: response['response']['docs']
  end
end
