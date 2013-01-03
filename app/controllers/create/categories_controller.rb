class Create::CategoriesController < ApplicationController
  cache_sweeper :flash_category_sweeper
  caches_action :index, :cache_path => Proc.new { |controller| controller.params.merge(:version=>2) }, :expires_in=>60.minutes

  # GET /categories
  # GET /categories.xml
  # GET /categories.fxml
  def index
    @categories = Category.active_parent_categories_for_flex(session[:language_id])
    @categories = Category.prepare_for_flex(@categories, session[:language_id])
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories.to_xml(:only => attribute_array, 
        :include => :sub_categories)}
      format.fxml  { render :fxml => @categories.to_fxml(:only => attribute_array, 
        :include => :sub_categories)}
    end
  end
  
  private 
  
  def attribute_array
    [:id, :name, :cat_type, :is_parent_category]
  end

  def index_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/categories/categories.fxml"
    else
      "flash/categories/categories.fxml"
    end
  end
end
