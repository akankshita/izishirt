class Checkout2Controller < ApplicationController

  # include ActiveMerchant::Billing::Integrations
  # include ActiveMerchant::Billing::Integrations::ActionViewHelper


  before_filter :set_environment, :except=>:verification_code
  before_filter :set_protocol, :only => [:show_cart, :show_brief_cart, :address, :payment, :confirmation]

  layout :set_layout

  def update_shipping_total
    shipping_type = params[:id];
    @cart         = get_cart
    @cart.set_shipping_type(shipping_type)
    @currency = session[:currency]
  end

  def verification_code
    render :layout => false
  end


  def show_brief_cart
    @cart = get_cart


    prepare_show_cart()
    order          = Order.find_or_create_by_id(@cart.order_id)
    @cart.order_id = order.id
  end

#  def set_referer
#    if request.referer && !request.referer.include?("www.izishirt.")
#      logger.debug("[+] REFERER: #{request.referer}")
#      cookies[:iframe_continue_link] = { :value=>!request.referer.nil? ? request.referer : '', :domain => ".#{@DOMAIN_NAME}"}
#      logger.debug("[+] SESSION REFERER: #{cookies[:iframe_continue_link]}")
#    end
#  end

  def show_cart
  prepare_show_cart()
  end

  def check_empty_cart
return false
    cart = get_cart

    if cart.empty?
      redirect_to :action => "show_cart"
      return true
    end

    return false
  end

  def to_step_two
    @cart          = get_cart
    @cart.comments = params[:comments]
    redirect_to params[:url]
  end


  def choose_login
    @cart = get_cart

    if params[:username] || params[:type] == 'guest'
      if session[:user_id].nil?
        if params[:type]=='guest'
          session[:guest_id] = User.get_guest_user.id
        else
          user = User.authenticate(params[:username], params[:password])
          session[:user_id] = user.id if user
        end
        if (session[:user_id].nil? && params[:type] != 'guest') || (session[:guest_id].nil? && params[:type] == 'guest')
          flash[:error] = t(:checkout_login_error)
          return
        end
        redirect_to :action       =>:address,
                    :onsite       => params[:onsite],
                    :iframe       => params[:iframe],
                    :flash_iframe => params[:flash_iframe],
                    :store_id     => params[:store_id]
        return
      end
    end

  end


  def refresh_shipping_options

    @country = Country.find(params[:country]).shortname
    if (@country == 'CA')
      @province = Province.find(params[:province]).code
    end
    @cart = get_cart

    if @cart.blank_order? && @cart.shipping(SHIPPING_BASIC, @country, @province, params[:town], params[:zip], params[:address1], params[:address2]) < 0
      render :text=>t(:warning_shipping_not_enough)
      return
    end

  end

  def shipping_options
    prepare_lang_stuff()

	begin
		@montreal_special_pick = PickUpStore.find(:first, :include => [:address], :conditions => "addresses.town LIKE 'Montreal' OR addresses.town LIKE 'Montréal'")
	rescue
		@montreal_special_pick = nil
	end

    begin
      country  = Country.find(params[:country])
      @country = country.shortname


      @cart = get_cart

      

      if (@country == 'CA' || @country == "US")
        province        = Province.find(params[:province])
        @province       = province.code

      elsif @country == "FR"
        @pick_up_stores = PickUpStore.find_all_by_active(1, :include=>[:address], :conditions=>"addresses.country_id=#{country.id}")
      end



      if @cart.blank_order? && @cart.shipping(SHIPPING_BASIC, @country, @province, params[:town], params[:zip], params[:address1], params[:address2]).to_i < 0
        render :text=>t(:warning_shipping_not_enough)
        return
      end
    rescue Exception => e
      logger.error("e = #{e}")
      render :text => ""

      return
    end

    render :partial=>"shipping_options", :layout=>false
  end

  def lostpass_submit
    prepare_lang_stuff()

    if params[:email] && params[:email] != ''
      user = User.find_by_email(params[:email])
      if user
        newpass = User.generate_password
        if SendMail.deliver_lost_pass(user, newpass)
          @user = User.find_by_email(params[:email])
          @user.update_attribute(:password, newpass)
          flash[:notice] = "<div class='successMessage'>#{t(:myizishirt_login_ctl_pass_sent, :locale=>@checkout_locale)}</div>"
        else
          flash[:notice] = "<div class='errorMessage'>#{t(:myizishirt_login_ctl_mail_faillure, :locale=>@checkout_locale)}</div>"
        end
      else
        flash[:notice] = "<div class='errorMessage'>#{t(:myizishirt_login_ctl_mail_match, :locale=>@checkout_locale)}</div>"
      end
      render :text => flash[:notice]
      return
    else
      render :text=>""
    end
  end

  def update_quantity
    @cart             = get_cart
    starting_quantity = @cart.blank_qty

    @cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == params[:id] }
    case params[:method]
      when 'add' :
        @cart.items[@item_idx].increment_quantity
		
		######################
	  @modelinfos  = Model.find(@cart.items[i].product.model.id)
	  
	if @modelinfos.nodiscount== true
		@cart.items[@item_idx].discount_value=0
	else
	
		@bulk_discount_req = BulkDiscount.find(:last, :conditions => ["is_default = ? and start <= ?", true, @cart.items[@item_idx].quantity], :order => :start)
		
		if @bulk_discount_req.nil?
        @bulk_discount =0
		else 
		@bulk_discount =@bulk_discount_req.percentage / 100.0
		end
		
		@cart.items[@item_idx].iscount_value= @bulk_discount
		
	
	end
	######################
		
      when 'remove' :
        begin
          if (@cart.items[@item_idx].quantity > 1)
            @cart.items[@item_idx].decrement_quantity
            @cart.items.delete_at @item_idx if (@cart.items[@item_idx].quantity < 1)
          end
        rescue
        end
      when 'delete' :
        begin
          @cart.items.delete_at @item_idx
          puts @cart.order_id
          if Order.exists?(@cart.order_id)
            @order   = Order.find(@cart.order_id)
            @product = @order.ordered_products.find_by_checksum(params[:id])
            @product.destroy
          end
        rescue
        end
    end
    
    end_quantity = @cart.blank_qty
    check_for_diff_prices(starting_quantity, end_quantity) if @cart.items[@item_idx].blank == true && @cart.items[@item_idx].product.model.model_category == "blank"


    @continue_link = params[:continue]
    validate_coupon(@cart.code)
    @next_step_url = "#{Language.print_force_lang(params[:lang])}checkout2/address"
    @next_step_url+= "?onsite=#{params[:onsite]}" if params[:onsite]
    @next_step_url+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]
    @next_step_url+= "&iframe=#{params[:iframe]}" if params[:iframe]
    @next_step_url+= "&store_id=#{params[:store_id]}" if params[:store_id]
  end

  def delete_cart_item

    prepare_lang_stuff

    @continue_link = get_continue_link
    @cart          = get_cart

    begin
      op = OrderedProduct.find_by_checksum(params[:id])
      op.destroy
    rescue
    end

    starting_quantity = @cart.blank_qty

    @cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == params[:id] }
    begin
      @cart.items.delete_at @item_idx

      begin
        if @cart.order_id && Order.exists?(@cart.order_id)
          @order   = Order.find(@cart.order_id)
          @product = @order.ordered_products.find_by_checksum(params[:id])
          @product.destroy
        end
      rescue
      end


      end_quantity = @cart.blank_qty

      check_for_diff_prices(starting_quantity, end_quantity) if @cart.items[@item_idx].blank == true && @cart.items[@item_idx].product.model.model_category == "blank"

    rescue
      validate_coupon(@cart.code)
      return
    end
    validate_coupon(@cart.code)
  end

  def update_cart_item

    prepare_lang_stuff

    @cart             = get_cart
    starting_quantity = @cart.blank_qty
	
	@cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == params[:id] }
	
	if !params[:model_size_id].nil?
		@model_size       = ModelSize.find(params[:model_size_id])	
	else 
		@model_size       = ModelSize.find(@cart.items[@item_idx].product.model_size_id.to_i)
	end

    @quantity         = params[:qty].to_i


    if params[:method] == "add"
      @quantity = @quantity + 1
      validate_coupon(@cart.code)
    elsif params[:method] == "remove"
      @quantity = @quantity - 1
      validate_coupon(@cart.code)
    end

    if @quantity < 1 || @model_size.nil?
      return
    end


    

    @base_price = @cart.items[@item_idx].product.price

    color       = @cart.items[@item_idx].product.color_id
    size        = @cart.items[@item_idx].product.model_size_id

    Rails.logger.error("outside THE IF: price=" + (@base_price).to_s)

	######################
	  @modelinfos  = Model.find(@cart.items[@item_idx].product.model.id)
	  
		if @modelinfos.nodiscount== true
			@cart.items[@item_idx].discount_value=0
		else
		
			@bulk_discount_req = BulkDiscount.find(:last, :conditions => ["is_default = ? and start <= ?", true, @cart.items[@item_idx].quantity], :order => :start)
			
			if @bulk_discount_req.nil?
			@bulk_discount =0
			else 
			@bulk_discount =@bulk_discount_req.percentage / 100.0
			end
			
			@cart.items[@item_idx].discount_value= @bulk_discount
			
			#@cart.items[@item_idx].set_price(@cart.items[@item_idx].product.price*(1-@bulk_discount))
			
		end
	######################
	
    if @cart.items[@item_idx].product.apply_size_prices? && (@cart.items[@item_idx].blank == false || @cart.items[@item_idx].product.model.model_category != "blank")
      @size_price      = @cart.items[@item_idx].product.model_size.extra_cost
      
		if !params[:model_size_id].nil? && params[:model_size_id].to_i>0
			@new_size_price  = ModelSize.find(params[:model_size_id].to_i).extra_cost	
		else 
			@new_size_price  = ModelSize.find(@cart.items[@item_idx].product.model_size_id.to_i).extra_cost
		end
      @diff_size_price = @new_size_price - @size_price
      @cart.items[@item_idx].set_price((@diff_size_price+@cart.items[@item_idx].product.price))
    end

    @cart.items[@item_idx].set_quantity(@quantity)
    @cart.items[@item_idx].set_model_size(@model_size)

    if @cart.items[@item_idx].blank == true && @cart.items[@item_idx].product.model.model_category == "blank"
      end_quantity = @cart.blank_qty
      check_for_diff_prices(starting_quantity, end_quantity)
      specification = ModelSpecification.find_by_color_id_and_model_id(color, @cart.items[@item_idx].product.model_id)
      blank_price = BlankPrice.price_of_by_qty(specification, @model_size, end_quantity)
      @cart.items[@item_idx].set_price(blank_price) if blank_price > 0
    end
	
	
	
	
	
	

    validate_coupon(@cart.code)


  end


  def popup_show_product
    @prod = OrderedProduct.find_by_checksum(params[:id])
    if @prod.nil?
      cart  = get_cart
      @prod = cart.items.detect { |i| i.product.checksum == params[:id] }.product
    end
    render :layout => false
  end

  def set_bulk_order
    #bulk_order_id = params[:order][:bulk_order_id]

    #get_cart.bulk_order_id = bulk_order_id

    render :text => ""
  end

  def validate_coupon(code = '')

    prepare_lang_stuff

    final_code = (code=='') ? params[:code] : code

    @cart      = get_cart
