class Create::ModelsController < ApplicationController
  cache_sweeper :flash_model_sweeper
  #caches_action :index, :cache_path => Proc.new { |controller| controller.params.merge(:version=>18) } , :expires_in=>60.minutes
  #caches_action :show, :cache_path => Proc.new { |controller| controller.params.merge(:version=>18) }, :expires_in=>60.minutes


  
  # GET /models
  # GET /models.xml
  # GET /models.fxml
  def index
    conditions = ["localized_models.language_id = ?", session[:language_id]]
    begin
      if params[:user_id] != 'null' || params[:store_id] != 'null'
        user = params[:user_id] != 'null' ? User.find(params[:user_id]) : Store.find(params[:store_id]).user
        if user.only_custom_models
          conditions[0] += " and vip_model_specifications.user_id = ?"
          conditions << user.id
        else
          conditions[0] += " and models.user_id is null"
        end
      else
        conditions[0] += " and models.user_id is null"
      end
    rescue
      conditions[0] += " and models.user_id is null"
    end


#    if params[:custom_case] == "true"
#      mode = "custom_case"
#    else
      mode = "custom"
#    end

#    if params[:store_id] != 'null'
    #if params[:custom_case] == "false" || params[:custom_case].nil?
     # conditions[0] += " and model_category = '#{mode}'"
    #else
      conditions[0] += " and model_category LIKE '%#{mode}%'"
    #end






    @models = Model.find_all_by_active(1,
                :conditions=> conditions,
                :include=>{                           :category => [], 
                           :model_specifications => {:color => [:localized_colors]}, 
                           :localized_models =>[] }, 
                :order=>"models.sort_order ASC")
    @models = Model.prepare_index_for_flex(@models,session[:language_id],@URL_ROOT)
    @models.delete_if{|model| model.model_specifications == [] }
    #list action needs few attributes
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @models.to_xml(:only => [:id, :model_name, :price, :thumbnail, :category_id, :model_category])}
      format.fxml  { render :fxml => @models.to_fxml(:only => [:id, :model_name, :price, :thumbnail, :category_id, :model_category])}  
    end
  end

  
  def show
    if params[:user_id] != 'null' || params[:store_id] != 'null'
      user_id = params[:user_id] != 'null' ? params[:user_id] : Store.find(params[:store_id]).user.id
    else 
      user_id = nil
    end

    @model = Model.find_all_by_id(params[:id], 
                :conditions=>["localized_models.language_id = #{session[:language_id]}"], 
                :include=>[:category, :model_specifications, :localized_models])
    @model = Model.prepare_show_for_flex(@model, I18n.locale, session[:language_id], @URL_ROOT, user_id, session[:country]).first
	#@model = Model.prepare_show_for_flex(@model, I18n.locale, session[:language_id], @URL_ROOT, user_id).first

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @model.to_xml(:only => attribute_array,
        :include => {:model_zones => {}, :model_specifications => {:methods=>[:mask_picture_url, :mask_generation_picture_url, :supplier_generation_picture_url], :include => {:sizes => {}, :color => {}, :model_prices => {} }}} )}
          
      format.fxml  { render :fxml => @model.to_fxml(:only => attribute_array, 
        :include => {:model_zones => {}, :model_specifications => {:methods=>[:mask_picture_url, :mask_generation_picture_url, :supplier_generation_picture_url], :include => {:sizes => {}, :color => {}, :model_prices => {} }}} )}
    end    
  end
  
  private

  def attribute_array
	    [
		    :id,
        :name,
	      :category_id,
				:warning_text,
				:default_color_id,
	      :default_zone,
				:price,
				:pricefr,
        :minimum_sale_price,
        :designs_per_zone,
				:model_name,
        :bulk_discount,
				:desc,
				:info,
				:identifier,
	      :image,
	      :thumbnail,
        :show_sizes,
        :color_id,      
        :model_id, 
        :img_front,
        :thumb_front,
        :img_back,
        :thumb_back,
        :img_left,
        :thumb_left,
        :img_right,
        :thumb_right,
        :mask_picture_url,
        :mask_generation_picture_url,
        :supplier_generation_picture_url,
        :zone_type,
        :max_lines,
        :max_images,
        :top_left_x,
        :top_left_y,
        :bottom_right_x,
        :bottom_right_y,
        :extra_cost,
        :model_category
     ]
  end

  def index_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/models/models.fxml"
    else
      "flash/models/models.fxml"
    end
  end

  def show_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/models/#{params[:id]}.fxml"
    else
      "flash/models/#{params[:id]}.fxml"
    end
  end
end
