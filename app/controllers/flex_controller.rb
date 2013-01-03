class FlexController < ApplicationController
  def index
    @flash_vars = "sessionVar=#{request.session_options[:id]}"
    @flash_vars+= "&sessionLanguage=#{session[:language]}"
    if params[:image_id] && 
      Image.exists?({:id => params[:image_id], :active => 1, :pending_approval => 1, :is_private => 0 })
      @flash_vars+= "&designId=#{params[:image_id]}"
    end
    if params[:model_id] && 
      Model.exists?({:id => params[:model_id], :active => 1 })
      @flash_vars+= "&modelId=#{params[:model_id]}"
    end   
    if params[:category_id] && 
      Category.exists?({:id => params[:category_id], :active => 1 })
      @flash_vars+= "&categoryId=#{params[:category_id]}"
    end
    if params[:tab_id]
      @flash_vars+= "&tabId=#{params[:tab_id]}"
    end    
    if params[:color_id]
      @flash_vars+= "&colorId=#{params[:color_id]}"
    end
    if params[:ordered_product_id]
      @flash_vars+= "&orderedProductId=#{params[:ordered_product_id]}"
    end                 
  end
end
