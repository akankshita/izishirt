class Admin::ModelController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

	def categorize_garments
		@categories = Category.find_all_by_category_type_id(2).map {|c| [c.local_name(session[:language_id]), c.id]}
		@brands = Category.find_all_by_category_type_id(CategoryType.find_by_name("Brands").id).map {|c| [c.local_name(session[:language_id]), c.id]}
		@models = Model.paginate(:conditions => ["models.id > 1258"], :page => params[:page], :per_page => 50, :order => "id DESC")
	end

	def update_categorization
		if ! params[:cat]
			params[:cat] = {}
		end

		params[:cat].each do |model_id, value|
			begin
				model = Model.find(model_id)
			
				model.update_attributes(:garment_type_id => value)
			rescue
			end
		end
		if ! params[:category]
			params[:category] = {}
		end

		params[:category].each do |model_id, value|
			begin
				model = Model.find(model_id)
			
				model.update_attributes(:category_id => value)
			rescue
			end
		end

		if ! params[:product_category]
			params[:product_category] = {}
		end

		params[:product_category].each do |model_id, value|
			begin
				model = Model.find(model_id)
			
				model.update_attributes(:product_category_id => value)
			rescue
			end
		end

		params[:brand].each do |model_id, value|
			begin
				model = Model.find(model_id)
			
				model.update_attributes(:brand_id => value)
			rescue
			end
		end

		redirect_to :back
	end

	def fill_store_infos
		@models = Model.paginate(:conditions => ["model_category = 'store'"], :page => params[:page], :per_page => 50, :order => "id DESC")
	end

	def update_store_infos
		params[:model].each do |model_id, infos|

			model = Model.find(model_id)

			lc_fr = model.localized_models.find_by_language_id(1)
			lc_en = model.localized_models.find_by_language_id(2)

			name_fr = infos[:name_1]
			name_en = infos[:name_2]

			if name_fr && name_fr != ""
				lc_fr.update_attributes(:name => name_fr, :nickname => name_fr)
			end

			if name_en && name_en != ""
				lc_en.update_attributes(:name => name_en, :nickname => name_en)
			end
	
			if infos[:product_category_id] && infos[:product_category_id].to_i > 0
				model.update_attributes(:product_category_id => infos[:product_category_id])
			end
		end

		redirect_to :back
	end

	def manage_model_previews
		@model = Model.find(params[:id])
	end

	def upload_model_preview
		model = Model.find(params[:id])

		# begin
		
			ModelPreview.create({:image => params[:new_image], :model_id => model.id})
		# rescue
		#	flash[:error] = "Error while uploading."
		# end

		redirect_to :action => "manage_model_previews", :id => model.id
	end

	def update_preview_positions
		if ! params[:position]
			params[:position] = {}
		end

		params[:position].each do |model_preview_id, value|
			obj = ModelPreview.find(model_preview_id)
			
			obj.update_attributes(:the_order => value)
		end

		redirect_to :back
	end

	def remove_model_preview
		mp = ModelPreview.find(params[:id])
	
		mp.destroy

		redirect_to :back
	end

	###################################################################################################
	# Garment stocks
	###################################################################################################

	def garment_stock
		params[:page] = params[:page] ? params[:page].to_i : 1
		params[:order] = params[:order] ? params[:order] : "id DESC"

		@garment_stocks = GarmentStock.paginate(:order => params[:order], :page => params[:page], :per_page => 50)

		@total_price, @total_cost_price, @total_retail_price = GarmentStock.general_stats()
	end


	def add_garment_stock
		@garment_stock = GarmentStock.new()
		@garment_stock.model_id = 0
		@garment_stock.color_id = 0
		@garment_stock.model_size_id = 0

		prepare_for_garment_stock_form()
	end

	def exec_add_garment_stock
		begin
			validate_garment_stock_form

			# check if it already exists:
			stock = GarmentStock.find_by_model_id_and_color_id_and_model_size_id(params[:garment_stock][:model_id], params[:garment_stock][:color_id], params[:garment_stock][:model_size_id])

			if stock
				stock.update_attributes(:quantity => stock.quantity + params[:garment_stock][:quantity].to_i)
			else
				GarmentStock.create(params[:garment_stock])
			end
		rescue => e
			flash[:error] = "Error: Make sure to fill all the fields."
			redirect_to :back
			return
		end

		redirect_to :action => "garment_stock"
	end

	def exec_edit_garment_stock
		begin
			validate_garment_stock_form

			garment_stock = GarmentStock.find(params[:id])
			garment_stock.update_attributes(params[:garment_stock])
		rescue => e
			flash[:error] = "Error: Make sure to fill all the fields."
			redirect_to :back
			return
		end

		redirect_to :action => "garment_stock"
	end

	def delete_garment_stock
		begin
			s = GarmentStock.find(params[:id])
			s.destroy
		rescue
		end

		redirect_to :action => "garment_stock"
	end

	def prepare_for_garment_stock_form
		@models = Model.find(:all)
		@colors = []
		@model_sizes = []
	end

	def garment_stock_load_color_model
		@color_id = params[:garment_stock_custom][:color_id].to_i if params[:garment_stock_custom]

		model_id = params[:garment_stock][:model_id]

		@colors = Color.find(:all, :conditions => ["EXISTS (SELECT * FROM model_specifications spec WHERE colors.id = spec.color_id AND spec.model_id = #{model_id})"])

		render :layout => false
	end

	def garment_stock_load_size_model
		@model_size_id = params[:garment_stock_custom][:model_size_id].to_i if params[:garment_stock_custom]

		model_id = params[:garment_stock][:model_id]

		    @model_sizes = Model.find(model_id).active_model_sizes

		render :layout => false
	end

	def garment_stock_load_model_search
		model_search = params[:search_model]
		@model_id = params[:garment_stock][:model_id].to_i

		@models = Model.find(:all, :conditions => ["EXISTS (SELECT * FROM localized_models l WHERE l.model_id = models.id AND name LIKE '%%#{model_search}%%')"])

		render :layout => false
	end

	###################################################################################################
	# END Garment stocks
	###################################################################################################

	###################################################################################################
	# Garment cost updater
	###################################################################################################
	def garment_cost_updater
		prepare_garment_cost

		@search_text = params[:search_text]

		conditions = ""

		if @search_text && @search_text != ""
			conditions += " AND EXISTS (SELECT * FROM localized_models trad WHERE trad.model_id = models.id AND trad.name LIKE '%%#{@search_text}%%')"
		end

		conditions += " AND models.model_category = '#{@model_category}' "

		# check if the model ext specs are created..
		@models = Model.paginate(:conditions => ["active = 1 #{conditions}"], :page => params[:page], :per_page => 50, :order => "models.id DESC")

		if @model_id > 0
			@models = Model.paginate(:conditions => ["id = #{@model_id}"], :page => params[:page], :per_page => 50, :order => "models.id DESC")
		elsif @supplier_id > 0
			@models = Model.paginate(:conditions => ["appatel_supplier_id = #{@supplier_id} AND active = 1 #{conditions}"], :page => params[:page], :per_page => 50, :order => "models.id DESC")
		end

		@quote_colors = QuoteProductColor.find(:all)

		if @quote_product_color_id > 0
			@quote_colors = [QuoteProductColor.find(@quote_product_color_id)]
		end

	end

  def update_garment_cost_sizes
    @model = Model.find(params[:id])

    @model_sizes = [["All", 0]] | @model.active_model_sizes.map{|model_size|
      [model_size.local_name(I18n.locale), model_size.id]
    }

    render :partial => 'update_garment_cost_sizes'
  end

	def prepare_garment_cost
		begin
			@model_category = params[:model_category]
		rescue
		end

		if ! @model_category || @model_category == ""
			@model_category = "custom"
		end

		conditions = " models.model_category = '#{@model_category}' "

		@quote_product_colors = [["All", 0]] | QuoteProductColor.find(:all).map{ |quote_prod_color| [quote_prod_color.str_id, quote_prod_color.id] }
		@models_list = [["All", 0]] | Model.find_all_by_active(true, :conditions => [conditions]).map { |model| [model.local_name(session[:language_id]), model.id] }.sort{|x,y|x[0]<=>y[0]}
		@model_sizes = [["All", 0]] 

		begin
			@supplier_id = params[:search_supplier].to_i
		rescue
			@supplier_id = 0
		end

		begin
			@quote_product_color_id = params[:search_color].to_i
		rescue
			@quote_product_color_id = 0
		end

		begin
			@model_id = params[:search_model].to_i
      @model_sizes |= Model.find(@model_id).active_model_sizes.map{ |model_size|
        [model_size.local_name(I18n.locale), model_size.id]
      }
		rescue
			@model_id = 0
		end

		begin
			@size_id = params[:search_size].to_i
		rescue
			@size_id = 0
		end

	end

	def bulk_update_garment_cost

		prepare_garment_cost

		@models = Model.find_all_by_active(true)

		if @model_id > 0
			@models = [Model.find(@model_id)]
		elsif @supplier_id > 0
			@models = Model.find_all_by_apparel_supplier_id_and_active(@supplier_id, true, :conditions => [conditions])
		end

		@quote_colors = QuoteProductColor.find(:all)

		if @quote_product_color_id > 0
			@quote_colors = [QuoteProductColor.find(@quote_product_color_id)]
		end

		has_specific_size = false
		specific_size_id = -1

		if params[:search_size] && params[:search_size].to_i > 0
			has_specific_size = true
			specific_size_id = params[:search_size].to_i
		end

		@models.each do |model|
			logger.error("model id => #{model.id}")
			@quote_colors.each do |quote_color|
				model.model_sizes.each do |model_size|
					if (has_specific_size && specific_size_id == model_size.id) || ( ! has_specific_size)
						#begin
							begin
								ext_spec = ModelExtSpecification.find_by_model_id_and_model_size_id_and_quote_product_color_id(model.id, model_size.id, quote_color.id)
							rescue
								ext_spec = nil
							end

							if ! ext_spec
								ext_spec = ModelExtSpecification.create(:model_id => model.id, :model_size_id => model_size.id, :quote_product_color_id => quote_color.id, :cost_price => model.cost_price)
							end

							logger.error("exp spec, #{ext_spec.id}")

							new_cost = ext_spec.cost_price.to_f

							amount = params[:bulk_percentage_price].to_f

							if params[:bulk_amount_type] == "percentage"
								amount = amount / 100.00
								new_cost = new_cost + (new_cost * amount)
							elsif params[:bulk_amount_type] == "amount"
								new_cost = new_cost + (amount)
							end

							ext_spec.update_attributes(:cost_price => new_cost)
						#rescue
						#end
					end
				end
			end
		end
	
		redirect_to :back
	end

	def update_garment_cost
		params["ext_spec"].each do |ext_spec_id, cost_price|
			ModelExtSpecification.find(ext_spec_id).update_attributes(:cost_price => cost_price)
		end

		redirect_to :action => "garment_cost_updater", :model_category => params[:model_category], :search_supplier => params[:search_supplier], :search_color => params[:search_color], :search_model => params[:search_model], :search_text => params[:search_text]
	end
	###################################################################################################
	# End Garment cost updater
	###################################################################################################

  def list
    order = (params[:order]) ? params[:order] : 'active desc, id desc' 
    
    @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}

	begin
		@user_id = params[:model][:user_id].to_i

		if @user_id == 0
			@user_id = nil
		end
	rescue
		@user_id = nil
	end
	
    conditions = (@user_id) ? "user_id = #{@user_id}" : "user_id IS NULL"

	begin
		@model_category = params[:model][:model_category]
	rescue
		@model_category = nil
	end

	if ! @model_category || @model_category == ""
		@model_category = "custom"
	end

	conditions += " AND models.model_category = '#{@model_category}' "

    @models = Model.paginate :conditions => conditions, 
              :order => order, 
              :per_page => ITEMS_PER_PAGE, 
              :page => params[:page]
  end
  
  def search
    search = params[:search]
    
    conditions = []
    
    if search
      conditions = ["EXISTS (SELECT * FROM localized_models lm WHERE lm.name LIKE :search AND lm.model_id = models.id) OR " +
        "EXISTS (SELECT * FROM localized_categories lc WHERE lc.name LIKE :search AND models.category_id = lc.category_id)", {:search => '%' + search + '%'}]
    end
    
    order = (params[:order]) ? params[:order] : 'active desc, id desc'
    
    @models = Model.paginate :conditions => conditions, :order => order, :per_page => ITEMS_PER_PAGE, :page => params[:page]
    
    @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
    render :action => "list"
  end
  
  def new
    @mymodel = Model.new
    @size_types = SizeType.all.map{|size_type|[size_type.name, size_type.id]}
    for lang in Language.find :all
      @mymodel.localized_models << LocalizedModel.new({:language_id => lang.id})
    end
    populate_dropdowns
  end

  def clone
    #begin
      @model_to_clone = Model.find(params[:id])
      @model = @model_to_clone.full_clone
      flash[:notice] = "Model Cloned Successfuly: you are now editing the model clone"
      redirect_to :action => 'edit', :id => @model.id
    #rescue
    #  flash[:notice] = "An error occured while cloning the model"
    #  redirect_to :action => 'edit', :id => params[:id]
    #end
  end
  
  def create
    @mymodel = Model.new(params[:mymodel])
    for lang in Language.find :all
		 @mymodel.localized_models << LocalizedModel.new({:language_id => lang.id, :name => params["localized_name_#{lang.id}"], :description => params["localized_description_#{lang.id}"], :warning_text => params["localized_warning_#{lang.id}"] })

		#@mymodel.localized_models << LocalizedModel.new({:language_id => lang.id, :name => params["localized_name_#{lang.id}"], :description => params["localized_description_#{lang.id}"], :warning_text => params["localized_warning_#{lang.id}"], :name => params["localized_name_#{l.lang.id}"], :nickname => params["localized_nickname_#{l.lang.id}"], :seo_name => params["localized_seo_name_#{l.lang.id}"], :description=> params["localized_description_#{l.lang.id}"], :model_info_upload => params["localized_model_info_#{l.lang.id}"], :warning_text=> params["localized_warning_#{l.lang.id}"], :create_meta_title => params["localized_create_meta_title_#{l.lang.id}"], :create_meta_description => params["localized_create_meta_description_#{l.lang.id}"], :create_meta_keywords => params["localized_create_meta_keywords_#{l.lang.id}"], :create_h1 => params["localized_create_h1_#{l.lang.id}"], :create_desc => params["localized_create_desc_#{l.lang.id}"] })
    end

    front=ModelZone.create()
    back=ModelZone.create()
    front.update_attribute('zone_type',1)
    back.update_attribute('zone_type',2)
    @mymodel.model_zones << front
    @mymodel.model_zones << back

    @mymodel.size_type.default_model_sizes.each do |default_model_size|
      @mymodel.model_sizes << default_model_size.get_clone
    end

    if @mymodel.save
      flash[:notice] = t(:admin_flash_created)
      @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
      redirect_to :action => 'list'
    else
      Rails.logger.error("dont get it @@@@@@@@@@@@@@@@@@@@")
      Rails.logger.error(@mymodel.save)
    Rails.logger.error(@mymodel.inspect)
      populate_dropdowns
      render :action => 'new'
    end
  end
  
  def default_model_sizes
    @size_types = SizeType.all
    @size_type = params[:size_type_id] ? SizeType.find(params[:size_type_id]) : @size_types.first

    @model_sizes = @size_type.default_model_sizes

    @default_locale = Locale.find_by_locale("en-CA")
    @locales= @model_sizes.empty? ? [@default_locale] : @model_sizes.first.localized_model_sizes.map{|lms|lms.locale}
    @other_locales = Locale.find(:all, :conditions => ["id not in (?)",@locales.map{|l|l.id}])
    @other_locales.map!{|locale|[locale.long_name, locale.id]}

  end

  def edit
    @mymodel = Model.find(params[:id])

    if @mymodel.user 
      @vip_model_specification = VipModelSpecification.find_or_create_by_model_id_and_user_id(@mymodel.id,
                                                                                              @mymodel.user_id)
    end

    @front = @mymodel.model_zones.find_by_zone_type(1)
    @back = @mymodel.model_zones.find_by_zone_type(2)
    @left = @mymodel.model_zones.find_by_zone_type(3) if @mymodel.model_zones.find_by_zone_type(3)
    @right = @mymodel.model_zones.find_by_zone_type(4) if @mymodel.model_zones.find_by_zone_type(4)

    @model_specifications = ModelSpecification.find_all_by_model_id(params[:id]).sort!{|a,b| a.color.local_name(session[:language_id]) <=> b.color.local_name(session[:language_id])}
    @Colors = Color.find_all_by_color_type_id_and_active(3,1).map{|c| [c.local_name(session[:language_id]), c.id]}.sort!{|a,b| a[0].upcase <=> b[0].upcase}
    populate_dropdowns
      
    @selected_color = Color.find(:first, :order => "id DESC")
  end

	def edit_garment_stock
		@garment_stock = GarmentStock.find(params[:id])

		prepare_for_garment_stock_form()
	end

  def edit_model_specification
     @model_specification = ModelSpecification.find(params[:id])
     @out_of_stock = OutOfStock.new
     @ms = @model_specification
     @mymodel = Model.find(@model_specification.model_id)
     @selected_color = Color.find(@model_specification.color_id)
     @Colors = Color.find_all_by_color_type_id_and_active(3,1).map{|c| [c.local_name(session[:language_id]), c.id]}.sort!{|a,b| a[0].upcase <=> b[0].upcase}
  end

  def edit_model_sizes
    @model = Model.find(params[:id])
    @model_sizes = @model.model_sizes
    @locales = @model_sizes.first.localized_model_sizes.map{|lms|lms.locale}
    @default_locale = Locale.find_by_locale("en-CA")
    @other_locales = Locale.find(:all, :conditions => ["id not in (?)",@locales.map{|l|l.id}])
    @other_locales.map!{|locale|[locale.long_name, locale.id]}
    @size_types = SizeType.all
  end

  def update_model_size_type
    @model = Model.find(params[:id]) 
    @model.update_attributes(params[:model])
    @model.model_sizes.each{|model_size|model_size.update_attribute('model_id',nil)}
    @model.size_type.default_model_sizes.each do |default_model_size|
      @model.model_sizes << default_model_size.get_clone
    end
    redirect_to :action => 'edit_model_sizes', :id => @model.id
  end

  def create_out_of_stock

	if Model.exists?(params[:out_of_stock][:model_id])
		params[:out_of_stock][:model_size_id].each do |model_size_id|
			params[:out_of_stock][:color_id].each do |color_id|

				begin
					out_of_stock = OutOfStock.find(:first, :conditions => ["model_id = #{params[:out_of_stock][:model_id]} AND model_size_id = #{model_size_id} AND color_id = #{color_id}"])
				rescue
					out_of_stock = nil
				end

				if ! out_of_stock
					@out_of_stock = OutOfStock.create({:model_id => params[:out_of_stock][:model_id],
									   :model_size_id => model_size_id,
									   :color_id => color_id, 
									   :expected_date => params[:search][:start]})
				end
			end
		end

	      redirect_to :action => 'edit', :id => params[:out_of_stock][:model_id]
	else
		redirect_to request.referer
	end
  end

  def create_bulk_discount
    if Model.exists? (params[:bulk_discount][:model_id])
      @bulk_discount = BulkDiscount.new(params[:bulk_discount])
      if @bulk_discount.save
        flash[:notice] = "Bulk discount created successfuly"
      else
        flash[:notice] = "Error occured creating bulk discount"
      end
      redirect_to :action => 'edit', :id => params[:bulk_discount][:model_id]
    end
  end

  def out_of_stock
    if params[:id]
      @out_of_stocks = OutOfStock.paginate :page => params[:page],  
        :include => [{:model, :localized_models}, {:color, :localized_colors}], 
        :conditions => ["out_of_stocks.model_id = ? and localized_models.language_id = ? and localized_colors.language_id = ?", 
          params[:id], session[:language_id],session[:language_id]],
        :order => "out_of_stocks.expected_date IS NOT NULL DESC, out_of_stocks.expected_date ASC, localized_models.name, localized_colors.name, model_size_id"
    else
      @out_of_stocks = OutOfStock.paginate :page => params[:page],  
        :include => [{:model, :localized_models}, {:color, :localized_colors}], 
        :conditions => ["localized_models.language_id = ? and localized_colors.language_id = ?", session[:language_id],session[:language_id]],
        :order => "out_of_stocks.expected_date IS NOT NULL DESC, out_of_stocks.expected_date ASC, localized_models.name, localized_colors.name, model_size_id"

    end
  end
  
  def destroy_out_of_stock
    if OutOfStock.exists?(params[:id])
      @out_of_stock = OutOfStock.find(params[:id])
      
      # - When an out of stock is destroyed, unflag all ordered products which are in back order for this model, color and size
      OrderedProduct.update_all("in_back_order = 0", "model_id = #{@out_of_stock.model_id} AND color_id = #{@out_of_stock.color_id} AND model_size_id = #{@out_of_stock.model_size_id}")
      
      @out_of_stock.destroy
      
      redirect_to request.referer
    else
      redirect_to :action => 'index'
    end
  end

  def destroy_bulk_discount
    if BulkDiscount.exists?(params[:id])
      @bulk_discount = BulkDiscount.find(params[:id])
      @model_id = @bulk_discount.model_id
      @bulk_discount.destroy
      redirect_to :action => 'edit', :id => @model_id
    else
      redirect_to :action => 'index'
    end
  end

  def bulk_set_stock
    if params[:out_of_stock]
      params[:out_of_stock].each do |id, value|
        if OutOfStock.exists?(id)
          @out_of_stock = OutOfStock.find(id)
          
          # - When an out of stock is destroyed, unflag all ordered products which are in back order for this model, color and size
          OrderedProduct.update_all("in_back_order = 0", "model_id = #{@out_of_stock.model_id} AND color_id = #{@out_of_stock.color_id} AND model_size_id = #{@out_of_stock.model_size_id}")
          
          @out_of_stock.destroy
        end
      end
    end
    redirect_to request.referer
  end

  def update_fabric_style
    params[:style].each do |id,value|
      localized_fabric_style = LocalizedFabricStyle.find(id)
      localized_fabric_style.update_attribute("style", value)
    end
  end

  def delete_fabric_style
    @fabric_style = FabricStyle.find(params[:id])
    @fabric_style.lc.each {|lc| lc.destroy }
    @fabric_style.destroy
  end

  def add_default_model_size
    begin
      @size_type = SizeType.find(params[:size_type_id]) 
      @model_sizes = @size_type.default_model_sizes
      @default_locale = Locale.find_by_locale("en-CA")
      @locales=@model_sizes.empty? ? [@default_locale] : @model_sizes.first.localized_model_sizes.map{|lms|lms.locale}

      model_size = ModelSize.create({:is_default => true, :size_type_id => params[:size_type_id]})

      @locales.each do |locale|
        localized_model_size = LocalizedModelSize.new
        localized_model_size.model_size_id = model_size.id
        localized_model_size.locale_id = locale.id 
        localized_model_size.update_attributes(params[:localized_model_size])
        localized_model_size.save
      end

      flash[:notice]="Model Size created successfuly"
      redirect_to :action => 'default_model_sizes', :size_type_id => params[:size_type_id] 
    rescue
      flash[:notice]="An error occured creating new model size"
      redirect_to :action => 'default_model_sizes', :size_type_id => params[:size_type_id] 
    end
  end

  def add_size_type
    @size_type = SizeType.create(params[:size_type])
    @size_type.save
    redirect_to :action => 'default_model_sizes', :size_type_id => @size_type.id 
  end

  def add_default_model_size_locale
    @size_type = SizeType.find(params[:size_type_id])
    @locale = Locale.find(params[:locale])
    @default_locale = Locale.find_by_locale("en-CA")
    flash[:notice]="Localized sizes added"
    @size_type.default_model_sizes.each do |model_size|
      new_locale_size = model_size.localized_model_sizes.find_by_locale_id(@default_locale.id).clone
      new_locale_size.locale = @locale
      new_locale_size.save
    end
    redirect_to :action => 'default_model_sizes', :size_type_id => params[:size_type_id] 
  end
  
  def add_model_size_locale
    @model = Model.find(params[:id])
    @locale = Locale.find(params[:locale])
    @default_locale = Locale.find_by_locale("en-CA")
    flash[:notice]="Localized sizes added"
    @model.model_sizes.each do |model_size|
      new_locale_size = model_size.localized_model_sizes.find_by_locale_id(@default_locale.id).clone
      new_locale_size.locale = @locale
      new_locale_size.save
    end
    redirect_to :action => 'edit_model_sizes',  :id => @model.id
  end

  def add_fabric_style
    @model = Model.find(params[:id])
    @fabric_style = FabricStyle.create({:model_id => @model.id})
    params[:style].each do |id,value|
      LocalizedFabricStyle.create({:fabric_style_id => @fabric_style.id, 
                                  :language_id => id,
                                  :style => value})
    end
  end
  
  def update
    @mymodel = Model.find(params[:id])
    user_id = @mymodel.user_id
    if @mymodel.update_attributes(params[:mymodel])
      if @mymodel.user
        @vip_model_spec=VipModelSpecification.find_or_create_by_user_id_and_model_id(@mymodel.user_id,@mymodel.id)
        @vip_model_spec.update_attributes(params[:vip_model_specification]) if params[:vip_model_specification]
        if ![1,2].include?(@vip_model_spec.designs_per_zone)
          flash[:notice]="designs per zone must be 1 or 2"
          @vip_model_spec.update_attribute("designs_per_zone",2)
          populate_dropdowns
          redirect_to :action => 'edit', :id => params[:id]
          return
        end 
      elsif user_id && @mymodel.vip_model_specifications.exists?(:user_id => user_id) 
        @mymodel.vip_model_specifications.find_by_user_id(user_id).destroy
      end
      for model_size in @mymodel.model_sizes
        model_size.active = params[:model_size][:active].include?(model_size.id.to_s)
        model_size.save
      end
		  for l in @mymodel.localized_models
        l.name = params["localized_name_#{l.language.id}"]
        l.nickname = params["localized_nickname_#{l.language.id}"]
        l.seo_name = params["localized_seo_name_#{l.language.id}"]
        l.description= params["localized_description_#{l.language.id}"]
        l.model_info_upload = params["localized_model_info_#{l.language.id}"]
        l.warning_text= params["localized_warning_#{l.language.id}"]

        l.create_meta_title = params["localized_create_meta_title_#{l.language.id}"]
        l.create_meta_description = params["localized_create_meta_description_#{l.language.id}"]
        l.create_meta_keywords = params["localized_create_meta_keywords_#{l.language.id}"]
        l.create_h1 = params["localized_create_h1_#{l.language.id}"]
        l.create_desc = params["localized_create_desc_#{l.language.id}"]
        l.save
      end   	

	begin
	      #Update Zones
	      @front = Model.find(params[:id]).model_zones.find_by_zone_type(1)
	      @front.update_attributes(params[:front])
	      
	      if params[:back]
		@back = Model.find(params[:id]).model_zones.find_by_zone_type(2)
		@back.update_attributes(params[:back]) 
	      end
	      
	      if params[:left]
		@left = Model.find(params[:id]).model_zones.find_by_zone_type(3)
		@left.update_attributes(params[:left])
	      end
	      
	      if params[:right]
		@right = Model.find(params[:id]).model_zones.find_by_zone_type(4) 
		@right.update_attributes(params[:right])
	      end
	rescue
	end

      #EO Update Zones
      flash[:notice] = t(:admin_flash_updated)
      @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
      redirect_to :action => 'list'
    else
      populate_dropdowns
      render :action => 'edit', :id => params[:id]
    end
  end

  def update_model_sizes
    flash[:notice]="Model sizes updated"
    params[:model_size].each do |id, values|
      logger.debug "[+] UPDATE: #{id}"
      model_size = ModelSize.find(id)
      model_size.update_attributes(values)
    end
    params[:localized_model_size].each do |id, values|
      localized_model_size = LocalizedModelSize.find(id)
      localized_model_size.update_attributes(values)
    end
    if params[:size_type_id]
      redirect_to :action => 'default_model_sizes', :size_type_id => params[:size_type_id]
    else
      redirect_to :action => 'edit_model_sizes', :id => params[:id]
    end
  end

  def update_order
    if params[:model]
      params[:model].each do |id,value|
        model = Model.find(id)
        model.update_attribute("sort_order",value)
      end
    end
    puts params[:model].to_yaml

    redirect_to request.referrer
  end

  def destroy
    Model.find(params[:id]).destroy
    @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
    redirect_to :action => 'list'
  end

  def destroy_localized_sizes
    @locale = Locale.find(params[:locale_id])

    if @locale.locale != "en-CA"
      if params[:size_type_id]
        @size_type = SizeType.find(params[:size_type_id])
        @size_type.default_model_sizes.each do |model_size|
          model_size.localized_model_sizes.find_by_locale_id(params[:locale_id]).destroy
        end
        flash[:notice]="Localized sizes deleted"
        redirect_to :action => 'default_model_sizes', :size_type_id => params[:size_type_id]
      else
        @model = Model.find(params[:id])
        @model.model_sizes.each do |model_size|
          model_size.localized_model_sizes.find_by_locale_id(params[:locale_id]).destroy
        end
        flash[:notice]="Localized sizes deleted"
        redirect_to :action => 'edit_model_sizes', :id => params[:id]
      end
    end
  end

  def destroy_model_size
    ModelSize.find(params[:id]).update_attribute('active', false)
    redirect_to :action => 'default_model_sizes', :size_type_id => params[:size_type_id]
  end
  
   def active
    @active = Model.find(params[:id])
    if @active.active
      @active.update_attributes(:active => 0)      
    elsif !@active.active
      @active.update_attributes(:active => 1) 
    end
    @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
    redirect_to :action => 'list'
  end    

  def nodiscount
    @nodiscount = Model.find(params[:id])
    if @nodiscount.nodiscount
      @nodiscount.update_attributes(:nodiscount => 0)      
    elsif !@nodiscount.nodiscount
      @nodiscount.update_attributes(:nodiscount => 1) 
    end
    @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
    redirect_to :action => 'list'
  end
  
  def top_product
   @model = Model.find(params[:id])
   (@model.top_product == true) ? @model.update_attributes(:top_product => false ) : @model.update_attributes(:top_product => true)
    @users = User.find_all_by_is_vip(true).map{|u|[u.username, u.id]}
   redirect_to :action => 'list', :page => params[:page] ? params[:page] : 1
  end   

  def create_model_specification
    @model_color = ModelSpecification.new()
    @model_color.set_default_prices()
    @model_color.color_id = (params[:model_specification][:color_id])
    @model_color.attributes = (params[:model_specification])

    if @model_color.save
      @mymodel = Model.find(params[:id])
      @ModelSpecification = ModelSpecification.find_all_by_model_id(params[:id])
      @Colors = Color.find_all_by_color_type_id(3).map {|c| [c.localized_colors[0].name, c.id]}	
      flash[:notice] = t(:admin_flash_created)
      check_zones(@model_color)
      redirect_to :action => 'edit', :id =>@mymodel.id
    else
      @mymodel = Model.find(params[:id])
      @ModelSpecification = ModelSpecification.find_all_by_model_id(params[:id])
      @Colors = Color.find_all_by_color_type_id(3).map {|c| [c.localized_colors[0].name, c.id]}
      redirect_to :action => 'edit', :id =>@mymodel.id
    end
  end

  def update_model_specification

    @model_color = ModelSpecification.find(params[:model_specification][:id])
    
    @model_color.check_deactivation_model

    @model_color.attributes = params[:model_specification]

    if @model_color.save
      check_zones(@model_color)
      flash[:notice] = t(:admin_flash_created)
      redirect_to :action => 'edit', :id => @model_color.model_id
    else
      redirect_to :action => 'edit_model_specification', :id => @model_color.id
    end
  end
  
  def check_zones(spec)
    if !spec.img_front.nil? && !spec.img_front.empty? &&
      !ModelZone.exists?({:model_id => spec.model_id, :zone_type => 1})
      spec.model.model_zones << ModelZone.create({:zone_type => 1})
    end
    if !spec.img_back.nil? && !spec.img_back.empty? &&
      !ModelZone.exists?({:model_id => spec.model_id, :zone_type => 2})
      spec.model.model_zones << ModelZone.create({:zone_type => 2})
    end
    if !spec.img_left.nil? && !spec.img_left.empty? &&
      !ModelZone.exists?({:model_id => spec.model_id, :zone_type => 3})
      spec.model.model_zones << ModelZone.create({:zone_type => 3})
    end

    if !spec.img_right.nil? && !spec.img_right.empty? &&
       !ModelZone.exists?({:model_id => spec.model_id, :zone_type => 4})
      spec.model.model_zones << ModelZone.create({:zone_type => 4})
    end
    clean_zones(spec.model_id)
  end

  def clean_zones(model_id)
    begin
      model = Model.find(model_id)
      if !model.model_specifications.exists?(["img_front <> ''"]) &&
         model.model_zones.exists?({:zone_type => 1})
        model.model_zones.find_by_zone_type(1).destroy
      end
      if !model.model_specifications.exists?(["img_back <> ''"]) &&
         model.model_zones.exists?({:zone_type => 2})
        model.model_zones.find_by_zone_type(2).destroy
      end
      
      if !model.model_specifications.exists?(["img_left <> ''"]) &&
         model.model_zones.exists?({:zone_type => 3})
        model.model_zones.find_by_zone_type(3).destroy
      end

      if !model.model_specifications.exists?(["img_right <> ''"]) &&
         model.model_zones.exists?({:zone_type => 4})
        model.model_zones.find_by_zone_type(4).destroy
      end
    rescue
    end
  end
  
  def destroy_model_specification
    
    spec = ModelSpecification.find(params[:id])

    @model_id = spec.model_id

    spec.check_deactivation_model

    spec.destroy
  
    clean_zones(@model_id)
    
    redirect_to :action => 'edit', :id =>@model_id
  end

  def preview_images
    @ms = ModelSpecification.find(params[:id])
	render :layout => false
  end

  def mass_color_updates
    @specifications = ModelSpecification.paginate(:conditions=>"model_id > 1258", :page => params[:page], :per_page => 50, :order => "id DESC")
  end

  def update_mass_colors


    quotes = params["model_specifications"]["id"]
  quotes.each do |quote_id,quote_attrs|
    quote = ModelSpecification.find(quote_id)
    quote.update_attributes(quote_attrs)

          #render :text=>quote_attrs.inspect
      #return
  end


    redirect_to :back


  end


  private

	def validate_garment_stock_form
		# check for model
		Model.find(params[:garment_stock][:model_id]).id
		
		# check color
		Color.find(params[:garment_stock][:color_id]).id

		# check size
		ModelSize.find(params[:garment_stock][:model_size_id]).id
		
		# qty
		if params[:garment_stock][:quantity].to_i <= 0
			raise "quantity error"
		end
	end
  
  def populate_dropdowns
    @users = User.find(:all, :conditions => {:is_vip => true}, :order => 'username').map{|u|[u.username, u.id]}
    @categories = Category.find_all_by_category_type_id(2).map {|c| [c.local_name(session[:language_id]), c.id]}
    @brand = Category.find_all_by_category_type_id(4).map {|f| [f.local_name(session[:language_id]), f.id]}
    @garment_types = Category.find_all_by_category_type_id(CategoryType.find_by_name("Garment Type").id).map {|f| [f.local_name(session[:language_id]), f.id]}
    @regions = Region.find(:all).map {|r| [r.name, r.id]}
    @size_types = SizeType.all.map{|size_type|[size_type.name, size_type.id]}
    if @mymodel
      @available_sizes = @mymodel.model_sizes.find_all_by_active(true).map{|size|[size.local_name(I18n.locale), size.id]}
      @available_colors = @mymodel.colors.sort{|x,y| x.local_name(session[:language_id])<=>y.local_name(session[:language_id])}
      @available_colors.map!{|c|[c.local_name(session[:language_id]), c.id]}
    end
  end
end