#    @coupon    = Coupon.find_by_active_and_code(true, final_code)
    #Only Izishirt Account can use the bulk order coupon
    if @coupon && @coupon.valid(@logged_in_user)
      if @cart.contains_shop2_items? && !@coupon.apply_to_boutique_products
        @cart.rebate = 0.0
        @cart.code   = ''
        if params[:code]
          @coupon_applied      ='false'
          @coupon_invalid_shop2='true'
        end
      else
        @cart.rebate = @coupon.calculate_rebate_from_cart(@cart)
        @cart.code   = final_code
        @coupon_applied='true' if params[:code]
      end
    elsif @logged_in_user && @logged_in_user.username == final_code && @logged_in_user.available_credit > 0
      @cart.user_credit = User.find_by_username(final_code).available_credit
      @cart.code        = 'User Credit'
      @coupon_applied   ='true'
    else
      @cart.rebate = 0.0
      @cart.code   = ''
      @coupon_applied='false' if params[:code]
    end

    render :partial => 'cart_total' if params[:action] == 'validate_coupon'
  end

  def load_billing_provinces_by_country
    @country_address_billing = Country.find(params["billing"]["country_id"])
    populate_for_provinces_refresh("billing")
    render :partial => "billing_province"
  end

  def load_shipping_provinces_by_country
    @country_address_shipping = Country.find(params["shipping"]["country_id"])
    populate_for_provinces_refresh("shipping")
    render :partial => "shipping_province"
  end

  def brief_address
    prepare_address()
  end

  def address

    if check_empty_cart
      return
    end
    prepare_lang_stuff()
    prepare_address()
  end

  def payment1
    p "START PAYMENT CONTROLLER"
    logger.fatal('start paymemt')
    @step = 4
    @cart = get_cart

    save_address

    @payment_subtotal = @cart.total.to_s
    @payment_shipping = @cart.shipping
    begin
      @payment_taxes = @cart.shippingaddress.province.taxe * @payment_subtotal.to_d / 100
    rescue
      @payment_taxes = 0.0
    end
    @payment_total = @payment_taxes + @payment_subtotal.to_d + @payment_shipping.to_d

    country        = session[:country]
    if (country == 'CA')
      @currency = 'CAD'
    else
      @currency = 'USD'
    end
  end

  def lcl_confirmation

    prepare_lang_stuff()

    if check_empty_cart
      return
    end

    message  ="message=#{params[:DATA]}"
    path_bin = "#{Rails.root}/lib/lcl/bin/response"
    pathfile = "pathfile=#{LCL_PATHFILE}"

    result   = `#{path_bin} #{pathfile} #{message}`
    tableau  = result.split("!")

    logger.error("tableau confirm : #{tableau}")

    code                  = tableau[1];
    error                 = tableau[2];
    merchant_id           = tableau[3];
    merchant_country      = tableau[4];
    amount                = tableau[5];
    #transaction_id = tableau[6];
    @authorization_number = tableau[6];
    payment_means         = tableau[7];
    transmission_date     = tableau[8];
    payment_time          = tableau[9];
    payment_date          = tableau[10];
    response_code         = tableau[11];
    payment_certificate   = tableau[12];
    authorisation_id      = tableau[13];
    currency_code         = tableau[14];
    @result_card_number   = tableau[15];
    cvv_flag              = tableau[16];
    cvv_response_code     = tableau[17];
    bank_response_code    = tableau[18];
    complementary_code    = tableau[19];
    complementary_info    = tableau[20];
    return_context        = tableau[21];
    caddie                = tableau[22];
    receipt_complement    = tableau[23];
    merchant_language     = tableau[24];
    language              = tableau[25];
    customer_id           = tableau[26];
    order_id              = tableau[27];
    customer_email        = tableau[28];
    customer_ip_address   = tableau[29];
    capture_day           = tableau[30];
    capture_mode          = tableau[31];
    data                  = tableau[32];

    # CODE VERIFICATION
    if response_code != "00" && response_code != "0"
      redirect_to :controller => "/"
      return
    end

    @cart       = get_cart
    @cart_total = @cart.grandtotal
    @currency   = session[:currency]

    begin
      @customer_name = @cart.billingaddress.name
    rescue
      @customer_name = ""
    end

    @order_number             = order_id

    @order                    = Order.find(order_id)

    @cardholder_name          = @order.billing.name

    @in_checkout_confirmation = true

    @lcl                      = true

    if @order.coupon_order? && @order.status == SHIPPING_TYPE_PENDING
      @order.status = SHIPPING_TYPE_SHIPPED
      @order.save
    end

    # Send confirmation email
    begin
      if !@order.coupon_order?
        generate_invoice(@order)

        if @order.user.username == "guest"
          SendMail.deliver_confirm_order_guest(@order, @order.language_id)
        else
          SendMail.deliver_confirm_order_user(@order)
        end
      else
      end

    rescue => e
      logger.error("LCL ERROR = #{e}")
      flash[:error] = 'Confirmation email not sent!'
    end

    @continue_link = get_continue_link

    # empty_cart

    render :action => "confirmation", :layout=>"izishirt_2011"
  end

  def generate_invoice(order)
    begin
      order_to_string = render_to_string :controller => "checkout2", :action => "generate_invoice_html", :id => order.id, :layout => false
      f               = File.open(order.tmp_invoice("html"), 'w')
      f.write(order_to_string)
      f.close

      order.invoice_html = File.new(order.tmp_invoice("html"))

      order.save

      # PDF
      system("wkhtmltopdf #{order.tmp_invoice("html")} #{order.tmp_invoice("pdf")}")

      order.invoice_pdf = File.new(order.tmp_invoice("pdf"))

      order.save
    rescue
    end
  end

  def confirmation
    prepare_lang_stuff()


    if check_empty_cart
      return
    end

    @cart  = get_cart
    order  = Order.find(@cart.order_id)
    @order = order

    if order.already_paid?
      return
    end

    #require "internetsecure.rb"
    @header            = t(:shopping_cart, :locale => @checkout_locale)


    @payment_type      = "credit_card"

    #login = session[:country] == 'US' ? '11862' : '11861'

    payment_problem    = false

    session[:currency] = @cart.get_currency
    user_id            = session[:user_id] || session[:guest_id]
    @customer          = User.find(user_id)

    #rate = CurrencyExchange.currency_exchange(100,session[:currency], "CAD")/100.0
    #@total = @cart.grandtotal*rate
    @cart.currency     = session[:currency]
    @currency          = session[:currency]
    payment_form       = params['payment']
    card_number        = payment_form['cardnumber'].scan(/\d/).to_s
    expiration         = payment_form['expiration_month'] + '/' + payment_form['expiration_year']
    @cardholder_name   = payment_form['firstname'] + " " + payment_form['lastname']
    @cc_type           = params[:payment_type]


    #if @cart.shippingaddress.country.shortname != "CA" || @cart.billingaddress.country.shortname != "CA"
    if session[:currency] != "CAD"

      order.extra_comment += "Currency not CAD | "
      order.save
    end

    begin
      payment_method = "custom"

      if session[:currency] == "CAD" && params[:payment_type] != "Amex"
        payment_method = "moneris"
      elsif params[:payment_type] != "Amex"
        payment_method = "paypal"
      end

      @authorization_number = "Izishirt Placed"

      # GOOD IF
      if (@customer.id != 70 && !@customer.is_izishirt_seller && @cart.grandtotal > 0.0) && ["moneris", "paypal"].include?(payment_method)

        # TEST IF
        #if ["moneris", "paypal"].include?(payment_method)

        amount = @cart.grandtotal*100

        # PAYPAL initialization
        if payment_method == "paypal"

          credit_card = ActiveMerchant::Billing::CreditCard.new(
              #:type       => @cc_type,
          :number            => card_number,
          :month             => payment_form['expiration_month'],
          :year              => payment_form['expiration_year'],
          :first_name        => payment_form['firstname'],
          :last_name         => payment_form['lastname'],
          :verification_value=> payment_form['ccv']
          )

          raise format_hash_error(credit_card.errors) unless credit_card.valid?
        end

        #raise credit_card.errors[credit_card.errors.keys[0]] unless credit_card.valid?
        begin
          state = @cart.billingaddress.province_name
          state = @cart.billingaddress.province.code if @cart.billingaddress.country.shortname == "CA" || @cart.billingaddress.country.shortname == "US"
        rescue
        end

        billingaddress = {
            :name     => @cart.billingaddress.name,
            :address1 => @cart.billingaddress.address1,
            :address2 => @cart.billingaddress.address2,
            :city     => @cart.billingaddress.town,
            :state    => state,
            :country  => @cart.billingaddress.country.shortname,
            :zip      => @cart.billingaddress.zip,
            :phone    => @cart.billingaddress.phone
        }


        state          = @cart.shippingaddress.province_name
        begin
          state = @cart.shippingaddress.province.code if @cart.shippingaddress.country.shortname == "CA" || @cart.shippingaddress.country.shortname == "US"
        rescue
        end
        shippingaddress = {
            :name     => @cart.shippingaddress.name,
            :address1 => @cart.shippingaddress.address1,
            :address2 => @cart.shippingaddress.address2,
            :city     => @cart.shippingaddress.town,
            :state    => state,
            :country  => @cart.shippingaddress.country.shortname,
            :zip      => @cart.shippingaddress.zip,
            :phone    => @cart.shippingaddress.phone
        }

        if payment_method == "paypal"
          # PAYPAL
          gateway = ActiveMerchant::Billing::PaypalGateway.new(:login=>$PAYPAL_LOGIN, :password=>$PAYPAL_PASSWORD)
          res     = gateway.authorize(amount, credit_card, :ip=>request.remote_ip, :billingaddress=>billingaddress, :shippingaddress=>shippingaddress, :currency=>session[:currency])
        elsif payment_method == "moneris"
          order = Order.find(@cart.order_id)
          # MONERIS
          res   = MonerisTransaction.new("#{@cart.order_id}", "#{order.email_client}", @cart.grandtotal, "#{card_number}",
                                         "#{payment_form['expiration_year']}", "#{payment_form['expiration_month']}", "#{payment_form['ccv']}", "production")

          res.execute
        end

        if res.success?
          # PAYPAL VERIFICATION
          if (!is_probably_fraud(@order, @cardholder_name) && payment_method == "paypal")
            gateway.capture(amount, res.authorization, :currency=>session[:currency])
          end
        else
          raise res.message.to_s
        end

        @authorization_number = res.authorization
        @result_card_number   = '**** **** **** ' + card_number[-4, 4]
        type_transaction      = "Gateway #{payment_method.capitalize}"
      elsif params[:payment_type] == "Amex"
        if card_number.length < 15
          raise "Wrong card number"
        end
        @order           = Order.find(@cart.order_id)

        @order.custom1   = card_number
        @order.custom2   = expiration
        @order.custom3   = @cardholder_name

        type_transaction = "Amex"


        @order.save!
      end
      @order_number  = @cart.order_id
      @order         = Order.find(@order_number)

      @customer_name = @cart.billingaddress.name
      @cart_total    = @cart.grandtotal
      confirm_order(@cart.order_id, type_transaction, @authorization_number)
      @order = Order.find(@order.id)

    rescue => e

      order.update_attributes(:nb_checkout_errors => order.nb_checkout_errors + 1, :last_checkout_error_on => Time.now)

      flash[:error] = t(:confirmation_denied, :locale => @checkout_locale)
      logger.error("e = #{e}")
      # payment
      # render :action => 'payment', 
      #  :onsite => params[:onsite], 
      #  :iframe => params[:iframe], 
      #  :flash_iframe => params[:flash_iframe], 
      #  :store_id => params[:store_id]

      redirect_to :action       => "payment", :onsite => params[:onsite],
                  :iframe       => params[:iframe],
                  :flash_iframe => params[:flash_iframe],
                  :store_id     => params[:store_id]
      return

      # payment_problem = true
    end

    if !payment_problem

      check_coupon_code_use(@order)



      check_because_supplier = false



      @order.update_attributes(:true_amount_paid => @order.total_price)

      #rescue Exception => e

      #  flash[:error] = 'Confirmation email not sent!'
      #end


      #check_big_online_order_to_call(@order)

      @continue_link            = get_continue_link
      @in_checkout_confirmation = true
    end
  end

  def generate_invoice_html

    @order         = Order.find(params[:id])

    @shipping_cost = @order.total_shipping

    @order_id      = @order.id

    @title         = I18n.t(:order_invoice_title, :locale => Language.find(@order.language_id).shortname)
    @terms         = ""

    begin
      @billing_address = Address.find(@order.billing_address)
    rescue
      @billing_address = nil
    end

    begin
      @shipping_address = Address.find(@order.shipping_address)
    rescue
      @shipping_address = nil
    end

    @taxes = @order.total_taxes

    @total = @order.total_price

    #render :layout => false
  end

  ###################################################################################
  #
  # Function was duplicated in the my controller in order to allow access to the cart
  # from the new boutiques.
  #
  # For security reasons subdomains are not able to make ajax calls to a main domain
  # There are work arounds but they create security issues.
  #
  ###################################################################################
  def add_product_from_boutique

    @cart       = get_cart
    add_to_cart = params[:add_to_cart]

    #copy product details into ordered products
    @product    = Product.find(params[:product_id])
    if @product.in_stock?(params[:model_size_id])
      @ordered_product                    = OrderedProduct.create_from_product(@product,
                                                                               params[:model_size_id],
                                                                               @product.color_id,
                                                                               params[:quantity])
      @ordered_product.is_blank = @ordered_product.define_is_blank
      @ordered_product.purchase_source_id = PurchaseSource.find_by_str_id("boutique").id

      #add product to cart
      @cart.add_product(@ordered_product, @ordered_product.quantity, @ordered_product.is_blank)

      if add_to_cart == 'true'
        render :partial => "cart_item_count"
      else
        redirect_to :controller=>"/checkout2/show_cart", :id=>@product.id
      end
    else
      redirect_to :controller=>"/checkout2/show_cart", :id=>@product.id
    end

  end

  def add_promotion
    @cart                                 = get_cart
    @product                              = Product.find(params[:product])
    @ordered_product                      = OrderedProduct.new
    @ordered_product.created_on           = Date.today
    @ordered_product.product_id           = @product.id
    @ordered_product.store_id             = @product.store_id
    @ordered_product.curency_id           = @product.curency_id
    @ordered_product.color_id             = Color.lookup(params[:color])
    @ordered_product.model_id             = @product.model_id
    @ordered_product.cost_price           = @product.model.cost_price
    @ordered_product.print_cost_white     = Price.find(:first, :conditions=>["name = 'Zone White'"]).price
    @ordered_product.print_cost_white_xxl = Price.find(:first, :conditions=>["name = 'Zone White XXL'"]).price
    @ordered_product.print_cost_other     = Price.find(:first, :conditions=>["name = 'Zone Other'"]).price
    @ordered_product.print_cost_other_xxl = Price.find(:first, :conditions=>["name = 'Zone Other XXL'"]).price
    @ordered_product.model_size_id        = params[:model_size_id]
    @ordered_product.quantity             = params[:quantity] || 1
    @ordered_product.price                = @product.price
    @ordered_product.commission           = @product.commission
    @ordered_product.checksum             = Digest::MD5.hexdigest(Time.to_s + rand.to_s)
    @cart.add_product(@ordered_product, @ordered_product.quantity)

    copy_promotion_images params[:sex], params[:color], @ordered_product.checksum
    if CHECKOUT_REQUIRE_LOGIN && !@user_is_logged_in
      #url_for(:protocol => 'https', :host => 'www.izishirt.ca', :controller => 'checkout', :action=>'address')
      @next_step_url = "#{Language.print_force_lang(params[:lang])}myizishirt/login?validate=1"
      @next_step_url+= "&onsite=#{params[:onsite]}" if params[:onsite]
      @next_step_url+= "&iframe=#{params[:iframe]}" if params[:iframe]
      @next_step_url+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]
      @next_step_url+= "&store_id=#{params[:store_id]}" if params[:store_id]
    else
      @next_step_url = "#{Language.print_force_lang(params[:lang])}checkout2/address"
      @next_step_url+= "?onsite=#{params[:onsite]}" if params[:onsite]
      @next_step_url+= "&iframe=#{params[:iframe]}" if params[:iframe]
      @next_step_url+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]
      @next_step_url+= "&store_id=#{params[:store_id]}" if params[:store_id]
    end
    redirect_to :controller=>@next_step_url
  end

  def add_product_from_shop1
    begin
      @image = params[:image] ? Image.find(params[:image]) : nil
      @color = Color.find(params[:color])
      @model = Model.find(params[:model])

      if Model.in_stock?(@model.id, params[:model_size_id].to_i, @color.id)
        #Generate new product
        @ordered_product                    = OrderedProduct.create_with_image_and_color_and_model(@image, @color, @model)
        @ordered_product.quantity           = params[:quantity].to_i
        @ordered_product.size               = Size.find(params[:model_size_id].to_i)
        @ordered_product.price              += @ordered_product.model_size.extra_cost
        @ordered_product.purchase_source_id = PurchaseSource.find_by_str_id("website").id

        @cart                               = get_cart
        @cart.add_product(@ordered_product, @ordered_product.quantity)
      end

      render :text => "Added to cart"
    rescue Exception => e
      logger.error("[+][+][+] Error adding product from shop 1 = #{e}")
      redirect_to :back
    end
  end

  def add_product_from_shop2
    @cart    = get_cart
    @product = Product.find(params[:product_id])
    if @product.in_stock?(params[:model_size_id])
      @ordered_product = OrderedProduct.create_from_product(@product,
                                                            params[:model_size_id],
                                                            params[:color_id],
                                                            params[:quantity],
                                                            params[:marketplace_price],
                                                            session[:user_id])

      @ordered_product.is_blank = @ordered_product.define_is_blank
      @cart.add_product(@ordered_product, @ordered_product.quantity, @ordered_product.is_blank)
    end

    redirect_to :controller=>"/checkout2/show_cart"
  end

  #def

  def save_product
    #This new product replaces the old one, so delete it first
    if params[:product]
      @cart = get_cart
      @cart.items.each_index { |i| @item_idx_del = i if @cart.items[i].product.checksum == params[:product] }
      begin
        @cart.items.delete_at @item_idx_del

        if Order.exists?(@cart.order_id)
          @order_del   = Order.find(@cart.order_id)
          @product_del = @order_del.ordered_products.find_by_checksum(params[:product])
          @product_del.destroy
        end
      rescue
      end
    end
    #EO Delete old product

    checkout      = params[:checkoutXmlString]
    checkout_hash = Digest::MD5.hexdigest("#{FLASH_APP_SALT}#{checkout}")

    if params[:checkoutHash] && params[:checkoutHash] != checkout_hash
      logger.error("Flash App Hack Attempt!!!")
    else
      doc = REXML::Document.new(checkout)
      doc.elements['//data/purchases'].each do |product_xml|
        @ordered_product = OrderedProduct.create_from_xml(product_xml, doc, currency_rate(session[:currency]))
        @ordered_product.is_blank = @ordered_product.define_is_blank
        logger.error("is_blank = " + @ordered_product.is_blank.to_s)
        session[:referer_from_boutique] = nil
        get_cart.add_product(@ordered_product, @ordered_product.quantity, @ordered_product.is_blank)
      end
    end
    render :text => '&success=true', :layout => false
  end

  def add_custom_tote

    begin
      if @cart.contains_item_with_promo("fast_custom_tote")
        redirect_to :back
        return
      end
    rescue
    end

    shirt_text = ""

    (1..5).each do |i|

      line = "#{params["line_#{i}"]}"

      if !line || (line && line.length == 0)
        next
      end

      shirt_text += "#{line}\n"
    end

    checksum = Digest::MD5.hexdigest(Time.to_s + rand.to_s)
    model    = Model.find(85)

    op       = OrderedProduct.create(:checksum             => checksum, :model_id => model.id, :price => 3.50, :quantity => 1,
                                     :color_id             => model.default_color_id, :cost_price => model.cost_price,
                                     :print_cost_white     => Price.find(:first, :conditions=>["name = 'Zone White'"]).price,
                                     :print_cost_white_xxl => Price.find(:first, :conditions=>["name = 'Zone White XXL'"]).price,
                                     :print_cost_other     => Price.find(:first, :conditions=>["name = 'Zone Other'"]).price,
                                     :print_cost_other_xxl => Price.find(:first, :conditions=>["name = 'Zone Other XXL'"]).price,
                                     :model_size_id        => model.default_model_size.id, :promo_type => "fast_custom_tote")

    oz_front = OrderedZone.create(:ordered_product_id => op.id, :zone_type => ZoneDefinition.find_by_str_id("front").id)
    oz_back  = OrderedZone.create(:ordered_product_id => op.id, :zone_type => ZoneDefinition.find_by_str_id("back").id)

    image, font_size = OnTheFlyPreviewGenerator.gen_image(model, shirt_text)

    lines = shirt_text.split("\n")


    pos   = 1

    lines.each do |line|

      line = line.strip

      OrderedTxtLine.create(:ordered_zone_id => oz_front.id, :line_position => pos, :color_id => Color.black.id,
                            :italic          => false, :bold => true, :align => "centered", :size => font_size, :font => Font.find_by_name("Arial").id, :content => line,
                            :x               => 0, :y => 0, :width => 0, :height => 0)

      pos += 1
    end

    # if op.apply_size_prices?
    #	op.price += op.model_size.extra_cost
    # end

    # gen front
    GenerateImage.finalize_with_image(image, OrderedProduct.path_ordered_product(op.created_on), op.checksum, ZoneDefinition.find_by_str_id("front").id)

    # gen back
    img = GenerateImage.new(model.id, model.default_color_id, ZoneDefinition.find_by_str_id("back").id)
    img.finalize(OrderedProduct.path_ordered_product(op.created_on), op.checksum, ZoneDefinition.find_by_str_id("back").id)

    begin
      if @cart.contains_item_with_promo("fast_custom_tote")
        redirect_to :back
        return
      end
    rescue
    end

    get_cart.add_product(op, 1)

    redirect_to :back
  end


  def shipping
    require 'net/http'
    require 'uri'

    uri             = URI.parse('http://cybervente.postescanada.ca:30000/')
    http            = Net::HTTP.new uri.host, uri.port
    @response_plain = http.post(uri.path, xmlRequest).body
    @res            = REXML::Document.new(@response_plain)

    @response       = @response_plain.include?('<?xml') ? REXML::Document.new(@response_plain) : @response_plain
    @response.instance_variable_set "@response_plain", @response_plain

    def @response.plain;
      @response_plain;
    end
  end

  def payment

    if check_empty_cart
      return
    end
    prepare_lang_stuff()
    ActionView::Base.send(:include, ActiveMerchant::Billing::Integrations::ActionViewHelper)

    @cart             = get_cart

    @payment_shipping = @cart.shipping

    if @payment_shipping < 0 && !@cart.coupon_order?
      flash[:error] = t(:front_office_checkout_err_storing_addr, :locale => @checkout_locale)
      redirect_to :action => "address"
      return
    end

    if (!@cart.shippingaddress || !@cart.billingaddress) && !@cart.coupon_order?
      flash[:error] = t(:front_office_checkout_err_storing_addr, :locale => @checkout_locale)
      redirect_to :action => "address"
      return
    end

    session[:currency] = @cart.get_currency

    #passed_by_address_form = params[:shipping] && params[:billing]

    begin
      @payment_subtotal = @cart.total.to_s
    rescue
      @payment_subtotal = 0.0
      @payment_shipping = 0.0
    end

    @back         = "#{Language.print_force_lang(params[:lang])}checkout2/address"
    @confirmation = "#{Language.print_force_lang(params[:lang])}checkout2/confirmation"
    @confirmation+= "?onsite=#{params[:onsite]}" if params[:onsite]
    @confirmation+= "&store_id=#{params[:store_id]}" if params[:store_id]
    @paypal_continue          = @SECURE_URL_ROOT+@confirmation.gsub("confirmation", "payment")
    @paypal_confirmation      = @SECURE_URL_ROOT+@confirmation.gsub("confirmation", "paypal_confirmation")
    @auto_paypal_confirmation = @SECURE_URL_ROOT+@confirmation.gsub("confirmation", "auto_paypal_confirmation")
    @confirmation+= "&iframe=#{params[:iframe]}" if params[:iframe]
    @confirmation+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]

    #begin
    #  @payment_taxes = @cart.taxes
    #rescue
    #  @payment_taxes = 0.0
    #end
	
	@payment_taxes1=@cart.taxes_canada
	
	totaxe=0
	@payment_taxes1.each do |taxeinfo, val| 
				if taxeinfo != "" && val != "" 
				
				totaxe= totaxe+val
				end
			end
	
    #begin
    #  @country_taxes   = @cart.country_taxes
    #  @tax_abreviation = @cart.tax_abreviation(session[:language_id])
    #rescue
    #  @country_taxes = 0
    #end totaxe + 

	@payment_total = 0.0
	#@payment_subtotal.to_d	+ (@payment_shipping - @cart.shipping_rebate(@payment_shipping))
	#@payment_total = @payment_taxes + @payment_subtotal.to_d + (@payment_shipping - @cart.shipping_rebate(@payment_shipping))

    # Don't create an order if there is no shipping address
    create_order


    prepare_payment

    @paypal_email = "embpoint@yahoo.ca"



    # paypal test
    if ENV['RAILS_ENV'] == "development"
      @paypal_email = "aa@studiocodency.com"
    end

    logger.error("ASDF 1")

    # if session[:currency] == "EUR" && (["FR", "BE"].include?(@cart.billingaddress.country.shortname))
    if true == false #session[:currency] == "EUR" && (["FR", "BE"].include?(@cart.billingaddress.country.shortname))
      logger.error("ASDF 2")

      confirm_order(@order_id, "lcl", "lcl", false)
      @lcl           = true


      path_bin       = "#{Rails.root}/lib/lcl/bin/request"
      params_payment = "merchant_id=#{LCL_MERCHANT_ID} merchant_country=fr amount=#{(@payment_total*100).to_i} currency_code=978 pathfile=#{LCL_PATHFILE} order_id=#{@order_id}"
      #params_payment = "merchant_id=#{LCL_MERCHANT_ID} amount=#{(@payment_total*100).to_i} pathfile=#{LCL_PATHFILE}"
      logger.error(params_payment)
      result    = `#{path_bin} #{params_payment}`

      tab       = result.split("!")
      @lcl_form = tab[3]

    else
      confirm_order(@order_id, "", "", false)
    end


    @back         = "#{Language.print_force_lang(params[:lang])}checkout2/address"
    @confirmation = "#{Language.print_force_lang(params[:lang])}checkout2/confirmation"
    @confirmation+= "?onsite=#{params[:onsite]}" if params[:onsite]
    @confirmation+= "&iframe=#{params[:iframe]}" if params[:iframe]
    @confirmation+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]
    @confirmation+= "&store_id=#{params[:store_id]}" if params[:store_id]

    @order = Order.find(@order_id)
  end


  def lcl_auto_confirmation

    message  ="message=#{params[:DATA]}"
    path_bin = "#{Rails.root}/lib/lcl/bin/response"
    pathfile = "pathfile=#{LCL_PATHFILE}"

    result   = `#{path_bin} #{pathfile} #{message}`
    tableau  = result.split("!")

    logger.error("tableau auto : #{tableau}")

    code                = tableau[1];
    error               = tableau[2];
    merchant_id         = tableau[3];
    merchant_country    = tableau[4];
    amount              = tableau[5];
    transaction_id      = tableau[6];
    payment_means       = tableau[7];
    transmission_date   = tableau[8];
    payment_time        = tableau[9];
    payment_date        = tableau[10];
    response_code       = tableau[11];
    payment_certificate = tableau[12];
    authorisation_id    = tableau[13];
    currency_code       = tableau[14];
    card_number         = tableau[15];
    cvv_flag            = tableau[16];
    cvv_response_code   = tableau[17];
    bank_response_code  = tableau[18];
    complementary_code  = tableau[19];
    complementary_info  = tableau[20];
    return_context      = tableau[21];
    caddie              = tableau[22];
    receipt_complement  = tableau[23];
    merchant_language   = tableau[24];
    language            = tableau[25];
    customer_id         = tableau[26];
    order_id            = tableau[27];
    customer_email      = tableau[28];
    customer_ip_address = tableau[29];
    capture_day         = tableau[30];
    capture_mode        = tableau[31];
    data                = tableau[32];

    # CODE VERIFICATION
    logger.error("RESPONSE CODE = #{response_code}, tableau = #{tableau.inspect}")
    if response_code != "00" && response_code != "0"
      return
    end

    order                     = Order.find(order_id)
    order.payment_transaction = transaction_id

    order.true_amount_paid    = (amount.to_f / 100.00).round(2)

    begin
      diff = order.true_amount_paid - order.total_price.round(2)

      if (diff >= 0.02 || diff <= -0.02)
        order.status        = SHIPPING_TYPE_TO_CHECK
        order.extra_comment += "Amount order and payment different | "
      end

    rescue
    end

    order.confirmed = true

    active_product_coupons(order)
    send_gift_coupons(order)

    if order.coupon_order? && order.status == SHIPPING_TYPE_PENDING
      order.status = SHIPPING_TYPE_SHIPPED
    end

    order.save!

    check_coupon_code_use(order)

    check_because_supplier = false




    if Order.is_24_hours_order(order.ordered_products)
      SendMail.deliver_notify_24_hours_order(order)
    end

    if order.status == SHIPPING_TYPE_TO_CHECK
      SendMail.deliver_to_check_notification(order, check_because_supplier)
    end

    check_big_online_order_to_call(order)

    render :text=>"ok"
  end

  def confirm_paypal(param_name_order, param_name_status, param_name_transaction)
    require 'socket'

    # first, check the host..
    host = ""

    begin
      s     = Socket.getaddrinfo(request.remote_ip, nil)
      host2 = ""
      begin
        host2 = Socket.getaddrinfo(request.env["HTTP_X_FORWARDED_FOR"], nil)[0][2]

      rescue
      end

      host = s[0][2]
    rescue Exception => e


    end


    if host.index("paypal.com").nil? && host2.index("paypal.com").nil?
      redirect_to "/"
      return true
    end

    order_id = params[param_name_order]
    status   = params[param_name_status]

    @order   = Order.find(order_id)

    logger.fatal('Params from PayPal:')
    logger.fatal(params.inspect)

    paypal_transaction = params[param_name_transaction] if params[param_name_transaction]

    confirmed = false

    order     = @order

    if status == 'Completed'
      confirmed = true
      # confirm_order(@order.id,"paypal",paypal_transaction)
    elsif status == 'Pending'
      confirmed = true

      if order.status != SHIPPING_TYPE_TO_CHECK
        order.status = SHIPPING_TYPE_AWAITING_PAYMENT
        order.save!
      end

    else
      redirect_to :action => "cart"
      return true
    end

    if order.coupon_order? && order.status == SHIPPING_TYPE_PENDING
      order.status = SHIPPING_TYPE_SHIPPED
      order.save
    end

    order.update_attributes(:confirmed => confirmed, :paypal_transaction => paypal_transaction)


    # Send confirmation email
    begin
        generate_invoice(@order)

        if @order.user.username != "guest"
          SendMail.deliver_confirm_order_user(@order)
        else
          SendMail.deliver_confirm_order_guest(@order, @order.language_id)
        end
    rescue
      flash[:error] = 'Confirmation email not sent!'
    end

    return false
  end

  def auto_paypal_confirmation
  
	if params[:item_number]
		order = Order.find(params[:item_number])

		if order && !order.confirmed

		  if confirm_paypal("item_number", "payment_status", "txn_id")
			#active_product_coupons(order)
			#send_gift_coupons(order)
			return
		  else
		  end

		  #check_coupon_code_use(order)
		end
	end
	
    render :text => ""
  end

  # tx=1YU40385EY890122L&st=Completed&amt=56.05&cc=CAD&cm=21636&item_number=21636
  def paypal_confirmation

    prepare_lang_stuff

    if check_empty_cart
      return
    end

    @cart         = get_cart

    order_id      = params[:item_number] || @cart.order_id

    order         = Order.find(order_id)
    @order        = order



    @header       = t(:shopping_cart, :locale => @checkout_locale)
    @cart_total   = @order.total_price
    @currency     = session[:currency]
    @paypal_email = "" # params['payer_email']
    @payment_type = "paypal"
    @alt_country  = "CA"

    @order_number = @order.id

    begin
      @customer_name = @order.billing.name
    rescue
      @customer_name = "N/A"
    end

    @currency                 = session[:currency] || @order.curency_id

    @header                   = t(:shopping_cart, :locale => @checkout_locale)
    @cart_total               = @cart.grandtotal
    @total                    = @cart.grandtotal
    @paypal_email             = "" # params['payer_email']

    @in_checkout_confirmation = true
    @continue_link            = get_continue_link

    # empty_cart

    render :action => "confirmation"
  end

  def gifts
  end

  def gifts_address
    session[:gift] = params[:gift] if params[:gift]
  end

  def gifts_payment
    session[:address] = params[:address] if params[:address]

    if session[:user_id].nil?
      session[:original_uri_login] = "/checkout2/gifts_payment"
      redirect_to :controller=>"/login"
    end
    country = session[:country]
    if (country == 'CA')
      @currency = 'CAD'
    else
      @currency = 'USD'
    end
  end

  def setup_menu
    @shop_theme = params[:theme] ? ShopTheme.find(params[:theme]) : @store.active_theme
    @shop_theme = ShopTheme.find(4) if @shop_theme.nil?
    if @shop_theme
      if @shop_theme.menu.shop_bank_menu
        bank_menu    =@shop_theme.menu.shop_bank_menu
        @shop_style  = bank_menu.button("shop", session[:language_id]).style
        @design_style=bank_menu.button("design", session[:language_id]).style
        @create_style=bank_menu.button("create", session[:language_id]).style
        @shop_link   ="&nbsp;"
        @design_link ="&nbsp;"
        @create_link ="&nbsp;"
        @link_style  =""
      else
        bank_menu    =@shop_theme.menu.shop_bank_menu
        @shop_style  = @shop_theme.menu.bg_border_style
        @design_style=@shop_theme.menu.bg_border_style
        @create_style=@shop_theme.menu.bg_border_style
        @shop_link   =t(:shop, :locale => @store.locale)
        @design_link =t(:designs, :locale => @store.locale)
        @create_link =t(:create, :locale => @store.locale)
        @link_style  = @shop_theme.menu.text.style
      end
    end
  end

  private

  def is_probably_fraud(order, cardholdname)
    begin
      # - si billing <> shipping
      s_billing  = StringUtil.to_comparable_string(order.billing.to_s)
      s_shipping = StringUtil.to_comparable_string(order.shipping.to_s)

      if s_billing == s_shipping && order.total_price <= 50.0
        return false
      end

      if (order.shipping.country.shortname != "CA" || order.billing.country.shortname != "CA") && order.nb_tshirts_with_prints == 0
        order.extra_comment += "Blank order not from CA | "
        order.save
        logger.error("FRAUDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD 55")
        return true
      end

      # price > 200
      if order.total_price >= 200 && !order.bulk_order?
        order.extra_comment += "Blank order not from CA | "
        order.save
        logger.error("FRAUDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD 1")
        return true
      end


      if s_billing != s_shipping && !order.pick_up
        order.extra_comment += "Shipping and billing different | "
        order.save
        logger.error("FRAUDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD 2")
        return true
      end

      # - si nom carte différent nom billing
      n_card    = StringUtil.to_comparable_string(cardholdname)
      n_billing = StringUtil.to_comparable_string(order.billing.name)

      if n_card != n_billing
        logger.error("FRAUDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD 3")
        order.extra_comment += "Credit card name and order name different | "
        order.save
        return true
      end

      # - si ip geoip diff billing country
      begin
        require 'geoip'
      rescue Exception => e
        logger.error("ERROR 1 DETECTION FRAUD -> #{e}")
      end

      begin
        g                = GeoIP.new("lib/GeoLiteCity.dat")
        ip               = request.ip
        city             = g.city(ip)
        country_code_cur = city[2]

        if country_code_cur && country_code_cur != order.billing.country.shortname
          order.extra_comment += "Country IP different billing country | "
          order.save
          logger.error("FRAUDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD 4")
          return true
        end
      rescue Exception => e
        logger.error("ERROR 2 DETECTION FRAUD -> #{e}")
      end


      logger.error("COUNTRY CODE CUR.. #{country_code_cur}")
    rescue Exception => e
      logger.error("ERROR 3 DETECTION FRAUD -> #{e}")
    end

    return false
  end

  def prepare_show_cart
    logger.error("nb_itemsssssssssssss  = #{get_cart.items.length}")
    prepare_lang_stuff
