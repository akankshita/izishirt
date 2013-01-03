class Create::FlashConfigsController < ApplicationController
  #Remove caching cause its not working with country tax
  #cache_sweeper :flash_config_sweeper
  #caches_action :index, :cache_path => :index_cache_path.to_proc 

  # GET /texts
  # GET /texts.xml
  # GET /texts.fxml
  def index
    @configs = FlashConfig.all
    @configs << tax(@configs.last.id+1)
    @configs << currency(@configs.last.id+1)
    @configs << bulk_discount(@configs.last.id+1)
    @configs << use_per_model_discount(@configs.last.id+1)
    @configs += user_configs(@configs.last.id+1)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @configs.to_xml(:only => [:id, :value, :identifier]) }
      format.fxml  { render :fxml => @configs.to_fxml(:only => [:id, :value, :identifier]) }
    end
  end

  # GET /texts/1
  # GET /texts/1.xml
  # GET /texts/1.fxml
  def show
    @config = FlashConfig.find_by_identifier_and_language_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @config }
      format.fxml  { render :fxml => @config }
    end
  end

  def index_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/configs/configs.fxml"
    else
      "flash/configs/configs.fxml"
    end
  end
  
  private 
  
  ###################################################################################################
  #Defines user configs that are created on the fly but never saved because they change from 
  #Boutique to boutique
  ###################################################################################################
  def user_configs(id)
    begin
      if params[:user_id] != 'null' || params[:store_id] !='null'
        user = params[:user_id] != 'null' ? User.find(params[:user_id]) : Store.find(params[:store_id]).user;        
        apply_size_prices = FlashConfig.new({:identifier => "apply_size_prices", :value => user.apply_size_prices})
        apply_size_prices.id = id
        apply_discounts = FlashConfig.new({:identifier => "apply_discounts", :value => user.apply_discounts})
        apply_discounts.id = id+1
        return [apply_size_prices,apply_discounts]    
      else
        return default_user_configs(id)
      end
    rescue
      return default_user_configs(id)
    end
  end
  
  def default_user_configs(id)
    apply_size_prices = FlashConfig.new({:identifier => "apply_size_prices", :value => 'true'})
    apply_size_prices.id = id
    apply_discounts = FlashConfig.new({:identifier => "apply_discounts", :value => 'true'})
    apply_discounts.id = id+1
    return [apply_size_prices,apply_discounts]    
  end

  def currency(id)
    @currency = FlashConfig.new({:identifier => "currency_rate",
                             :value => currency_rate(session[:currency]) })
    @currency.id = id
    return @currency    
  end
  
  def tax(id)
    country = session[:country] == "EU" ? "FR" : session[:country]
    #@tax = FlashConfig.new({:identifier => "country_tax", 
    #                         :value => Country.find_by_shortname(country).tax+1})
    @tax = FlashConfig.new({:identifier => "country_tax", 
                             :value => 1})
    @tax.id = id
    return @tax    
  end

  def bulk_discount(id)
    @discount = FlashConfig.new({
      :identifier => "bulk_discount",
      :value => BulkDiscount.default_discount_string
    })
    @discount.id = id
    return @discount    
  end

  def use_per_model_discount(id)
    @discount = FlashConfig.new({
      :identifier => "use_per_model_discount",
      :value => ApplicationSetting.use_per_model_discount?
    })
    @discount.id = id
    return @discount    
  end
end
