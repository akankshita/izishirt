namespace :mails do

	def apparel_supplier(op)
		return op.real_apparel_supplier
	end

	def order_product(ordered_products_to_order, suppliers_to_order, shipping_type, logger, blank_order = false)
	      # initialize the products per supplier
	      products_per_supplier = {}

	      suppliers_to_order.each do |supplier|
		products_per_supplier[supplier] = []
	      end

	      ordered_products_to_order.each do |op|
		if op.quantity > 0
			products_per_supplier[apparel_supplier(op)] << op
		end
	      end

	      listings = []

	      products_per_supplier.each do |supplier, products|

		if products && products.length > 0
		  # Expected date:
		  expected_date = DateUtil.next_business_days(Date.today, supplier.nb_days_to_ship)

		    supplier_printer = supplier

			printer_user_id = User.find_by_username("izishirt").id

		    # create the listing
		    listing = OrderGarmentListing.create(:apparel_supplier_id => supplier_printer.id, :date_expected => expected_date, :printer => printer_user_id)

		    # products of the current printer:
		    products.each do |op|

			op.quantity = op.initial_quantity
		      op.apparel_supplier_id = supplier_printer.id
		      op.expected_date = expected_date
		      op.order_garment_listing_id = listing.id
		      op.garments_ordered = true
		      op.garments_ordered_on = Time.now

		      OrderGarmentListingProduct.create(:order_garment_listing_id => listing.id, :order_id => op.order.id, :printer => printer_user_id,
			:model_id => op.model_id, :model_other => op.model_other, :color_id => op.color_id, :color_other => op.color_other,
			:model_size_id => op.model_size_id, :quantity => op.quantity, :ordered_product_id => op.id)

		      op.save
		    end

		    if listing.order_garment_listing_products.length > 0
		      listings << listing
		    else
		      listing.destroy
		    end
		end
	      end

	      if listings.length > 0

		listings.each do |listing|

		  email = listing.apparel_supplier.email

		  print "supplier email = #{email}\n"

		  if ! SendMail.deliver_automatic_supplier_email(listing, shipping_type, blank_order)
		    logger.error("Error_to_order_garments_request " + email)
		  else
		    logger.info("Delivered_to_order_garments_request " + email)
		  end

		  sleep 10
		end
	      end
	end

	# INPUT : orders, shipping_type
	# OUTPUT : ordered products to order, suppliers
	def collect_products_to_order(orders, shipping_type, is_blank=false)

		suppliers_to_order = []
		ordered_products_to_order = []

	      # extract the garments to order
	      orders.each do |order|

                # ordered_products_blank_to_order = []

		order.ordered_products.each do |product|
      #Listing blank, produit blank, rush order
      if is_blank && order.rush_order && product.is_blank
        next
      #Listing blank, produit custom
      elsif is_blank && !product.is_blank
        next
      #Listing custom, order normal, produit blank
      elsif !is_blank && product.is_blank && !order.rush_order
        next
      end

			product.initial_quantity = product.quantity

		  # Don't reorder

		  if product.garments_ordered || ! product.model || ! apparel_supplier(product) ||
			product.garment_in_stock_at_printer || product.do_not_order_automatically || ! product.active || product.coupon ||
			(shipping_type == "merged" && ! apparel_supplier(product).merge_order_types) ||
			(shipping_type != "merged" && apparel_supplier(product).merge_order_types)
		    next
		  end

      if RAILS_ENV == 'development'
        valid_supplier = apparel_supplier(product) && apparel_supplier(product).active
      else
        valid_supplier = apparel_supplier(product) && apparel_supplier(product).active && apparel_supplier(product).must_send_at?(ORDER_HOUR.to_i)
      end

		  if ! valid_supplier
		    next
		  end

		  ordered_products_to_order << product

		  if ! suppliers_to_order.include?(apparel_supplier(product)) && apparel_supplier(product)
		    suppliers_to_order << apparel_supplier(product)
		  end

		end
	      end

		return suppliers_to_order, ordered_products_to_order
	end

  task(:order_garments => :environment) do

    ORDER_HOUR = Time.current.hour

    # listing_izishirt_stocks = OrderGarmentListing.create(:apparel_supplier_id => ApparelSupplier.find_by_name("Izishirt Stock").id,