#    populate_bulk_orders()

    @header = t(:shopping_cart, :locale => @checkout_locale)

    url     = "#{Language.print_force_lang(params[:lang])}checkout2/address"
    url+= "?onsite=#{params[:onsite]}" if params[:onsite]
    url+= "&iframe=#{params[:iframe]}" if params[:iframe]
    url+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]
    url+= "&store_id=#{params[:store_id]}" if params[:store_id]

    @continue_link = get_continue_link

    save_address

    @cart = get_cart
    session[:currency] = @cart.get_currency if @cart.billingaddress
    @cart.verify_products

#    validate_coupon(@cart.code)

    if CHECKOUT_REQUIRE_LOGIN && !@user_is_logged_in
      @next_step_url = url_for(:action       =>:choose_login,
                               :onsite       => params[:onsite],
                               :iframe       => params[:iframe],
                               :flash_iframe => params[:flash_iframe],
                               :store_id     => params[:store_id],
                               :type=>"guest")
    else
      @next_step_url   = url
      @next_step_class = ""
      @next_step_name  = "Checkout"
    end

    @step = 1


  end


  def populate_for_provinces_refresh(address_id)
    country_id = params[address_id]["country_id"]
    populate_countries_provinces_by_country_id(country_id.to_i, country_id.to_i)

    @cart     = get_cart

    @billing  = (@cart.billingaddress || check_for_saved_addresses(1))
    @shipping = (@cart.shippingaddress || check_for_saved_addresses(2))
  end

  def populate_countries_provinces_by_country_id(billing_country_id, shipping_country_id)
    banned_countries    = ['ID', 'MY', 'VN', 'SG']
    @countries          = Country.find(:all).select { |c| c.shortname != 'EU' && c.shortname != 'IN' && !banned_countries.include?(c.shortname) }.map { |c| [c.name, c.id] }

    @billing_provinces  = [["", ""]] | Province.find_all_by_country_id(billing_country_id).map { |l| [l.name, l.id] }
    @shipping_provinces = [["", ""]] | Province.find_all_by_country_id(shipping_country_id).map { |l| [l.name, l.id] }

  end


  def confirm_order(order_id, type, transaction, confirm=true)
    #rate = CurrencyExchange.currency_exchange(100,session[:currency], "CAD")/100.0
    order     = Order.find(order_id)
    user_id   = session[:user_id] || session[:guest_id] || order.user.id
    @customer = User.find(user_id)
    @total    = @cart.grandtotal #*rate
    @currency = session[:currency] || order.curency_id
    order.update_attribute("confirmed", confirm)
    order.total_price    = @total.nil? ? 0 : @total

    p_ship               = @cart.shipping

    order.total_shipping = p_ship - @cart.shipping_rebate(p_ship)
    order.total_taxes    = @cart.taxes+@cart.country_taxes
    order.total_rebate   = @cart.total_rebate
    order.shipping_type  = @cart.shipping_type
    #order.bulk_order_id = @cart.bulk_order_id
    order.referer_id = session[:referer_id] if session[:referer_id]

    order.check_should_be_rush

    order.xmas = 1 if @cart.shipping_type.to_i == SHIPPING_CHRISTMAS
    order.hide_address = @cart.shippingaddress.hide_or_show(order.shipping_type) if @cart.shippingaddress
    if (type == "Gateway Paypal" || type == "Gateway Moneris") && transaction
      order.payment_transaction = transaction
    elsif type == "Amex"
      if order.status != SHIPPING_TYPE_TO_CHECK
        order.status = SHIPPING_TYPE_AWAITING_PAYMENT
      end
    else
      order.paypal_transaction = transaction
    end


    if @cart.shipping_type.to_i == SHIPPING_PICKUP.to_i || @cart.shipping_type.to_i == SHIPPING_RUSH_PICKUP.to_i

      # @cart.shipping_type = SHIPPING_BASIC
      @addrs               = Address.new()
      @addrs.name          = @cart.shippingaddress.name || "Izishirt"
      addr_to_dup          = Address.find(PickUpStore.find(@cart.pickup_address).address_id)

      @addrs.address1      = addr_to_dup.address1
      @addrs.address2      = addr_to_dup.address2
      @addrs.province_id   = addr_to_dup.province_id
      @addrs.province_name = addr_to_dup.province_name
      @addrs.country_id    = addr_to_dup.country_id
      @addrs.name          = @cart.shippingaddress.name || "Izishirt"
      @addrs.zip           = addr_to_dup.zip
      @addrs.phone         = @cart.billingaddress.phone
      @addrs.town          = addr_to_dup.town

      order.shipping       = @addrs
      order.pick_up        = true
    end


    order.ordered_products.delete_if { |x| !@cart.items.map { |i| i.product.checksum }.include?(x.checksum) }

    order.user_credit = @cart.user_credit - @cart.final_credit_balance
    order.user.update_attribute("available_credit", @cart.final_credit_balance)


    order.save

    if confirm
      active_product_coupons(order)
    end

    # empty_cart if confirm == true


  end

  def create_order
    user_id       = session[:user_id] || session[:guest_id]
    @customer     = User.find(user_id)
    @cart         = get_cart
    #rate = CurrencyExchange.currency_exchange(100,session[:currency], "CAD")/100.0
    #@total = @cart.grandtotal*rate

    # Save order in database
    order         = Order.find_or_create_by_id(@cart.order_id)
    order.user_id = user_id

    #detect online seller
    if session[:rfs]
      order.online_seller = session[:rfs].to_i
    end

    if @cart.shipping_type.to_i == SHIPPING_PICKUP.to_i ||
        @cart.shipping_type.to_i == SHIPPING_RUSH_PICKUP.to_i
      @addrs          = Address.new()
      @addrs.address1 = "1625 Rue chabanel ouest"
      @addrs.province = Province.find_by_name("Quebec")
      @addrs.country  = Country.find_by_name("Canada")
      @addrs.name     = @cart.shippingaddress.name || "Izishirt"
      @addrs.zip      = "H4N 2S7"
      @addrs.phone    = "5144951771"
      @addrs.town     = "Montreal"
      order.pick_up   = true
    else
      @addrs        = @cart.shippingaddress
      order.pick_up = false
    end

    # Very important to get the exact date creation because there is a find_or_create !
    order.created_on = Date.today
    order.created_at = Time.current

    if session[:from_user] && User.exists?({:username => session[:from_user]})
      order.refering_user = User.find_by_username(session[:from_user])
    end

    order.custom_client_email = @cart.custom_email_client
    order.billing             = @cart.billingaddress
    order.shipping            = @addrs
    order.total_price         = @cart.grandtotal.nil? ? 0 : @cart.grandtotal

    p_ship                    = @cart.shipping

    order.total_shipping      = p_ship - @cart.shipping_rebate(p_ship)
    order.total_taxes         = @cart.taxes+@cart.country_taxes
    order.total_rebate        = @cart.total_rebate
    order.status              = 0
    begin
      order.curency_id = Currency.find_by_label(@cart.get_currency).id
    rescue
      order.curency_id = Currency.find_by_label(session[:currency]).id
    end
    order.language_id        = session[:language_id]
    order.signature_required = !params[:cb_signature].nil? ? true : false
    order.shipping_type      = @cart.shipping_type
    order.xmas = 1 if @cart.shipping_type.to_i == SHIPPING_CHRISTMAS
    #order.bulk_order_id = @cart.bulk_order_id

    if @cart.shippingaddress
      order.hide_address = @cart.shippingaddress.hide_or_show(order.shipping_type)
    else
      order.hide_address = false
    end

    #order.bulk_order_id = @cart.bulk_order_id

    begin
      order.entry_uri = cookies[:entry_uri]
    rescue
    end

    #Update Coupon Code and attach coupon code to order if present
    if @cart.code && @cart.code != "" && @cart.code != "User Credit"
      coupon            = Coupon.find_by_code(@cart.code)
      order.coupon_code = @cart.code
      coupon.update_attribute(:currency_off, coupon.currency_off-@cart.rebate) if coupon.gift
      coupon.update_attributes({:currency_off => 0, :active => 0}) if coupon.gift && coupon.currency_off <= 0
    end

    order.ordered_products.delete_if { |x| !@cart.items.map { |i| i.product.checksum }.include?(x.checksum) }
    @cart.items.each { |x|
    #Ensure that the quantity in the order is what is displayed in cart
      x.product.quantity = x.quantity
      order.ordered_products << x.product
    }

    if !session[:user_id] #Save guest informations
      order.guest_email            = @cart.guest_email
      order.guest_wants_newsletter = @cart.guest_wants_newsletter
    end

    order.checkout_comment = @cart.comments

    order.save

    @order_id = order.id


    @cart.order_id = order.id
  end

  def prepare_lang_stuff
    @checkout_locale      = session[:language]
    @checkout_language_id = session[:language_id]

  end

  def set_layout

    prepare_lang_stuff

    if params[:action] == "show_brief_cart" || params[:action] == "brief_address"
      return "brief_checkout"
    elsif params[:onsite] && params[:store_id]


      setup_menu
      return params[:iframe] || params[:flash_iframe] ? "iframe_boutique" : "custom_boutique"
    elsif params[:action] == "confirmation" || params[:action] == "paypal_confirmation"
      return "izishirt_2011"
    else
      return "checkout"
    end

  end

  def set_protocol

    return if request.post?

    #SSLCHANGE
