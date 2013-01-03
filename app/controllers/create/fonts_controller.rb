class Create::FontsController < ApplicationController
  cache_sweeper :flash_font_sweeper
  caches_action :index, :cache_path => Proc.new { |controller| controller.params } , :expires_in=>60.minutes
  # GET /fonts
  # GET /fonts.xml
  # GET /fonts.fxml
  def index
    @fonts = Font.all
    @fonts.each{|f|f.write_attribute("flash_identifier",f.flash_id)}

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fonts}
      format.fxml  { render :fxml => @fonts}
    end
  end
  def index_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/fonts/fonts.fxml"
    else
      "flash/fonts/fonts.fxml"
    end
  end
end