#					:date_expected => Date.today, :printer => User.find_by_username("izishirt").id)

	###############################################################################################
	# MISSED PRODUCTS CREATION
	# 

	missed_prod_stats = PrinterStatistic.find(:all, :conditions => ["reordered_missed = 0 AND nb_missed > 0"])

	missed_prod_stats.each do |missed_prod_stat|
		begin
			o_product = missed_prod_stat.ordered_product

			garment = o_product
			nb_to_reorder = missed_prod_stat.nb_missed

			extra_garment = OrderedProduct.new(:order_id => garment.order_id, :color_id => garment.color_id, :model_id => garment.model_id, 
				:model_size_id => garment.model_size_id, :quantity => nb_to_reorder, :cost_price => 0, :price => 0, :commission => 0, 
				:garments_reordered => 0, :print_cost_white => 0, :print_cost_white_xxl => 0, :print_cost_other => 0, :print_cost_other_xxl => 0, 
				:ordered_product_id => garment.id, :is_extra_garment => 1, :is_from_missed => true, :is_blank=>false)

			extra_garment.save!

			# update the order garment listing:
			if garment.garment_listing_product
				garment.garment_listing_product.update_attributes(:order_garment_state_id => OrderGarmentState.find_by_str_id("reordered").id)
			end

			garment.order.update_attributes(:status => SHIPPING_TYPE_AWAITING_STOCK)

			# OK, now change the stat to reordered missed
			missed_prod_stat.reordered_missed = true
			missed_prod_stat.save
		rescue
		end
	end

	# 
	# END, MISSED PRODUCTS CREATION
	###############################################################################################


		# we send two mails per supplier, one for the rush and another one for non rush


	    # ["rush_order", "normal", "merged"].each do |shipping_type|
	    ["normal", "merged"].each do |shipping_type|
	      # first extracts orders of yesterday
	      today = Date.today

	      # don't do orders during the weekend !
	      if [6,7].include?(today.cwday)
		next
	      end

	      # rush_condition = (shipping_type == "rush_order") ? "AND orders.rush_order = 1" : "AND orders.rush_order = 0"
	      rush_condition = "" # (shipping_type == "rush_order") ? "AND orders.rush_order = 1" : "AND orders.rush_order = 0"

		if shipping_type == "merged"
			rush_condition = ""
		end

	      yesterday_orders = Order.find(:all, :conditions =>
		  ["created_on <= '#{today}' AND confirmed = 1 #{rush_condition} AND status NOT IN (#{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_TO_CHECK}) AND " +
		  # printer assigned:
		  "printer > 0  " +
		  ""])

	      entry_logfile = File.open("#{RAILS_ROOT}/log/order_garments_#{Date.today}.log", 'a')
	      entry_logfile.sync = true
	      logger = CustomLogger.new(entry_logfile)

		######################################################################################
		# WALL DECALS
		wd_orders = []

		yesterday_orders.each do |order|
			if ! order.contains_fast_shipping_models
				next
			end

			wd_suppliers, wd_products = collect_products_to_order([order], shipping_type)

			tmp_wd_products = []

			wd_products.each do |p|
				if p.model.fast_shipping
					tmp_wd_products << p
				end
			end

			order_product(tmp_wd_products, wd_suppliers, shipping_type, logger, false)
		end
		# END WALL DECALS
		######################################################################################

		######################################################################################
		# BLANKS



		# CASE ONE ORDER FOR TECHNOSPORT
		blank_suppliers, blank_products = collect_products_to_order(yesterday_orders, shipping_type, true)


    #print "Blank product inspection #{blank_products.length}"

		order_product(blank_products, blank_suppliers, shipping_type, logger, true)

		# END BLANK
		######################################################################################

		######################################################################################
		# NON BLANKS
		non_blank_suppliers, non_blank_products = collect_products_to_order(yesterday_orders, shipping_type, false)

    #print "Custom product inspection #{non_blank_products.length}"  

		order_product(non_blank_products, non_blank_suppliers, shipping_type, logger)
		# END NON BLANKS
		######################################################################################
	    end
  end
end