#    if ENV['RAILS_ENV'] == "production"
#      redirect_to params.merge(:protocol => "https://", :host=>"www.#{@DOMAIN_NAME}", :lang=>print_lang_flash_new) unless (request.ssl? or local_request?)
#      return unless (request.ssl? or local_request?)
#    end
    prepare_lang_stuff

    if @checkout_locale == 'fr' && params[:onsite] && !request.url.match("/fr/") && @DOMAIN_NAME=='izishirt.ca'
      redirect_to "/fr"+request.request_uri
      return
    end
  end

  # Set the required environment to run the checkout module
  def set_environment

    @in_checkout = true
    require 'checkout-config.rb'

    case params[:action]
      when 'show_cart' :
        @step = 1
      when 'choose_login' :
        @step = 2
      when 'address' :
        @step = 2
      when 'payment' :
        @step = 3
      when 'confirmation' :
        @step = 3
      else
        @step = 0
    end

    @user_is_logged_in = !(session[:user_id].nil?)

    return true
  end


  def check_big_online_order_to_call(order)
    begin
      if order.total_price >= 150 && !order.bulk_order?
        SendMail.deliver_big_online_order_notification(order)
      end
    rescue
    end
  end


  # Check to see if the current user has any addresses saved in the DB or return a new one if not.
  def check_for_saved_addresses(type)
    return Address.new if session[:user_id].nil?
    u = User.find(session[:user_id])
    case type
      when 1 :
        return (u.billing_addresses && u.billing_addresses.length > 0) ? u.billing_addresses[0] : Address.new
      when 2 :
        return (u.shipping_addresses && u.shipping_addresses.length > 0) ? u.shipping_addresses[0] : Address.new
    end
  end

  # Save the address information
  def save_address
    @cart = get_cart
    @cart.sameaddress = "false" if !params[:sameaddress]
    @cart.sameaddress = "true" if params[:sameaddress]
    @cart.billingaddress = Address.new(params[:billing]) if params[:billing]

    if @cart.sameaddress == "true"
      @cart.shippingaddress = @cart.billingaddress
    else
      @cart.shippingaddress = Address.new(params[:shipping]) if params[:shipping]
    end
  end

  def create_ordered_zone_artwork(zone, doc, artwork_tag_name)
    if doc.elements[artwork_tag_name]
      art                 = OrderedZoneArtwork.new()

      art.ordered_zone_id = zone.id

      if  (doc.elements[artwork_tag_name].attributes['userUpLoadImage'] == 'true' or doc.elements[artwork_tag_name].attributes["id"].match('_'))
        art.uploaded_image_id = doc.elements[artwork_tag_name].attributes["id"]
      else
        art.image_id = doc.elements[artwork_tag_name].attributes["id"]
      end

      art.artwork_printtype   = doc.elements[artwork_tag_name].attributes["printtype"]
      art.artwork_hreflection = doc.elements[artwork_tag_name].attributes["hreflection"]
      art.artwork_vreflection = doc.elements[artwork_tag_name].attributes["vreflection"]
      art.artwork_rotation    = doc.elements[artwork_tag_name].attributes["rotation"]
      art.artwork_y           = doc.elements[artwork_tag_name].attributes["y"]
      art.artwork_x           = doc.elements[artwork_tag_name].attributes["x"]
      art.artwork_zoom        = doc.elements[artwork_tag_name].attributes["zoom"]

      zone.ordered_zone_artworks << art
    end
  end

  def copy_promotion_images sex, color, checksum, created_on
    #copy product images into checksum folder

    path_created_on = path_ordered_product(created_on)

    FileUtils.mkdir_p(File.join("public/izishirtfiles/#{path_created_on}", checksum))
    FileUtils.ln(File.join("public/images/promotion/", sex, "#{color}.jpg"), File.join("public/izishirtfiles/#{path_created_on}", checksum, 'preview.jpg'), {:force => true})
    FileUtils.ln(File.join("public/images/promotion/", sex, "back", "blank.jpg"), File.join("public/izishirtfiles/#{path_created_on}", checksum, "#{checksum}-back.jpg"), {:force => true})
    for side in ['-front', '-left', '-right']
      FileUtils.ln(File.join("public/images/promotion/", sex, "#{color}.jpg"), File.join("public/izishirtfiles/#{path_created_on}", checksum, checksum+side+'.jpg'), {:force => true})
    end
  end


  def get_continue_link
    if params[:onsite] && params[:onsite] == "true" && params[:store_id]
      #Iframe Boutique
      if params[:iframe] && params[:iframe] == "true"
        @continue_link = Store.find(params[:store_id]).user.create_my_url(@DOMAIN_NAME)
        @continue_link +="/my/iframe_boutique"
        #Iframe Flash Shop
      elsif params[:flash_iframe] && params[:flash_iframe]
        @continue_link = Store.find(params[:store_id]).user.create_my_url(@DOMAIN_NAME)
        @continue_link +="/my/iframe_flash_shop?onsite=true"
        #Regular Boutique
      else
        @continue_link = Store.find(params[:store_id]).user.create_my_url(@DOMAIN_NAME)
        @continue_link +="/my/boutique"
      end
    elsif cookies[:iframe_continue_link] && cookies[:iframe_continue_link].length > 0
      @continue_link = cookies[:iframe_continue_link]
    elsif params['referer']
      @continue_link = Base64.decode64(params['referer'])
    elsif request.referer && (request.referer.include?("/my/") ||
        request.referer.include?(t(:boutique_flash_url_id)))
      @continue_link = request.referer
    else
      @continue_link = "#{@URL_ROOT}#{create_tshirt_url()}"
    end
  end

  def format_hash_error(hash_error)
    str  = "<br/>"
    keys = hash_error.keys
    keys.each do |k|
      hash_error["#{k}"].each do |s|
        str += k + " " + s + "<br/>"
      end
    end
    return str
  end

  def prepare_address

    @cart   = get_cart
    @header = t(:shopping_cart, :locale => @checkout_locale)

    if @cart.coupon_order?
      params[:sameaddress] = "true"
    end

    if params[:address_form] # the address form has been submitted
      save_address
      @cart.guest_email            = params[:guest_email]
      @cart.guest_wants_newsletter = params[:wants_newsletter]
      if params[:sameaddress]
        @cart.sameaddress = "true"
      else
        @cart.sameaddress = "false"
      end
      @cart.sameaddress = params[:sameaddress] ? "true" : "false"
      shipping_type     = params[:radio_shipping].to_i
      if shipping_type != 0 && (!@cart.ca_order? && !@cart.fr_order? && !@cart.us_order?)
        flash[:error] = t(:error_shipping)
      else
        @cart.set_shipping_type(shipping_type)
        # Check for the custom email client:
        @cart.pickup_address = params["pickup_address"].to_i
        @cart.custom_email_client = params[:custom_email_client] if params[:custom_email_client]

        if params[:action] != "brief_address"
          redirect_to :action       =>:payment,
                      :onsite       => params[:onsite],
                      :iframe       => params[:iframe],
                      :flash_iframe => params[:flash_iframe],
                      :store_id     => params[:store_id]
          return
        end
      end
    end

    begin
      @user = User.find(session[:guest_id]) if session[:user_id].nil?
      @user = User.find(session[:user_id]) if session[:user_id]

      @billing  = (@cart.billingaddress || check_for_saved_addresses(1))
      @shipping = (@cart.shippingaddress || check_for_saved_addresses(2))


      if @cart.sameaddress == "false"
        @sameaddress_yes = ''
      else
        @sameaddress_yes = ' checked="checked"'
      end

      @sameaddress_no      = (!@cart.sameaddress) ? ' checked="checked"' : ''
      @sameaddress_display = (@cart.sameaddress) ? 'none' : ''
