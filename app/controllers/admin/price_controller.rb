class Admin::PriceController < Administration

  def index
    #@price = Price.find(:all)#_all_by_technology_id_and_price_type_id(Technology.find_all_by_id(),PriceType.find_all_by_id())
	
	@price = Price.find_by_sql("select p.id as id, p.price, p.name, t.name as t_name, pt.name as pt_name from prices as p, price_types as pt, technologies as t where p.technology_id = t.id  and pt.id = p.price_type_id order by p.name, p.id ASC")
  end

  def canada_tax
    @provinces = Country.find_by_shortname("ca").provinces
  end
  def update_canada_tax
    @provinces = Country.find_by_shortname("ca").provinces
    @provinces.each do |province|
      province.update_attribute("taxe",params[:province]["#{province.id}"])
    end
    flash[:notice]="Province taxes successfuly updated"
    render :action => 'canada_tax'
  end

  def country_tax
    @countries = Country.all
    @country = Country.find(params[:id] || 1) #default to canada
    Language.all.each do |language|
      LocalizedCountry.find_or_create_by_country_id_and_language_id(@country.id,language.id)
    end
  end
  
  def get_country
    @country = Country.find(params[:id])
    Language.all.each do |language|
      LocalizedCountry.find_or_create_by_country_id_and_language_id(@country.id,language.id)
    end
    render :partial => "country_form"
  end

  def update_country
    @country = Country.find(params[:id])
    @country.update_attributes(params[:country])
    params[:localized_countries].each do |language, fields|
    #Language.all.each do |language|
      local_country = LocalizedCountry.find_or_create_by_country_id_and_language_id(@country.id,language)
      local_country.update_attribute("tax_abreviation", fields[:tax_abreviation])
    end
    flash[:notice] = "Country Tax Saved"
    render :action => 'country_tax'
  end

  def new_flash
    @prices = FlashConfig.find_all_by_config_type("price")
  end

  def discounts
    @bulk_discounts = BulkDiscount.defaults
    @application_setting = ApplicationSetting.find_by_name("use_per_model_discount")
  end

  def create_bulk_discount
    @bulk_discount = BulkDiscount.new(params[:bulk_discount])
    if @bulk_discount.save
      flash[:notice] = "Bulk discount created successfuly"
    else
      flash[:notice] = "Error occured creating bulk discount"
    end
    redirect_to :action => 'discounts'
  end
  def destroy_bulk_discount
    if BulkDiscount.exists?(params[:id])
      @bulk_discount = BulkDiscount.find(params[:id])
      @bulk_discount.destroy
      flash[:notice] = "Bulk discount destroyed successfuly"
    else
      flash[:notice] = "Error destroying discount"
    end
    redirect_to :action => 'discounts'
  end
  
  def update_application_setting
    application_setting = ApplicationSetting.find(params[:id])
    application_setting.update_attributes(params[:application_setting])
    flash[:notice] = "'Use per model discount' updated successfully"
    redirect_to :action => 'discounts'
  end

  def models
    @models = Model.find_all_by_active(1, :conditions=>"model_category LIKE '%custom%'", :order => 'brand_id')
    @model = Model.find(params[:id]) if params[:id]
  end
  
  def reset_model_price
    @model = Model.find(params[:id])
    @model.model_specifications.each { |ms| ms.set_default_prices() }
    redirect_to :action => "models", :id => @model.id    
  end
    
  def reset_spec_price
    @model_specification = ModelSpecification.find(params[:id])
    @model_specification.set_default_prices()
    redirect_to :action => "models", :id => @model_specification.model_id
  end
  
  def save_model
    params[:model_prices].each do |model_price_id, model_price|
      ModelPrice.find(model_price_id).update_attributes(model_price)
    end
    flash[:notice] = "Prices saved successfuly!"
    redirect_to :action => "models", :id => params[:id]
  end

  def update_new_flash
    @prices = FlashConfig.find_all_by_config_type("price")
    val = 0
    friendly_name = ""
    @prices.each do |price|
			val = params[:price]["#{price.id}"].to_f
      friendly_name = price.friendly_name
			break if val < 0
