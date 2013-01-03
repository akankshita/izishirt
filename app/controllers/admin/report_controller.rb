class Admin::ReportController < Administration
  before_filter :get_regions, :only => [:index, :all_profit, :profit,:bulk_profit, :all_cost, :cost, :bulk_cost, :zone]
  before_filter :prepare_params, :only => [:index, :profit, :all_profit, :bulk_profit, :all_cost, :cost, :bulk_cost, :zone, :sellers]

  def index
    render :action => :all_profit
  end

  delegate :number_to_currency_custom, :to => 'ActionController::Base.helpers'
  def generate_csv

    list_id = params[:orders]

    orders = Order.find(:all, :conditions => "id IN (#{list_id.join(',')})")
    file = File.open("lib/csv/report-"+Time.now.to_s+".csv", "w")
    file.write("Order,Created On,Month,Total Price,Shipping,Tax,Label,Status,Name,Type,Authcode,Code,Country,Address,Town,Zip,Firstname,Lastname")
    orders.each do |order|
      file.write("#{order.id},#{order.created_at},#{number_to_currency_custom(order.total_price, {:currency=>order.currency.label})},#{number_to_currency_custom(order.total_shipping, {:currency=>order.currency.label})},#{number_to_currency_custom(order.total_taxes, {:currency=>order.currency.label})},#{order.currency.label},#{order.user.firstname + " " + order.user.lastname if order.user},#{order.payment_transaction ? 'Credit Card' : (order.paypal_transaction ? "Paypal" : "")},#{order.payment_transaction ? order.payment_transaction : (order.paypal_transaction ? order.paypal_transaction : "")},#{order.billing.province.code if order.billing && order.billing.province},#{order.billing && order.billing.country ? order.billing.country.name : order.billing.country_name if order.billing},#{order.billing.address1 if order.billing},#{order.billing.town if order.billing},#{order.billing.zip if order.billing},#{order.user.firstname if order.user},#{order.user.lastname if order.user}\n")
    end
    file.close
    
    send_file("lib/csv/report-"+Time.now.to_s+".csv")

  end

	def blank_margin
		begin
			@type = params[:type]
		rescue
		end

		if ! @type || @type == ""
			@type = "current"
		end

		cond_shipped = ""

		if @type == "shipped"
			cond_shipped += " AND orders.status = #{SHIPPING_TYPE_SHIPPED} "
		else
			cond_shipped += " AND orders.status <> #{SHIPPING_TYPE_SHIPPED} "
		end

		@orders = Order.paginate(:conditions => ["orders.confirmed = 1 AND orders.status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) #{cond_shipped} AND NOT EXISTS(SELECT * FROM ordered_products op, models " +
			"WHERE op.model_id = models.id AND op.order_id = orders.id AND op.is_extra_garment = 0 AND op.coupon_id <= 0 AND models.model_category <> 'blank') " +
			" AND EXISTS(SELECT * FROM ordered_products op WHERE op.order_id = orders.id AND op.is_extra_garment = 0 AND op.coupon_id <= 0)"], :page => params[:page], :per_page => 50, :order => "orders.id DESC")
	end

  def all_profit
    if @end.nil?
      @end = @start
    end

    @count_img = Image.count(:all, :conditions=>["created_on between '#{@start} 00:00:00' and '#{@end} 23:59:59'"]) if @start && @end
    @count_img = "" if @count_img.nil?

 

    if request.post? 
      where = ["confirmed = ? and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@purchase_source_cond} #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond} #{@referer_cond} #{@affiliate_cond}",
                true, 
                @start,
                @end]

      @orders = Order.find(:all, 
        :conditions => where, 
        :include => [:billing], :order=>"orders.created_at desc,orders.id desc")

      create_money_hashs

	begin
		@nb_boutiques_opened = Store.nb_stores_opened(@start, @end)
	rescue
		@nb_boutiques_opened = 0
	end

	begin
		@nb_active_stores = Store.nb_active_stores
	rescue
		@nb_active_stores = 0
	end

	begin
		@ratio_active_boutiques = Store.ratio_active_vs_stores
	rescue
		@ratio_active_boutiques = 0.0
	end

	begin
		@ratio_active_boutiques_with_something = Store.ratio_active_vs_stores_with_something
	rescue
		@ratio_active_boutiques_with_something = 0.0
	end

      @nb_products_with_print = 0
      @nb_products_without_print = 0

      @orders.map do |order|
        currency = order.currency.label
        # Good for bulk and non-bulk:
        @sub_total[currency]   += order.subtotal
        @tax_total[currency]   += order.total_taxes
        @grand_total[currency] += order.total_price if order.total_price
        @ship_total[currency]  += order.total_shipping

	@nb_products_with_print += order.nb_tshirts_with_prints.to_i
	@nb_products_without_print += order.nb_tshirts_without_prints.to_i
      end
    end

    if request.xml_http_request?
      render :partial => "all_profit_report"
    else 
      render :action => :all_profit
    end
  end

	def shipping_costs

		if ! params[:search]
			params[:search] = {}
		end

		begin
			if params[:search_start]
				params[:search][:start] = params[:search_start]
			end			


			params[:search][:start] = params[:search][:start].to_date
		rescue
			params[:search][:start] = Date.today - 1
		end

		begin
			if params[:search_end]
				params[:search][:end] = params[:search_end]
			end			

			params[:search][:end] = params[:search][:end].to_date
		rescue
			params[:search][:end] = Date.current
		end

		@order_type = params[:order_type]

		cond_order_type = ""

		if @order_type == "online"
			cond_order_type = " (orders.coupon_code IS NULL OR orders.coupon_code <> 'bulk') AND "
		elsif @order_type == "offline"
			cond_order_type = " orders.coupon_code IS NOT NULL AND orders.coupon_code = 'bulk' AND "
		end

		@shipping_histories = OrderShippingHistory.paginate(:conditions => [" #{cond_order_type} order_shipping_histories.state IN ('shipped', 'mail_sent') AND CAST(order_shipping_histories.created_at AS DATE) BETWEEN '#{params[:search][:start]}' AND '#{params[:search][:end]}'"], :include => [:order], :page => params[:page], :per_page => 100, :order => "order_shipping_histories.real_shipping_cost DESC")
	end

	def sellers_summary

		if ! params[:search]
			params[:search] = {}
		end

		begin
			if params[:search_start]
				params[:search][:start] = params[:search_start]
			end			


			params[:search][:start] = params[:search][:start].to_date
		rescue
			params[:search][:start] = Date.today
		end

		begin
			if params[:search_end]
				params[:search][:end] = params[:search_end]
			end			

			params[:search][:end] = params[:search][:end].to_date
		rescue
			params[:search][:end] = Date.current
		end

		@start_date = params[:search][:start]
		@end_date = params[:search][:end]

		@begin_month = @start_date.beginning_of_month
		@end_month = @start_date.end_of_month
		@begin_week = @start_date.beginning_of_week
		@end_week = @start_date.end_of_week

		@sellers = User.find_all_by_active_and_user_level_id(true, UserLevel.find_by_name("Izishirt Seller").id)
	end

	def garment_costs

		if ! params[:search]
			params[:search] = {}
		end

		begin
			if params[:search_start]
				params[:search][:start] = params[:search_start]
			end			


			params[:search][:start] = params[:search][:start].to_date
		rescue
			params[:search][:start] = Date.today - 1
		end

		begin
			if params[:search_end]
				params[:search][:end] = params[:search_end]
			end			

			params[:search][:end] = params[:search][:end].to_date
		rescue
			params[:search][:end] = Date.current
		end

		@order_type = params[:order_type]

		cond_order_type = ""

		if @order_type == "online"
			cond_order_type = " (orders.coupon_code IS NULL OR orders.coupon_code <> 'bulk') AND "
		elsif @order_type == "offline"
			cond_order_type = " orders.coupon_code IS NOT NULL AND orders.coupon_code = 'bulk' AND "
		end

		@garment_histories = Order.paginate(:conditions => [" #{cond_order_type} CAST(orders.created_on AS DATE) BETWEEN '#{params[:search][:start]}' AND '#{params[:search][:end]}' AND orders.confirmed = 1 AND orders.status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT})"], :page => params[:page], :per_page => 100, :order => "(SELECT SUM(ordered_products.quantity) FROM ordered_products WHERE ordered_products.order_id = orders.id) DESC")
	end

	def ink_costs
		if ! params[:search]
			params[:search] = {}
		end

		begin
			if params[:search_start]
				params[:search][:start] = params[:search_start]
			end			


			params[:search][:start] = params[:search][:start].to_date
		rescue
			params[:search][:start] = Date.today - 1
		end

		begin
			if params[:search_end]
				params[:search][:end] = params[:search_end]
			end			

			params[:search][:end] = params[:search][:end].to_date
		rescue
			params[:search][:end] = Date.current
		end

		@order_type = params[:order_type]

		cond_order_type = ""

		if @order_type == "online"
			cond_order_type = " (orders.coupon_code IS NULL OR orders.coupon_code <> 'bulk') AND "
		elsif @order_type == "offline"
			cond_order_type = " orders.coupon_code IS NOT NULL AND orders.coupon_code = 'bulk' AND "
		end

		@ink_histories = PrinterStatistic.paginate(:page => params[:page], :per_page => 100, :conditions => [" #{cond_order_type} CAST(printer_statistics.created_at AS DATE) BETWEEN '#{params[:search][:start]}' AND '#{params[:search][:end]}' AND nb_prints > 0"], :include => [:printer_shift, {:ordered_product => :order}], :order => "(SELECT stats.amount * printer_statistics.nb_prints FROM accounting_variables v, accounting_stats stats WHERE v.name = 'encre' AND v.user_id = printer_shifts.printer AND stats.accounting_variable_id = v.id AND stats.date_stat = CAST(printer_statistics.created_at AS DATE)) DESC")
	end

	def ink_costs_izishirt_ordered
		if ! params[:search]
			params[:search] = {}
		end

		begin
			if params[:search_start]
				params[:search][:start] = params[:search_start]
			end			


			params[:search][:start] = params[:search][:start].to_date
		rescue
			params[:search][:start] = Date.today - 1
		end

		begin
			if params[:search_end]
				params[:search][:end] = params[:search_end]
			end			

			params[:search][:end] = params[:search][:end].to_date
		rescue
			params[:search][:end] = Date.current
		end

		@order_type = params[:order_type]

		cond_order_type = ""

		if @order_type == "online"
			cond_order_type = " (orders.coupon_code IS NULL OR orders.coupon_code <> 'bulk') AND "
		elsif @order_type == "offline"
			cond_order_type = " orders.coupon_code IS NOT NULL AND orders.coupon_code = 'bulk' AND "
		end

		@ink_histories = OrderedProduct.paginate(:page => params[:page], :per_page => 100, :conditions => [" #{cond_order_type} orders.created_on BETWEEN '#{params[:search][:start]}' AND '#{params[:search][:end]}'"], :order => "(SELECT stats.amount * ordered_products.quantity FROM accounting_variables v, accounting_stats stats WHERE v.name = 'encre' AND v.user_id = ordered_products.printer AND stats.accounting_variable_id = v.id AND stats.date_stat = orders.created_on) DESC", :include => [:order])
	end

  def profit
    if request.post? 
      
      cond_payment_type = ""
      
      if @payment_type == "paypal"
        cond_payment_type = " AND orders.paypal_transaction IS NOT NULL"
      elsif @payment_type == "credit_card"
        cond_payment_type = " AND orders.paypal_transaction IS NULL"
      end
      
      where = ["confirmed = true and users.id <> 70 AND users.user_level_id <> #{UserLevel.find_by_name("Izishirt Seller").id} and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@purchase_source_cond} #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond} #{cond_payment_type} #{@referer_cond}",
                @start,
                @end]

      @orders = Order.find(:all, 
        :conditions => where, 
        :include => [:billing, :user], :order=>"orders.created_at desc,orders.id desc")
      

      create_money_hashs

      @nb_products_with_print = 0
      @nb_products_without_print = 0

      @orders.map do |order|
        currency = order.currency.label
        @sub_total[currency]   += order.subtotal
        @tax_total[currency]   += order.total_taxes
        @grand_total[currency] += order.total_price
        @ship_total[currency]  += order.total_shipping

        @nb_products_with_print += order.nb_tshirts_with_prints
        @nb_products_without_print += order.nb_tshirts_without_prints
        
        if ! order.paypal_transaction.nil?
          @paypal_total[currency] += order.total_price
        else
          @credit_card_total[currency] += order.total_price
        end
      end
    end

    if request.xml_http_request?
      render :partial => "profit_report"
    else 
      render :action => :profit
    end
  end

  def bulk_profit
    if request.post? 
      where = ["confirmed = true and (users.id = 70 OR users.user_level_id = #{UserLevel.find_by_name("Izishirt Seller").id}) and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond}",
                @start,
                @end]

      @orders = Order.find(:all, 
        :conditions => where, 
        :include => [:billing, :user], :order=>"orders.created_at desc,orders.id desc")

      create_money_hashs
      @orders.map do |order|
        currency = order.currency.label

        if ! order
          next
        end

        @sub_total[currency]   += order.subtotal if order.subtotal
        @tax_total[currency]   += order.total_taxes if order.total_taxes
        @grand_total[currency] += order.total_price if order.total_price

        @ship_total[currency]  += order.shipping_cost if order.shipping_cost
      end
    end

    if request.xml_http_request?
      render :partial => "bulk_profit_report"   
    else 
      render :action => :bulk_profit  
    end
  end
  
  def sellers
    if request.post? 
      where = ["confirmed = ? and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@printer_cond}  ",
                true, 
                @start,
                @end]

      tmp_orders = Order.find(:all, 
        :conditions => where, 
        :include => [:billing], :order=>"orders.created_at desc,orders.id desc")
      

      @nb_products_with_print = 0
      @nb_products_without_print = 0
      
      @orders = []
      
      tmp_orders.each do |order|
        # offline -> bulk order
        if @sale_type == "offline"
          if ! order.bulk_order?
            next
          end
          
          begin
            if @seller != 0 && @seller && order.user_id != @seller && order.bulk_seller_id != @seller
              next
            end
          rescue
            next
          end
        elsif @sale_type == "online"
          # online -> order.online_seller
          if @seller != 0 && order.online_seller != @seller
            next
          end
        elsif @sale_type == "all"
          if ! (@seller == order.online_seller || order.user_id == @seller || order.bulk_seller_id == @seller)
            next
          end
        end

        @orders << order
      end
      create_money_hashs
      @orders.map do |order|
        currency = order.currency.label
        
        @sub_total[currency]   += order.subtotal if order.subtotal
        @tax_total[currency]   += order.total_taxes if order.total_taxes
        @grand_total[currency] += order.total_price if order.total_price
        @ship_total[currency]  += order.total_shipping if order.total_shipping
        
        @nb_products_with_print += order.nb_tshirts_with_prints
        @nb_products_without_print += order.nb_tshirts_without_prints
      end
    end

    if request.xml_http_request?
      render :partial => "sellers_report"
    else 
      render :action => :sellers
    end
  end

  def all_cost
    if request.post? 
      @orders = Order.find(:all, 
        :conditions => ["confirmed = true and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond}", @start, @end],
        :include => [:billing], :order=>"orders.created_at desc,orders.id desc")

      @model_count = 0
      @print_count = 0

      @model_cost  = 0.0
      @model       = 0.0
      @print_cost  = 0.0
      @print       = 0.0
      @total_cost  = 0.0
      @revenue     = 0.0
      @shipping_cost = 0.0

      @orders.each do |order|

        @model_count    += order.count_models
        @print_count    += order.count_zones

        # For non-bulk:
        if ! order.bulk_order?
          #Cost
          @model       = order.cost_price
          @print       = order.total_print_cost
          @total_cost  += @model + @print
          @model_cost  += @model
          @print_cost  += @print

          #Revenue
          @revenue += order.total_price
        else

	begin
          @model_cost     += order.garment_cost
	rescue
	end

	begin
          @print_cost     += order.print_cost
	rescue
	end

	begin
          @shipping_cost  += order.shipping_cost
	rescue
	end

	begin
          @total_cost+= order.production_cost
	rescue
	end

          #Revenue
          @revenue += order.total_price
        end
        
      end
    end
      

    if request.xml_http_request?
      render :partial => "all_cost_report"
    else
      render :action => :all_cost
    end
  end

  def cost
    if request.post? 
      @orders = Order.find(:all, 
        :conditions => ["confirmed = true and users.id <> 70 AND users.user_level_id <> #{UserLevel.find_by_name("Izishirt Seller").id} and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond}", @start, @end],
        :include => [:billing, :user], :order=>"orders.created_at desc,orders.id desc")

      @model_count = 0
      @print_count = 0

      @model_cost  = 0.0
      @model       = 0.0
      @print_cost  = 0.0
      @print       = 0.0
      @total_cost  = 0.0
      @revenue     = 0.0

      @orders.each do |order|
        #Cost
        @model_count += order.count_models
        @print_count += order.count_zones
        @model       = order.cost_price 
        @print       = order.total_print_cost
        @total_cost  += @model + @print
        @model_cost  += @model
        @print_cost  += @print

        #Revenue
        @revenue += order.total_price
      end
    end
      

    if request.xml_http_request?
      render :partial => "cost_report"  
    else
      render :action => :cost
    end
  end

  def bulk_cost
    if request.post? 
      @orders = Order.find(:all, 
        :conditions => ["confirmed = true and (users.id = 70 OR users.user_level_id = #{UserLevel.find_by_name("Izishirt Seller").id}) and status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_AWAITING_PAYMENT}) and created_on between ? and ? #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond}", @start, @end],
        :include => [:billing, :user], :order=>"orders.created_at desc,orders.id desc")

      @model_count     = 0
      @print_count     = 0
      @model_cost      = 0.0
      @print_cost      = 0.0
      @shipping_cost   = 0.0
      @production_cost = 0.0
      @revenue         = 0.0

      @orders.each do |order|
        #Cost
        @model_count    += order.count_models.to_i
        @print_count    += order.count_zones.to_i
        @model_cost     += order.garment_cost.to_f
        @print_cost     += order.print_cost.to_f 
        @shipping_cost  += order.shipping_cost.to_f
        @production_cost+= order.production_cost.to_f

        #Revenue
        @revenue += order.total_price.to_f
      end
    end

    if request.xml_http_request?
      render :partial => "bulk_cost_report"  
    else
      render :action => :bulk_cost
    end


  end

  def image
    params[:search] ? @search_term = params[:search] : @search_term = 'some_text_to_give_no_results'
    where = [ "(fast_tags.name like :search_term)", { :search_term => '%' + @search_term + '%' } ]
    @image_pages, @images = paginate :images, :per_page => 100, :conditions => where, :include => [:fast_tag_images => :fast_tag], :order => 'created_on desc'
    @images.each do |image|
      image.write_attribute('orders', Order.find_by_sql("select distinct ordered_products.order_id from ordered_products, ordered_zones, ordered_zone_artworks artwork WHERE ordered_products.id = ordered_zones.ordered_product_id and ordered_zones.id = artwork.ordered_zone_id AND artwork.image_id = #{image.id}"))
      image.write_attribute('profits', Order.find_by_sql("select distinct orders.id, orders.total_price as profit from orders join ordered_products on orders.id = ordered_products.order_id join ordered_zones on ordered_products.id = ordered_zones.ordered_product_id JOIN ordered_zone_artworks ON ordered_zone_artworks.ordered_zone_id = ordered_zones.id and ordered_zone_artworks.image_id = #{image.id}")).map!{ |i| i.profit.to_f }
      image.profits == [] ? image.profits = 0 : image.profits = image.profits.inject{|sum, n| sum + n}   
    end
  end

  def zone
    if request.post? 
      @zones = []
      @orders = Order.find(:all, 
        :conditions => ["confirmed = true and created_on between ? and ? #{@printer_cond} #{@prov_cond} #{@country_cond} #{@prov_name_cond} #{@country_name_cond}",
          @start, @end], 
        :include => [:ordered_products => {:ordered_zones => :ordered_txt_lines} ], :order=>"orders.created_at desc,orders.id desc" )

          
      @front = 0
      @back  = 0

      @orders.map do |order|
        front_items = 0
        back_items = 0
        order.ordered_products.each do |prod|
          prod.ordered_zones.each do |zone|
            if (zone.contains_artwork_or_text ) && zone.zone_type == 1
              front_items += 1
            end
            if (zone.contains_artwork_or_text ) && zone.zone_type == 2
              back_items += 1
            end  
          end
        end
        order.write_attribute(:front_items, front_items)
        order.write_attribute(:back_items, back_items)
        order.write_attribute(:total, order.front_items + order.back_items)

        @front += order.front_items 
        @back  += order.back_items
      end
      @total = @front + @back


      render :partial => "zone_report" 
    end
  end

  
  

  private
  
  

	

  def prepare_params
    if request.post? 
      @start         = params[:profit][:start] != "" ? params[:profit][:start] : 100.year.ago.to_date
      @end           = params[:profit][:end]   != "" ? params[:profit][:end]   : Time.now.to_date+1.days

      @printer      = params[:profit][:printer].to_i
      @only_affiliates = params[:profit][:affiliate_id] if params[:profit][:affiliate_id]
      @province      = params[:profit][:province]
      @province_name = params[:profit][:province_name]
      @country       = params[:profit][:country]
      @country_name  = params[:profit][:country_name]
      @payment_type  = params[:profit][:payment_type]
      
      
      @seller = params[:seller].to_i
      @sale_type = params[:sale_type]

      @purchase_source_cond = ""
      
      if params[:profit][:purchase_source] && params[:profit][:purchase_source].to_i > 0
        @purchase_source_cond += " AND EXISTS (SELECT * FROM ordered_products p WHERE p.order_id = orders.id AND p.purchase_source_id IS NOT NULL AND p.purchase_source_id = #{params[:profit][:purchase_source]})"
      end
      
      if params[:profit][:referer] && params[:profit][:referer] != "*"
        @referer_cond = "and referer_id = #{params[:profit][:referer]}"
      else
        @referer_cond = ""
      end

      begin

        @printer_cond = @printer > 0 ? " AND orders.printer = #{@printer}" : ""

        #Get Province by id or name
        @prov_cond    = @province != "All" ?  " and (addresses.province_id = #{@province} or addresses.province_name = '#{Province.find(@province).name}')" : ""
        @country_cond = @country  != "All" ?  " and (addresses.country_id = #{@country} or addresses.country_name = '#{Country.find(@country).name}')" : ""
        @affiliate_cond = @only_affiliates ? " AND affiliate_id IS NOT NULL" : ""
        @prov_name_cond    = @province_name != "" ? " and (addresses.province_name = '#{@province_name}' or addresses.province_id = #{Province.find_by_name(@province_name).id})" : ""
        @country_name_cond = @country_name  != "" ? " and (addresses.country_name = '#{@country_name}' or addresses.country_id = #{Country.find_by_name(@country_name).id})" : ""


      rescue
      end
    end
    
    @sale_types = [["All", "all"], ["Online", "online"], ["Offline", "offline"]]
    @sellers = generate_options_tags_for_bulk_orders_seller()
    @purchase_sources = generate_options_tags_for_purchase_sources()
    @printers = [["All", 0]] | generate_options_tags_for_printers()
  end

  def get_regions
    @countries = Country.find(:all).map {|country| [country.name, country.id]}
    @provinces = Province.find(:all).map {|province| [province.name, province.id]} 
    @referers  = Referer.all.map{|referer|[referer.url, referer.id]} 
    @countries = ["All"] + @countries
    @provinces = ["All"] + @provinces
    @referers  = [["All","*"]] + @referers
  end

  def create_money_hashs
      all_currencies = Currency.find(:all)

      @sub_total = Hash.new
      @tax_total = Hash.new
      @grand_total = Hash.new
      @ship_total = Hash.new
      @paypal_total = Hash.new
      @credit_card_total = Hash.new
      for currency in all_currencies
        @sub_total[currency.label] = 0.0
        @tax_total[currency.label] = 0.0
        @grand_total[currency.label] = 0.0
        @ship_total[currency.label] = 0.0
        @paypal_total[currency.label] = 0.0
        @credit_card_total[currency.label] = 0.0
      end
  end

end