#      @back                = get_lang_url

      country              = Country.find_by_shortname(session[:country])
      @country_id          = (country && country.shortname != 'EU' && country.shortname != 'IN') ? country.id : -1

      @country_id = 1 if @country_id == -1
      @province_id = -1

      begin
        if session[:province]
          @province_id = Province.find_by_code(session[:province]).id
        else
          @province_id = Province.find_by_country_id(@country_id).id
        end
      rescue Exception => e
        @province_id = -1
      end

      billing_country_id        = @billing.country_id ? @billing.country_id : @country_id
      shipping_country_id       = @shipping.country_id ? @shipping.country_id : @country_id
      @country_address_billing  = @billing.country_id ? Country.find(@billing.country_id) : Country.find(@country_id)
      @country_address_shipping = @shipping.country_id ? Country.find(@shipping.country_id) : Country.find(@country_id)

      populate_countries_provinces_by_country_id(billing_country_id, shipping_country_id)

      prepare_payment if params[:action] == "brief_address"

    rescue Exception => e
      logger.error("jcbeau exception : " + e.to_s)
      url                          = "/checkout2/address"
      session[:original_uri_login] = url
      loginurl                     = "/myizishirt/login"
      redirect_to :controller=>loginurl
    end
  end

  def prepare_payment
    @cart   = get_cart
    @header = t(:shopping_cart, :locale => @checkout_locale)

    if !(@cart.shippingaddress && params[:action] != "brief_address") && !@cart.coupon_order?
      flash[:error] = t(:front_office_checkout_err_storing_addr, :locale => @checkout_locale)
      redirect_to :action => "address"
      return
    end


    #passed_by_address_form = params[:shipping] && params[:billing]

    begin
      @payment_subtotal = @cart.total.to_s
      @payment_shipping = @cart.shipping
    rescue
      @payment_subtotal = 0.0
      @payment_shipping = 0.0
    end

    @back         = "#{Language.print_force_lang(params[:lang])}checkout2/address"
    @confirmation = "#{Language.print_force_lang(params[:lang])}checkout2/confirmation"
    @confirmation+= "?onsite=#{params[:onsite]}" if params[:onsite]
    @confirmation+= "&iframe=#{params[:iframe]}" if params[:iframe]
    @confirmation+= "&flash_iframe=#{params[:flash_iframe]}" if params[:flash_iframe]
    @confirmation+= "&store_id=#{params[:store_id]}" if params[:store_id]

    begin
      @payment_taxes = @cart.taxes
    rescue
      @payment_taxes = 0.0
    end

    @payment_total = @payment_taxes + @payment_subtotal.to_f + (@payment_shipping.to_f - @cart.shipping_rebate(@payment_shipping.to_f))

    # Don't create an order if there is no shipping address

    create_order
  end

  def generate_certificate_html
    @ordered_product = params[:id]
  end

  def active_product_coupons(order)
    # activate coupons !!!

  end

  def send_gift_coupons(order)
    order.ordered_products.each do |op|
      if !op.coupon
        next
      end

      # @ordered_product = op
      # cert_str = render_to_string :action => "generate_certificate_html", :id => op.id, :layout => false
      # p = "/tmp/cert#{op.id}."
      # f = File.open(p + "html", 'w')
      # f.write(cert_str)
      # f.close

      # system("wkhtmltopdf #{p}html #{p}pdf")
      SendMail.deliver_gift_certificate(op, "")
    end
  end

  def check_coupon_code_use(order)
    # Update coupon code use
    begin
      if order.coupon_code && order.confirmed
        order.increment_coupon
      end
    rescue
    end
  end

end