#			ModelPrice.find_all_by_identifier_and_price(price.identifier, price.value).each {|mp| mp.update_attribute("price",val)}
			ModelPrice.update_all("price = #{val}", "identifier = '#{price.identifier}' and price = #{price.value}")
			FlashConfig.update(price.id.to_i, {:value => val})
    end
		
    if val < 0
			flash[:notice] = "Invalid input value for '" + friendly_name + "'"
    else
			flash[:notice] = t(:admin_flash_updated)   
		end
		redirect_to :action => "new_flash"
  end
  
  
  def update_price
		 @price = Price.find_by_sql("select p.id as id, p.price, p.name, t.name as t_name, pt.name as pt_name from prices as p, price_types as pt, technologies as t where p.technology_id = t.id  and pt.id = p.price_type_id order by p.id ASC")
		 for i in 0...@price.size do 
			temp_price = params[:price]["label_#{@price[i].id}"].to_f
			break if temp_price < 0
			Price.update(@price[i].id.to_i, {:price => temp_price})
		 end
		if temp_price < 0
			flash[:notice] = "Invalid input values at # " + @price[i].id.to_s
		 else
			flash[:notice] = t(:admin_flash_updated)   
		end
		 redirect_to :action => "index"
  end  

	def blanks
		@models = Model.find_all_by_active_and_model_category(true, "blank")

		begin
			@model = Model.find(params[:model_id])
			@model_id = @model.id
			@model_specs = @model.model_specifications
		rescue
			@model = nil
			@model_id = 0
		end

	end

	def refresh_blank_prices
		begin
			@model = Model.find(params[:model_id])
		rescue
			@model = nil
		end

		if ! @model
			render :text => ""
			return
		end

		@model_specs = @model.model_specifications

		render :layout => false
	end

	def update_blank_prices

		model = Model.find(params[:model_id])

		if ! params[:price]
			params[:price] = {}
		end

		if ! params[:apply_to_all]
			params[:apply_to_all] = {}
		end

		qty_min = params[:qty_min].to_i
		qty_max = params[:qty_max].to_i

		params[:price].each do |pair_id, price|
			ids = pair_id.split("_")

			model_spec_id = ids[0]
			model_size_id = ids[1]

			bp = BlankPrice.find_by_model_specification_id_and_model_size_id_and_qty_min_and_qty_max(model_spec_id, model_size_id, qty_min, qty_max)

			if ! bp
				bp = BlankPrice.create(:model_specification_id => model_spec_id, :model_size_id => model_size_id, :qty_min => qty_min, :qty_max => qty_max)
			end

			bp.update_attributes(:price => price)
		end

		# apply to all
		params[:apply_to_all].each do |model_size_id, price|
			if ! price || price == ""
				next
			end

			model.model_specifications.each do |model_spec|
				bp = BlankPrice.find_by_model_specification_id_and_model_size_id_and_qty_min_and_qty_max(model_spec.id, model_size_id, qty_min, qty_max)

				if ! bp
					bp = BlankPrice.create(:model_specification_id => model_spec.id, :model_size_id => model_size_id, :qty_min => qty_min, :qty_max => qty_max)
				end

				bp.update_attributes(:price => price)
			end
		end

		redirect_to :action => "blanks", :model_id => model.id
	end

	def blank_model_problems
		@models = Model.find_all_by_model_category_and_active("blank", true, 
			:conditions => ["EXISTS(SELECT * FROM model_sizes, model_specifications spec " +
					"WHERE models.id = spec.model_id AND model_sizes.model_id = models.id AND (NOT EXISTS(SELECT * FROM blank_prices p WHERE p.model_specification_id = spec.id AND p.model_size_id = model_sizes.id) OR EXISTS(SELECT * FROM blank_prices p WHERE p.model_specification_id = spec.id AND p.model_size_id = model_sizes.id AND p.price <= 0)))"])
	end
 
end
