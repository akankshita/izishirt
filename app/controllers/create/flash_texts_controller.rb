class Create::FlashTextsController < ApplicationController
  #cache_sweeper :flash_text_sweeper
  #caches_action :index, :cache_path => Proc.new { |controller| controller.params } #:index_cache_path.to_proc 
  # GET /texts
  # GET /texts.xml
  # GET /texts.fxml
  def index
    @texts = FlashText.find_all_by_language_id(session[:language_id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @texts.to_xml(:only => [:id, :text, :identifier]) }
      format.fxml  { render :fxml => @texts.to_fxml(:only => [:id, :text, :identifier]) }
    end
  end

  # GET /texts/1
  # GET /texts/1.xml
  # GET /texts/1.fxml
  def show
    @text = FlashText.find_by_identifier_and_language_id(params[:id], session[:language_id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @text }
      format.fxml  { render :fxml => @text }
    end
  end

  def index_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/text/text.fxml"
    else
      "flash/text/text.fxml"
    end
  end
end
