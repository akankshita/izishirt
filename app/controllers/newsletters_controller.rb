class NewslettersController < ApplicationController

  layout nil

  def index
    id = params[:id]
    @newsletter = Newsletter.find(id)
    @language_id = params[:language_id]

	if ! @language_id
		@language_id = session[:language_id]
	end

    @country_id = params[:country]
  end
  
end
