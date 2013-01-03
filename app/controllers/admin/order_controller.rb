class Admin::OrderController < Administration

  def index
    list
    render :action => 'list'
  end
  

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :update ],
    :redirect_to => { :action => :list }

	def notify_ready_for_pick_up
		order = Order.find(params[:id])

		if SendMail.deliver_notify_ready_for_pick_up(order)
			flash[:info] = "Pick up email successfully sent."
		else
			flash[:error] = "Problem while sending the pick up email."
		end

		redirect_to :back
	end

	def send_shipping_po_box_notification
		order = Order.find(params[:id])

		if SendMail.deliver_notify_shipping_po_box(order)
			flash[:info] = "Shipping PO Box notification email sent."
		else
			flash[:error] = "Problem while sending the PO Box notification email."
		end

		redirect_to :back
	end

	def orders_raw_data
		
	end

	def bulk_orders_summary

		begin
			@machine = params[:machine].to_i
		rescue Exception => e
			@machine = 0
		end

		filter_conditions = ""

		if @machine > 0
			filter_conditions += " AND (orders.printer = #{@machine} OR EXISTS(SELECT * FROM ordered_products op WHERE op.order_id = orders.id AND op.printer = #{@machine})) "
		end

		order_by = " orders.requested_shipping_on IS NOT NULL DESC, orders.requested_shipping_on ASC "

		if params[:order]
			order_by = params[:order]
		end

		@printers = generate_options_tags_for_printers()
		@orders = Order.paginate(:per_page => 50, :page => params[:page], :conditions => ["coupon_code = 'bulk' AND confirmed = 1 AND " +
			" status NOT IN (#{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_CANCELED_COUPON})  " +
			" #{filter_conditions} "], :order => order_by)
	end

	######################################################################################################
	## BEGIN shipping
	##
	def ship_step_1
		@order = Order.find(params[:id])

		if params[:address]
			@order.shipping.address1 = params[:address][:address1]
			@order.shipping.address2 = params[:address][:address2]
			@order.shipping.town = params[:address][:city]
			@order.shipping.zip = params[:address][:zip]
			@order.shipping.country_id = params[:address][:country_id]
			@order.shipping.province_id = params[:address][:province_id]
			@order.shipping.phone = params[:address][:phone]
			@order.shipping.name = params[:address][:name]
		end

		@package_weight = (params[:package_weight]) ? params[:package_weight] : @order.total_lbs_weight
		@nb_packages = (params[:nb_packages]) ? params[:nb_packages] : 1
		@package_type = params[:package_type]
	end

	def ship_validate_step_1
		@order = Order.find(params[:id])

		begin
			province_code = Province.find(params[:address][:province_id]).code
		rescue
			province_code = ""
		end


		@request_confirm = UpsShipConfirmRequest.new(params[:address][:address1], params[:address][:address2], 
			params[:address][:city], params[:address][:zip], Country.find(params[:address][:country_id]).shortname, province_code, 
			params[:address][:name], params[:address][:phone], 
			params[:service], params[:nb_packages].to_i, params[:package_weight], params[:package_type], @order.id)

		@request_confirm.execute

		if ! @request_confirm.valid_response?
			flash[:error] = @request_confirm.result_description

			redirect_to :params => params.merge({:action => "ship_step_1", :id => @order.id})
			return
		end
	end

	def ship_accept
		@order = Order.find(params[:id])

		old_status = @order.status

		@request_accept = UpsShipAcceptRequest.new(params[:digest])

		@request_accept.execute

		if ! @request_accept.valid_response?
			flash[:error] = @request_accept.result_description

			redirect_to :params => params.merge({:action => "ship_step_1", :id => @order.id})
			return
		end

		# create history
		# OrderHistory.create(:order_id => @order.id, :attribute => "status", :from_value => @order.status, :to_value => params[:status], :user_id => session[:user_id])

		@order.update_attributes(:tracking_number => @request_accept.tracking_number, :real_shipping_cost => @order.real_shipping_cost + @request_accept.total_cost, :status => params[:status])

		begin
			Order.set_to_shipped(@order, true) if (old_status != SHIPPING_TYPE_SHIPPED) && (params[:status] == "#{SHIPPING_TYPE_SHIPPED}")
		rescue
		end

		render :layout => false
	end

	##
	## BEGIN shipping
	######################################################################################################

	def change_cartridge
		begin
			machine = params[:cartridge_machine]
			printer = params[:cartridge_printer]

			cartridge_infos = params[machine]

			h = CartridgeHistory.create(cartridge_infos)
			h.machine_user_id = User.find_by_username(machine).id
			h.printer_user_id = printer
			h.save
			flash[:info] = "Cartridge history added"
		rescue Exception => e
			flash[:error] = "Cartridge history error -> #{e}"
		end
		
		redirect_to :back
	end

	######################################################################################################
	## BEGIN Order Calendar
	##

	def calendar

		@printers = generate_options_tags_for_printers()
		cond_printer = ""

		begin
			@selected_printer = params[:printer].to_i
			
			if @selected_printer > 0
				cond_printer = " AND (printer = #{@selected_printer} OR EXISTS(SELECT * FROM ordered_products op WHERE op.order_id = orders.id AND op.printer = #{@selected_printer})) "
			end
		rescue
			@selected_printer = 0
		end


		begin
			@selected_status = params[:status].to_i

			if params[:status] == nil
				@selected_status = SHIPPING_TYPE_PROCESSING
			end
		rescue
			@selected_status = SHIPPING_TYPE_PROCESSING
		end

		cond_status = @selected_status != 0 ? " AND status = #{@selected_status} " : ""

		@orders = Order.find(:all, :conditions => ["status NOT IN (#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_PACKAGING}, #{SHIPPING_TYPE_PRINTED}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_TO_CHECK}) AND confirmed = 1 #{cond_printer} #{cond_status}"])

		render :layout => false
	end

	##
	## END Order Calendar
	######################################################################################################


  ######################################################################################################
  ## BEGIN Printer assignment process
  ##
  def printer_assignment_process
    orders = Order.find(:all, :conditions => condition_orders_in_printer_assignment_process(), :order => "orders.id ASC")
    
    selected_order = orders.length > 0 ? orders[0] : nil
    
    if params[:last_order_id]
      last = params[:last_order_id].to_i
      
      orders.each do |tmp_order|
        if tmp_order.id > last
          selected_order = tmp_order
          break
        end
      end
    end
    
    @order = selected_order
    #@order = Order.find(4385)

    if ! @order.nil?
      @image_decline_reasons = populate_select_design_decline_reasons(@order.user.language_id)
      
      user_izishirt = User.find_by_username("izishirt")
      
      @printers = [["No printer", 0], [user_izishirt.username, user_izishirt.id]]
      @printers += User.find_all_by_user_level_id(5, :select => "id, username").map{|p| [p.username, p.id]}
    end
  end
  
  def save_printer_assignment
    if params[:custom] && params[:custom][:action] == "skip"
      redirect_to :action => "printer_assignment_process", :last_order_id => params[:id]
      return
    end
        
    # Parameters: {"commit"=>"Sauvegarder et passer au suivant", "id"=>"4301", 
    # "order"=>{"printer"=>"2610"}, "internal_comment"=>{"comment"=>""}}
    @order = Order.find(params[:id])
    
    # Check if there is any out of stock. If yes, set in_back_order
    @order.set_back_order_to_out_of_stock_products()
    
    if params[:order] && params[:order][:printer].to_i > 0
      @order.printer = params[:order][:printer].to_i
      @order.save
    end

    # check out the ordered products
    @order.ordered_products.each do |prod|
      if ! prod.active
        next
      end

      if params["ordered_product_#{prod.id}"] && params["ordered_product_#{prod.id}"][:in_izishirt_stock] && params["ordered_product_#{prod.id}"][:in_izishirt_stock] == "true"
        # get izishirt supplier:
        begin
          prod.garments_ordered = true
          prod.garments_ordered_on = Date.today()
          prod.do_not_order_automatically = true
          prod.save
        rescue
        end
      end

	if params["ordered_product_#{prod.id}"] && params["ordered_product_#{prod.id}"][:printer]
		prod.update_attributes(:printer => params["ordered_product_#{prod.id}"][:printer])
	end
    end
    
    save_comments()
    
    update_image_decline(@order)
    
    redirect_to :action => "printer_assignment_process", :last_order_id => params[:id]
  end
 
  ## 
  ## END Printer assignment process
  ###################################################################################################### 

	################################################################################################
	# INVOICES
	#
	# regenerate invoice
	def view_invoice
		regen_invoice

		send_file @pdf_to_load.path, :type => "application/pdf", :disposition => 'attachment', :filename => "#{File.basename(@pdf_to_load.path)}"
	end

	def regen_invoice
		@order = Order.find(params[:id])

		calculator = @order.main_quote_calculator
		
		invoice_type = params[:invoice_type]

		# destroy alllllLLLL invoices of that type
		calculator.quote_calculation_invoices.each do |invoice|
			if invoice.type_str == invoice_type
				invoice.destroy
			end
		end

		payment_comment = @order.amount_paid >= @order.total_price ? "PAID IN FULL" : ""
		shipping_comment = ""
		terms = nil

		# Now regenerate it
		prepare_generate_quote_pdf(calculator.id, @order.shipping_cost, shipping_comment, payment_comment, 0.0, invoice_type, 0, nil, terms, false)
	end

	def invoice

		order = Order.find(params[:id])
		@order = order

		# begin
			order_to_string = render_to_string :controller => "/checkout2", :action => "generate_invoice_html", :id => order.id, :layout => false
			f = File.open(order.tmp_invoice("html"), 'w')
			f.write(order_to_string)
			f.close

			order.invoice_html = File.new(order.tmp_invoice("html"))

			order.save

			# PDF
			system("wkhtmltopdf #{order.tmp_invoice("html")} #{order.tmp_invoice("pdf")}")

			order.invoice_pdf = File.new(order.tmp_invoice("pdf"))
			
			order.save

			send_file order.invoice_pdf.path, :type => "application/pdf", :disposition => 'attachment', :filename => "#{File.basename(order.invoice_pdf.path)}"
		# rescue
		# end
	end

	def send_invoice
		regen_invoice

		if params[:invoice_type] == "invoice"
			begin
				SendMail.deliver_bulk_order_invoice(@invoice)
			rescue
				flash[:error] = "Error while sending invoice."
				redirect_to :back
				return
			end
		end

		if params[:invoice_type] == "invoice_comptability"
			begin
				SendMail.deliver_bulk_order_invoice_comptability(@invoice)
			rescue => ex
				flash[:error] = "Error while sending invoice comptability."
				redirect_to :back
				return
			end
		end

		flash[:info] = "Invoice sent."

		redirect_to :back
	end

	#
	# END INVOICES
	################################################################################################

	################################################################################################
	# PRINTER STATS
	#
	def add_printer_statistics
		@ordered_product = OrderedProduct.find(params[:ordered_product_id])

		begin
			shift = PrinterShift.find(params[:printer_shift_id])
			shift_id = shift.id
		rescue
			shift_id = 0
		end
		

		begin
			extra_missed = params[:extra_missed].to_i
		rescue
			extra_missed = 0
		end

		if shift && ! shift.finished_at.nil? && extra_missed <= 0
			flash[:error] = "This shift is finished. Please log in and start your shift (if required)."
			redirect_to :action => "show", :id => @order_product.order.id
			return
		end
		
		begin
			nb_missed = params[:nb_missed].to_i
		rescue
			nb_missed = 0
		end

		begin
			pretreatment = params[:pretreatment].to_i
		rescue
			pretreatment = 0
		end

		if extra_missed > 0
			nb_missed = extra_missed
		end

		# Put to reproduction if there are some missed.
		if nb_missed > 0
			begin
				@ordered_product.order.update_attributes(:is_reproduction => true)
			rescue
			end
		end

		begin
			nb_printed = params[:nb_printed].to_i
		rescue
			nb_printed = 0
		end

		begin
			nb_prints = params[:nb_prints].to_i
		rescue
			nb_prints = 0
		end

		if nb_printed > 0 && nb_prints == 0
			# we must find the number of prints
			nb_prints = nb_printed * @ordered_product.nb_prints_per_shirt
		end

		if (nb_printed > 0 || nb_missed > 0 || nb_prints > 0 || pretreatment > 0) && @ordered_product
			PrinterStatistic.create(:printer_shift_id => shift_id, :ordered_product_id => @ordered_product.id, :nb_printed => nb_printed, :nb_missed => nb_missed, :nb_prints => nb_prints, :pretreatment => pretreatment)
		end

		render :layout => false
	end

	def delete_printer_statistic

		@ordered_product = OrderedProduct.find(params[:ordered_product_id])

		begin
			stat = PrinterStatistic.find(params[:stat_id])
			

			stat.destroy
		rescue
		end

		render :layout => false
	end
	#
	# PRINTER STATS
	################################################################################################


	def save_order_payment
		exec_save_order_payment(params[:id])

		render :text => ""
	end

	def delete_order_payment
		exec_delete_order_payment(params[:order_payment_id])

		redirect_to :back
	end

  def send_again_confirmation_order_email
    order = Order.find(params[:id])
	@order = order

	generate_invoice(order)
    
    if order
      if SendMail.deliver_confirm_order_user(order)
        flash[:info] = "Confirmation email sent."
      else
        flash[:error] = "Error while sending the confirmation email."
      end
    end
    
    redirect_to :back
  end

	def do_not_order_automatically

		@order = Order.find(params[:id])
		new_value = params[:do_not_order_automatically_new_value] == "1"

		flash[:error] = ""

		@order.ordered_products.each do |prod|

			if prod.coupon
				next
			end

			begin
				prod.update_attributes(:do_not_order_automatically => new_value)
			rescue => e
				flash[:error] += "Error updating ordered product #{prod.id} => #{e}"
			end
		end

		flash[:info] = "Modifications saved successfully."

		redirect_to :back
	end


  def cancel_and_refund_with_coupon
	order = Order.find(params[:id])
	coupon_reason_type = CouponReasonType.find(params[:cancel_reason])

	if coupon_reason_type.str_id == "custom_coupon_deluxe"
		redirect_to :controller => "/admin/coupon", :action => "new", :order_id => order.id
		return
	end

	old_status = order.status	


    if order 

	# check out the products to be canceled
	products_to_cancel = []

	order.ordered_products.each do |product|

		if params["ordered_product_#{product.id}_cancel_with_coupon"] == "1"
			products_to_cancel << product
		end
	end

	# dont add the extra amount SEVERAL TIMES
	already_gave_refund = false
	original_total_price = order.total_price
	extra_amount = coupon_reason_type.extra_amount

	begin
		if order.coupon_code && order.coupon_code != ""
			c = Coupon.find_by_code(order.coupon_code)
		else
			c = nil
		end

		if c && c.coupon_reason_type
			original_total_price = order.total_price - c.coupon_reason_type.extra_amount + c.currency_off
			extra_amount = 0.0
		end
	rescue
	end

	coupon_amount = order.total_price + extra_amount

	cancel_order_completely = products_to_cancel.length == 0 || products_to_cancel.length == order.ordered_products.length

	if ! cancel_order_completely
		coupon_amount = 0.0

		products_to_cancel.each do |product|
			# add price to coupon
			coupon_amount += product.price * product.quantity

			# desactivate product in the current
			product.update_attributes(:active => false)
		end

		coupon_amount += extra_amount
	end

	r = Digest::MD5.hexdigest(Time.current.to_s + order.id.to_s)[0..10]

	coupon_code = "#{order.id}_#{r}"

      new_coupon = Coupon.create(:code => coupon_code, :percent_off => 0, :currency_off => coupon_amount, :total_allowed => 1, :total_given => 0, :start_date => Date.today, :end_date => Date.today + 1000, :active => true, :for_refund => true, :comment => "auto-generated coupon for refund order #{order.id}", :no_shipping => false, :apply_to_boutique_products => true, :also_apply_to_shipping => true, :coupon_reason_type_id => coupon_reason_type.id)

	if cancel_order_completely
	      if new_coupon.errors.length == 0 && SendMail.deliver_refund_with_a_coupon(new_coupon, order)

		if ! [SHIPPING_TYPE_SHIPPED, SHIPPING_TYPE_PARTIALLY_SHIPPED].include?(old_status)
			order.update_attributes(:status => SHIPPING_TYPE_CANCELED_COUPON)
		end

		flash[:info] = "A coupon code has been sent to the client."

		order.ordered_products.each do |prod|
			prod.update_attributes(:coupon_code => coupon_code)
		end

	      else
		flash[:error] = "Error, no coupon code has been sent [code 1]., errors = #{new_coupon.errors.length}, coupon = #{coupon_code}"

		new_coupon.errors.each do |f, msg|
			flash[:error] += ", #{f} - #{msg}"
		end
	      end
	else # sub order

		products_to_cancel.each do |prod|
			prod.update_attributes(:coupon_code => coupon_code)
		end

	      if SendMail.deliver_refund_with_a_coupon_create_sub_order(new_coupon, order, products_to_cancel)
		flash[:info] = "A coupon code has been sent to the client."
	      else
		flash[:error] = "Error, no coupon code has been sent [code 2]."
	      end
	end
    else
      flash[:error] = "Error, no coupon code has been sent [code 3]."
    end

	redirect_to :back
  end

  def send_back_order_email
	order = Order.find(params[:id])

	if SendMail.deliver_back_order_email(order)
		flash[:info] = "A back order email was sent."
	else
		flash[:error] = "Error while sending the back order email."
	end

	redirect_to :back
  end
  
  def make_as_bulk
    order = Order.find(params[:id])
    
    if order
      order.update_attributes(:coupon_code => "bulk")
    end
    
    flash[:info] = "Order has been set as a bulk."
    
    redirect_to :back
  end
  
  def remove_as_bulk
    order = Order.find(params[:id])
    
    if order
      order.update_attributes(:coupon_code => "")
    end
    
    flash[:info] = "Order has been unset as a bulk."
    
    redirect_to :back
  end

  def populate_for_list

    if params[:printer]
      session["order_printer"] = params[:printer]
    end

    @printer = User.find_by_username(session["order_printer"])
    @printer_id = @printer ? @printer.id : 0

    if ! @printer
      session["order_printer"] = nil
    end

    user_izishirt = User.find_by_username("izishirt")
    @printers = [["No printer", 0], [user_izishirt.username, user_izishirt.id]]
    User.find_all_by_user_level_id(5).each {|printer| @printers << [printer.username,printer.id]}
  end

  def list(id = nil)
    populate_for_list

    execute_order_list(id)
  end
  
  

  def refresh_for_model
    prod = OrderedProduct.find(params[:id])
    
    selected_model_id = params["ordered_product_#{prod.id}_model_id"]
    selected_model_other = params["ordered_product_#{prod.id}_model_other"]

    new_model = Model.find(selected_model_id) if selected_model_id
    
    prepare_new_order_show(params[:init], selected_model_id, selected_model_other, prod.order, prod.color_id, prod.model_size_id)
    
    model_modified = params[:model_modified] == "true"

    render :update do |page|
        page.replace_html "product_#{prod.id}_color_block", :partial => '/admin/order/select_color', :locals => { :prod => prod, :model_modified => model_modified }
        page.replace_html "product_#{prod.id}_size_block", :partial => '/admin/order/select_size', :locals => { :prod => prod, :model_modified => model_modified, :new_model => new_model}
    end
  end

	def confirm_order
		begin
			order = Order.find(params[:id])

			order.update_attributes(:confirmed => true)
			flash[:info] = "Order #{order.id} confirmed"
		rescue Exception => e
			flash[:error] = "Order not confirmed"
		end

		redirect_to :back
	end

	def ship
		@order = Order.find(params[:id])
	end

	def exec_ship
		@order = Order.find(params[:id])

		# TODOOOOOOOOO, ADD TRACKING NUMBER FROM UPS
		tracking_number = ""
		# TODOOOOOOOO END.

		ship_history = nil

		params["product"].each do |product_id, product_infos|
			begin
				if product_infos["checked"] == "true"
					qty = product_infos["quantity"].to_i

					if qty > 0
						if ! ship_history
							ship_history = OrderShippingHistory.create(:order_id => @order.id, :user_id => @user.id, :tracking_number => tracking_number)
						end

						OrderedProductShippingHistory.create(:order_shipping_history_id => ship_history.id, :ordered_product_id => product_id, :quantity => qty)
					end
				end
			rescue Exception => e
				logger.error("ERRRRRRRRRRR #{e}")
			end
		end

		redirect_to :action => "show", :id => @order.id
	end

  def show 
    session[:order_show_type] = "order"
    prepare_order_show()
    
    prepare_new_order_show("true", nil, nil, @order, nil, nil)
  end

  def history
    @order_histories = OrderHistory.find_all_by_order_id(params[:id], :order => 'id desc')
    @email_histories = OrderEmailHistory.find_all_by_order_id(params[:id], :order => "id DESC")

    @assignments = []
  end

  def search
    populate_for_list
    
    execute_search_order()

    render :action => "list"
  end

  def print
    prepare_for_order_print()

    render :layout => false
  end 

  def custom
    @order = Order.new()
    @order.language_id=1
    @order.user_id=1406
    @order.total_price=0.00
    @order.curency_id=1
	
    @order.user.firstname=''
    @order.user.lastname=''
    @order.user.email=''
	
    @printers = [["Izishirt", 0]]
    @printers += User.find_all_by_user_level_id(5, :select => "id, username").map{|p| [p.username, p.id]}
	
    @languages = [['English', 0],['French',1]]
  end  
  
  
  def custom_save
    @order = Order.new()
	
    @adr = Address.new()
    @adr.name =  params[:shipping][:name]
    @adr.address1 = params[:shipping][:address1]
    @adr.province_name = params[:shipping][:province_name]
    @adr.country_name = params[:shipping][:country_name]
    @adr.phone = params[:shipping][:phone]
    @adr.town = params[:shipping][:town]
    @adr.zip = params[:shipping][:zip]
    @adr.save
	
    @order.shipping_address = @adr.id;
    @order.billing_address = @adr.id;
	
    @user = User.find_by_username('izishirt')
    @order.user_id = @user.id
    @order.curency_id = 1
    @order.custom_order=true
    shiptype = params[:order][:shipping_type]
    shiptype = (shiptype == '-1') ? nil : shiptype;
	
    #save order to create new order id.
    @order.update_attributes( :status => params[:order][:status],
      :printer => params[:order][:printer],
      :tracking_number => params[:order][:tracking_number],
      :rush_order => params[:order][:rush_order],
      :xmas => params[:order][:xmas],
      :critical => params[:order][:critical],
      :artwork_sent => params[:order][:artwork_sent],
      :total_price => params[:order][:total_price],
      :signature_required => params[:order][:signature_required],
      :shipping_type => shiptype,
      :language_id =>params[:order][:language_id])

    Admin::OrderController.set_check_assigned_on(@order, false, @order.assigned, "")

    if params[:image]
      @file_img_design = params[:image]['uploaded_img_design1']
      if(@file_img_design != nil &&  @file_img_design != '')
        file_dir = CUSTOM_ORDER_PATH
        name=  '/file1.'+@file_img_design.original_filename.split(".").last
        FileUtils.mkdir_p(File.join(file_dir, @order.id.to_s))
        File.open(File.join(file_dir, @order.id.to_s, name),'wb') do |file|
          file.puts @file_img_design.read
        end
      end
      @file_img_design = params[:image]['uploaded_img_design2']
      if(@file_img_design != nil &&  @file_img_design != '')
        file_dir = CUSTOM_ORDER_PATH
        name=  '/file2.'+@file_img_design.original_filename.split(".").last
        FileUtils.mkdir_p(File.join(file_dir, @order.id.to_s))
        File.open(File.join(file_dir, @order.id.to_s, name),'wb') do |file|
          file.puts @file_img_design.read
        end
      end
    end
	
    redirect_to :action => 'list', :id=>0
  end   

	def exec_comment
		@order = Order.find(params[:order_id])

		comment_type_str_id = params[:comment_type]
		comment_type = CommentType.find_by_str_id(comment_type_str_id)
		@comment_type = comment_type
		comment = params[:comment][comment_type_str_id]

		# check for comment:
		if comment != nil
			comment.strip!

			if comment != ""
				@comment = Comment.new
				@comment.user_id = session[:user_id]
				# set order.id  or  you'll never find comment <:'(
				@comment.order_id = @order.id
				@comment.comment = comment
				@comment.date_time = Time.now
				@comment.comment_type_id = comment_type.id
				@comment.save

				#comment_types are  0, 1, 2 for none, read, unread, 2 flags this comment unread
				@order.update_attributes(:comment_type => 2,:flagged_date => Time.now, :last_comment_posted_by => session[:user_id])
			end
		end

		# check the order by filterrr !
		begin
			session[:order_comments_sort_by_user_id] = params["sort_comments_by_#{comment_type_str_id}"].to_i
		rescue => e
			session[:order_comments_sort_by_user_id] = 0
		end

		@comments = @order.comments_per_comment_type(@comment_type.str_id, 1, session[:order_comments_per_page], session[:order_comments_sort_by_user_id])
		@all_comments = @order.comments_per_comment_type(@comment_type.str_id, 1, 1000000, session[:order_comments_sort_by_user_id], false)


		render :layout => false
	end

	def delete_comment
		comment = Comment.find(params[:comment_id])
		@order = Order.find(params[:order_id])

		if comment
			comment.update_attributes(:deleted => true)
		end

		@comment_type = CommentType.find_by_str_id(params[:comment_type])

		@comments = @order.comments_per_comment_type(@comment_type.str_id, 1, session[:order_comments_per_page], session[:order_comments_sort_by_user_id])
		@all_comments = @order.comments_per_comment_type(@comment_type.str_id, 1, 1000000, session[:order_comments_sort_by_user_id], false)
		
		render :action => "exec_comment", :layout => false
	end

	def list_comments
		@order = Order.find(params[:order_id])
		@comment_type = CommentType.find_by_str_id(params[:comment_type])

		@comments = @order.comments_per_comment_type(@comment_type.str_id, params[:page], session[:order_comments_per_page], session[:order_comments_sort_by_user_id])

	end   

  def send_tracking_number
    @tn = params[:tn]
    order = Order.find(params[:id])
    if @tn == ""
      render :update do |page|

      end
    else
      SendMail.deliver_admin_tracking_number(order,@tn)
      render :update do |page|
        page.replace_html "_feedback_mail_tracking_number", :text => ("Tracking number "+params[:tn]+" has been sent")
      end
    end
  end
  def update

	if params[:cancel_reason].to_i > 0
		cancel_and_refund_with_coupon()
		return
	end

    params[:page] = (params[:page] && params[:page] != "") ? params[:page].to_i : 1

    if params[:page] < 1
	params[:page] = 1
    end

    @order = Order.find(params[:id], :conditions => ["confirmed = true"])

	# PARTIALLY SHIP MAIL
	# partially_ship()

    old_status = @order.status

    @new = Order.new(params[:order])
    was_assigned = @order.assigned
    last_assigned_on = @order.assigned_on

    begin
      #keep a history of any changes
      
      field_for_history = params[:order]

      field_for_history.each do |attr,value|
        if @order[attr] != @new[attr] && attr != "print_file" && attr != "status"
          @order.order_histories << OrderHistory.create({:order_id => @order.id,
            :attribute => attr,
            :from_value => @order[attr].to_s,
            :to_value => value, :user_id => session[:user_id]})     
        end
      end
      @new.destroy
    rescue
    end

    @order.update_attributes(params[:order])
    
    flash[:error] = ""
    
    (1..params[:nb_comments].to_i).each do |cur_comment_ind|
      comment = params["new_comment"]["comment_#{cur_comment_ind}"]
      comment_type = params["comment_type_#{cur_comment_ind}"]
      
      if comment_type == "no_type" && comment && comment != ""
        flash[:error] += "Please select a comment type<br />"
        redirect_to :action => "show", :id => @order.id
        return
      end  
    end
    
    save_comments();
    
    # 'custom', 'new_created_on'
    
    begin
      if params[:custom][:new_created_on] && params[:custom][:new_created_on].to_date != @order.created_on
        @order.update_attributes(:created_on => params[:custom][:new_created_on].to_date, :created_at => params[:custom][:new_created_on])
      end
    rescue
    end
    
    if @order.errors.length > 0
      
      
      @order.errors.each do |attr, msg|
          flash[:error] += "#{msg}<br />"
      end
      
      redirect_to :action => "show", :id => @order.id
      return
    end

    @order.update_attributes(:status_changed_on => DateTime.now) if old_status.to_i != params[:order][:status].to_i
    @order.update_attributes(:packaged_on => Date.today) if old_status.to_i != params[:order][:status].to_i && params[:order][:status].to_i == SHIPPING_TYPE_PACKAGING

    Admin::OrderController.set_check_assigned_on(@order, was_assigned, @order.assigned, last_assigned_on)
    check_ordered_product_active()
    
    # Check for the artwork state 
    check_change_artwork_state()

    begin
      if @order.bulk_order?
        @order.update_attribute('total_price', params[:order][:sales_price].to_f) 
        if params[:ordered_zones]
          params[:ordered_zones].each do |id,values|
            zone = OrderedZone.find(id).update_attributes(values)
          end
        end
      end
    rescue
    end

    # get all fields:
    # check for user check comments read
    if (params[:checkbox_read] != nil)
      user_flag_read = params[:checkbox_read][:read]
      if (user_flag_read != nil)
        #comment_types are  1, 2 for  admin read,  adnmin unread
        res = (user_flag_read == "1") ? 1 : 2;
        #@order.update_attributes(:comment_type => res)
        @order.user_change_comments_state(session[:user_id], res)
      end
    end	

    #Update shipping date if status set to shipped
    Order.set_to_shipped(@order, false) if (old_status != SHIPPING_TYPE_SHIPPED) && (params[:order][:status]=="#{SHIPPING_TYPE_SHIPPED}") && @order.tracking_number != "" && @order.tracking_number
    Order.set_to_other_status_from_shipped(@order, old_status, params[:order][:status])
    @order.cancel if params[:order][:status] == "5"
    

    # Check for image rejected modifications:

    flash[:notice] = ""
    update_image_decline(@order)
    
    # Redirection

	contrl_to_redirect = (session[:order_show_type] == "artwork") ? "artwork" : "order"

	new_page = params[:page].to_i

	if params[:save_goto_previous]
		if new_page > 1
			new_page = new_page - 1
		end

		redirect_to :controller => contrl_to_redirect, :action => "show", :id => @order.id, :page => new_page
		return
	elsif params[:save_goto_next]
		new_page = new_page + 1

		redirect_to :controller => contrl_to_redirect, :action => "show", :id => @order.id, :page => new_page
		return
	end

    
    if session[:order_show_type] == "artwork"
      artwork_action = session[:last_action] ? session[:last_action] : "index"
      
      redirect_to :controller => "artwork", :action => artwork_action
    else
      redirect_to :action => 'list', :id => session[:current_order_listing]
    end
  end
  
  def update_listing
    #rails routing 1.2 does not allow '.' in url params
    begin
      params[:paid_amount]["_"]= '.'
      params[:track]["_"]= '.'
    rescue
    end
    
    #rails routing 1.2 does not allow blank url params eg http://www.izishirt.com/123//tracking_num/
    # so pass an empty string in the url, and then remove in the action
    params[:track] = '' if (params[:track] == ' ')
    
    order = Order.find(params[:id])
    order.update_attribute(:tracking_number,params[:track]) if params[:track]
    order.update_attribute(:paid_amount, params[:paid_amount]) if params[:paid_amount]
    order.update_attribute(:paid, params[:paid]) if params[:paid]
    redirect_to :action => 'list', :id => session[:current_order_listing] 
  end

  def update_address
    order = Order.find(params[:order])
    attribute = params[:attribute]
    params[:type] == "shipping" ? address = order.shipping : address = order.billing
    if address.nil? 
      address = Address.new 
      params[:type] == "shipping" ? order.shipping = address : order.billing = address
      order.save
    elsif order.shipping == order.billing
      address = order.shipping.clone
      address.save
      params[:type] == "shipping" ? order.update_attribute(:shipping, address) : order.update_attribute(:billing, address) 
    end

    if attribute == "country"
      attribute += "_name" 
      address.update_attribute(:country,nil)
    end

    if attribute == "province"
      attribute += "_name"
      address.update_attribute(:province,nil)
    end

    address.update_attribute(attribute, params[:val])
    render :text => address[attribute]
  end

  def bulk_update
    action = params[:id]
    case action
    when "set_to_pending"
      attribute = :status
      value = 0
    when "set_to_processing"
      attribute = :status
      value = 1
    when "set_to_shipped"
      attribute = :status
      value = 2
    when "set_to_batching"
      attribute = :status
      value = 3
    when "set_to_canceled"
      attribute = :status
      value = 5
    when "set_to_awaiting_stock"
      attribute = :status
      value = 4
    when "set_to_nextshirt"
      attribute = :printer
      value = 2610
    when "set_artwork_sent"
      attribute = :artwork_sent
      value = 1
    when "set_rush_order"
      attribute = :rush_order
      value = 1
    when "set_to_packaging"
      attribute = :status
      value = SHIPPING_TYPE_PACKAGING
    when "set_to_on_hold"
      attribute = :status
      value = SHIPPING_TYPE_ON_HOLD
    when "set_to_art_on_hold"
      attribute = :status
      value = SHIPPING_TYPE_ARTWORK_ON_HOLD
    when "set_to_printed"
      attribute = :status
      value = SHIPPING_TYPE_PRINTED
    end

    if params[:order_checks] && attribute && value
      params[:order_checks].each do |id,check_value|
        order = Order.find(id)
        was_assigned = order.assigned
        last_assigned_on = order.assigned_on
        old_status = order.status
        order.update_attribute(attribute,value)
        Order.set_to_shipped(order, false) if attribute == :status && value == 2 && old_status != 2
        order.cancel if attribute == :status && value == 5

        
        
        Admin::OrderController.set_check_assigned_on(order, was_assigned, order.assigned, last_assigned_on)

        order.update_attributes(:status_changed_on => DateTime.now) if attribute == :status && old_status.to_i != value.to_i
        order.update_attributes(:packaged_on => Date.today) if old_status.to_i != value.to_i && value.to_i == SHIPPING_TYPE_PACKAGING

        Order.set_to_other_status_from_shipped(order, old_status, value.to_i) if attribute == :status
      end
    end
    redirect_to :action => :list, :id => session[:current_order_listing]
  end
 
  #def destroy
  #  Order.find(params[:id]).destroy
  #  redirect_to :action => 'list'
  #end

  # Check if the assigned rule has changed. If yes, update the assigned_on field and
  # create an history.
  def self.set_check_assigned_on(order, was_assigned, is_assigned, last_assigned_on)
    if ! was_assigned && is_assigned
      # Unassigned -> Assigned
      estimate_assigned_on = order.estimate_assigned_on()
      order.update_attribute('assigned_on', estimate_assigned_on)
      order.order_histories << OrderHistory.create({:order_id => order.id,
        :attribute => "assigned_on",
        :from_value => last_assigned_on.to_s,
        :to_value => estimate_assigned_on})
    elsif ! is_assigned && was_assigned
      # Assigned -> Unassigned
      order.update_attribute('assigned_on', nil)
      order.order_histories << OrderHistory.create({:order_id => order.id,
        :attribute => "assigned_on",
        :from_value => last_assigned_on.to_s,
        :to_value => ""})
   end
   
  end

  def send_email
    @order = Order.find(params[:id])

    if ! @order
      redirect_to :back
      return
    end

  end

  def exec_send_mail
    order_id = params[:order_email][:order_id]
    order = Order.find(order_id)
    subject = params[:order_email][:title] + " (Order ID #{order_id})"
    body = params[:order_email][:body]
    from_email = params[:order_email][:from_email]
    artwork_required_problem = params[:order_email][:artwork_required_problem]

    if artwork_required_problem.to_i == 1
      Order.update(order.id, :artwork_required_problem => 1)
    end

    if SendMail.deliver_send_order_email(order, from_email, subject, body)
      flash[:info] = t(:checkout_address_custom_email_client_success_send_mail) + " " + order.email_client
      
      OrderEmailHistory.create(:order_id => order_id, :user_id => session[:user_id], :sent_to => order.email_client, :subject => subject, :body => body, :passed_as_artwork_required_problem => artwork_required_problem.to_i)
      
      redirect_to :action => :show, :id => order.id
    else
      flash[:error] = t(:checkout_address_custom_email_client_error_send_mail)
      redirect_to :action => :send_email, :id => order.id
    end
  end

  def self.calculate_order_statistics(order)
    nb_tshirts = 0
    nb_artworks = 0

    order.ordered_products.each do |ordered_product|

      if ! ordered_product.active
        next
      end

      nb_tshirts += 1

      prod_for_zones = ordered_product

      if ordered_product.is_extra_garment
        prod_for_zones = OrderedProduct.find(ordered_product.ordered_product_id)
      end

      prod_for_zones.ordered_zones.each do |ordered_zone|
        if ordered_zone.contains_artwork_or_text()
          nb_artworks += 1
        end
      end
    end

    return nb_tshirts, nb_artworks
  end


  ########
  private
  ########

  # Connexplace Interaction
    
  def check_change_artwork_state()
    
    if ! flash[:error]
      flash[:error] = ""  
    end

    if ! (params[:artwork_assignment] && params[:artwork_assignment][:state] && params[:artwork_assignment][:state].to_i > 0)
      return true
    end

    if ArtworkOrderAssignmentState.find_all_by_id(params[:artwork_assignment][:state]).length == 1
      order = @order

      # Check if there is a printer:
      if params[:artwork_assignment][:state].to_i == ArtworkOrderAssignmentState.find_by_str_id("artworks_sent").id && order.printer == 0 # no printer !
        flash[:error] += t(:admin_artwork_dept_no_printer_selected) + order_id.to_s
        return false
      end
      
      if ArtworkOrderAssignment.find_all_by_order_id(order.id).length == 1
        assignment = ArtworkOrderAssignment.find_by_order_id(order.id)
        
        nb_problems = assignment.nb_problems
        
        if params[:artwork_assignment][:state].to_i == ArtworkOrderAssignmentState.find_by_str_id("artworks_problem").id
          nb_problems = nb_problems + 1
        end
          
        assignment.update_attributes(:artwork_order_assignment_state_id => params[:artwork_assignment][:state], :nb_problems => nb_problems)
        
        # is it artwork sent ?
        if params[:artwork_assignment][:state].to_i == ArtworkOrderAssignmentState.find_by_str_id("artworks_sent").id
          order.update_attributes(:artwork_sent => true)
        end
      end
    end
    
    return true
  end
  
  def save_comments()
    
    (1..params["nb_comments"].to_i).each do |ind_comment|
      comment_type = params["comment_type_#{ind_comment}"]
      comment = params[:new_comment]["comment_#{ind_comment}"]
      
      logger.error("nb comment = #{params["nb_comments"]}, comment type = #{comment_type}, comment = #{comment}")
      
      comment.strip!
      
      if comment && comment != ""
      
        if comment_type == "administrator" || comment_type == "administrator_internal"
          @comment = Comment.new
          @comment.user_id = session[:user_id]
          @comment.order_id = params[:id]
          @comment.comment = comment
          @comment.date_time = Time.now
          
          if comment_type == "administrator_internal"
            @comment.internal = true
          end
          
          @comment.save
          #comment_types are  0, 1, 2 for none, read, unread, 2 flags this comment unread
          @order.update_attributes(:comment_type => 2,:flagged_date => Time.now,:last_comment_posted_by => session[:user_id])
        elsif comment_type == "artwork"
          comment_created = OrderArtworkDepartmentComment.create(:order_id => @order.id, :staff_id => @connected_staff.id, :comment => comment, :artwork_order_assignment_state_id => 0)
        end
      end
    end
  end

  def check_shipping(status, shipping_type, tracking_number, shipping_company_id)

    # If rush order, the tracking number must be filled.
    if shipping_type.to_i == SHIPPING_RUSH && status.to_i == SHIPPING_TYPE_SHIPPED
      if ! tracking_number || tracking_number == ""
        flash[:notice] = t(:admin_shipping_missing_tracking_number)

        redirect_to :back

        return false
      end
    end

    # Check that a shipping company has been selected when a tracking number is entered.
    if tracking_number && tracking_number != "" && shipping_company_id.to_i == 1 ## 1 == N/A
      flash[:notice] = t(:admin_shipping_missing_shipping_company)

      redirect_to :back

      return false
    end

    return true
  end

  def update_image_decline(order)

    order.ordered_products.each do |ordered_product|


      ordered_product.ordered_zones.each do |ordered_zone|
        if ordered_zone && ordered_zone.contains_uploaded_image && ! ordered_zone.contains_image
          begin

            if ! params[:image]["pending_approval#{ordered_zone.id}"] || ! params[:image]["design_image_decline_reason_id#{ordered_zone.id}"] || ! params[:image]["decline_reason#{ordered_zone.id}"]
              next
            end

            new_pending_approval = params[:image]["pending_approval#{ordered_zone.id}"]
            old_pending_approval = ordered_zone.pending_approval
            new_decline_reason_id = params[:image]["design_image_decline_reason_id#{ordered_zone.id}"]
            new_decline_reason = params[:image]["decline_reason#{ordered_zone.id}"]

            # Change image status and notify it
            if new_pending_approval.to_i != ordered_zone.pending_approval
              ordered_zone.update_attributes(:pending_approval => new_pending_approval, :last_pending_approval => old_pending_approval, :design_image_decline_reason_id => new_decline_reason_id,
                :decline_reason => new_decline_reason)

              OrderedProduct.path_ordered_product(ordered_product.created_on)

              front_or_back = (ordered_zone.zone_type == 1) ? "front" : "back"
              path_preview = "/izishirtfiles/#{path_ordered_product(ordered_product.created_on)}/#{ordered_product.checksum}/#{ordered_product.checksum}-#{front_or_back}.jpg"

              if new_pending_approval.to_i != DESIGN_VALIDATION_STATE_APPROVED_ID

                if new_pending_approval.to_i == DESIGN_VALIDATION_STATE_DECLINED_ID
                  order.update_attributes(:status => SHIPPING_TYPE_ARTWORK_ON_HOLD)
                end

                image_pending_approval_changed(ordered_zone, false, order.email_client, order.user, path_preview, "contact@izishirt.com", order.id)
              end

              state_translations = Image.approval_states(session[:language])

              # Create history:
              order.order_histories << OrderHistory.create({:order_id => order.id,
                :attribute => "pending_approval uploaded image ID##{ordered_zone.id}",
                :from_value => state_translations[old_pending_approval.to_i],
                :to_value => state_translations[new_pending_approval.to_i]})
            end
          rescue
          end
        end
      end
    end
  end
  
  
 
end
