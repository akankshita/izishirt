# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  require 'open-uri'
  require 'add_country_tax'
  require 'rate'
  require 'uri'

  layout 'izishirt_2011', :except => [:sitemap]

  before_filter :set_headers
  before_filter :set_url_root
  before_filter :set_domain_language
  before_filter :find_username

  before_filter :check_cart_state, :except => [:confirmation, :paypal_confirmation, :lcl_confirmation, :auto_paypal_confirmation]
	before_filter :prepare_cart_summary, :except => [:display_subcategories, :update_marketplace_price, :lcl_auto_confirmation, :auto_paypal_confirmation]
  before_filter :fix_default_canonical_url
  
  filter_parameter_logging :payment


	def check_cart_state

		@cart = get_cart

		if @cart
			begin
				if @cart.order_id
					order = Order.find(@cart.order_id)

					if order.confirmed
						empty_cart
					end
				end
			rescue
			end
    end


  end

  
  
  def find_username


    @logged_in_username = ""
    @logged_in_user = User.find(session[:user_id]) if session[:user_id]
    @logged_in_username = @logged_in_user.username if session[:user_id]
  end


  # Empty the cart in session.
  def empty_cart
    session[:cart] = nil
  end

  def set_headers

    logger.error("TIMER START")
    @timer = Time.now


    @time_start = Time.now
    response.headers['P3P'] = 'CP="CAO PSA OUR"'
  end

  def set_domain_language



	@redirected_to_another_domain = false
do_some_conf_for_country()
    if !request.post? && ((top_domain? || LANGUAGE_SUBDOMAINS.include?(@SUBDOMAIN_NAME)) && params[:lang]) && ! (params[:controller] == "checkout2" && params[:lang] == "es")
      redirect_to params.merge(:lang=>nil), :status=>:moved_permanently
      return
    end
	
	

    if (@DOMAIN_NAME == "izishirtdev.com"  || @DOMAIN_NAME == "izishirt.com" )
if session[:country] != "US"		
		#######################################################
		
		@cart = get_cart
	@cart.items.each do |item1|

	#	params[:id] = item1.product.checksum
		
		begin
		  op = OrderedProduct.find_by_checksum(item1.product.checksum)
		  op.destroy
		rescue
		end

		starting_quantity = @cart.blank_qty

		@cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == item1.product.checksum }
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
		#  validate_coupon(@cart.code)
		  return
		end
		#validate_coupon(@cart.code)
		
	end
		
		########################################################
end
		
      params[:lang] = nil
      session[:lang] = nil
      session[:country] = "US"
      session[:country_long] = "United States"
      @alt_country = 'US'
      session[:currency] = "USD"
      session[:language] = 'en'
      session[:language_id] = 2

      set_locale()
	    do_some_conf_for_country()
	    @redirected_to_another_domain = true
      @meta_content_language = "en-US"



    elsif(@DOMAIN_NAME == "izishirtdev.ca"  || @DOMAIN_NAME == "izishirt.ca" ) && @SUBDOMAIN_NAME == "fr"
	
	
if session[:country] != "CA"	
		#######################################################
		
		@cart = get_cart
	@cart.items.each do |item1|

	#	params[:id] = item1.product.checksum
		
		begin
		  op = OrderedProduct.find_by_checksum(item1.product.checksum)
		  op.destroy
		rescue
		end

		starting_quantity = @cart.blank_qty

		@cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == item1.product.checksum }
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
		#  validate_coupon(@cart.code)
		  return
		end
		#validate_coupon(@cart.code)
		
	end
		
		########################################################
end		
	
	
	
      params[:lang] = nil
      session[:lang] = nil

      session[:currency] = "CAD"
      session[:language] = 'fr'
      session[:language_id] = 1
      @alt_country = 'CA'
      session[:country] = 'CA'
      session[:country_long] = "Canada"
      @meta_content_language = "fr-ca"

      set_locale()
	    do_some_conf_for_country()
      @redirected_to_another_domain = true

    
    elsif(@DOMAIN_NAME == "izishirtdev.ca"  || @DOMAIN_NAME == "izishirt.ca" ) && @SUBDOMAIN_NAME == "frch"
		
if session[:country] != "FR"	
		#######################################################
		
		@cart = get_cart
	@cart.items.each do |item1|

	#	params[:id] = item1.product.checksum
		
		begin
		  op = OrderedProduct.find_by_checksum(item1.product.checksum)
		  op.destroy
		rescue
		end

		starting_quantity = @cart.blank_qty

		@cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == item1.product.checksum }
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
		#  validate_coupon(@cart.code)
		  return
		end
		#validate_coupon(@cart.code)
		
	end
		
		########################################################
end		
		
		
      params[:lang] = nil
      session[:lang] = nil

      session[:currency] = "EUR"
      session[:language] = 'fr'
      session[:language_id] = 1
      @alt_country = 'FR'
      session[:country] = 'FR'
      session[:country_long] = "France"
      @meta_content_language = "fr-ca"

      set_locale()
	    do_some_conf_for_country()
      @redirected_to_another_domain = true

    
	elsif(@DOMAIN_NAME == "izishirtdev.ca"  || @DOMAIN_NAME == "izishirt.ca" ) && @SUBDOMAIN_NAME == "www"
      
if session[:country] != "CA"	  
	  
		#######################################################
		
		@cart = get_cart
	@cart.items.each do |item1|

	#	params[:id] = item1.product.checksum
		
		begin
		  op = OrderedProduct.find_by_checksum(item1.product.checksum)
		  op.destroy
		rescue
		end

		starting_quantity = @cart.blank_qty

		@cart.items.each_index { |i| @item_idx = i if @cart.items[i].product.checksum == item1.product.checksum }
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
		#  validate_coupon(@cart.code)
		  return
		end
		#validate_coupon(@cart.code)
		
	end
		
		########################################################
end		
	  
	  params[:lang] = nil
      session[:lang] = nil

      session[:currency] = "CAD"
      session[:language] = 'en'
      session[:language_id] = 2
      session[:user_id] = 70
      @alt_country = 'CA'
      session[:country] = 'CA'
      session[:country_long] = "Canada"
      @meta_content_language = "en-ca"

      set_locale()
	    do_some_conf_for_country()
      @redirected_to_another_domain = true

    end

do_some_conf_for_country()
	logger.error("country = #{session[:country]}, lang = #{session[:language]}")


  end

	##############################################################################################
	# CURRENCY, LANG, COUNTRIES DEFINITION
	##############################################################################################
	def country_can_access_to(from_country, to_country)
		return Country.country_can_access_to(from_country, to_country)
	end

	def countries_from_country(from_country)
		return Country.countries_from_country(from_country)
	end

	def currency_of(country)
		return Country.currency_of(country)
	end

	def currency_available_to(label)
		return Country.currency_available_to(label)
	end

	def only_langs_of(country)
		return Country.only_langs_of(country)
	end

	def can_access_to_langs(country, logged_in_user)
		return Country.can_access_to_langs(country, logged_in_user)
	end
	
	def can_access_to_lang?(country, lang)
		return Country.can_access_to_lang?(country, lang)
	end

	def lang_infos_for_layout()
		return Country.layout_infos(session[:country])
	end


	def fix_default_canonical_url
	
		if session[:country] == "CA" && session[:language]=="fr"
			@canonical_begin_url= "http://fr.izishirt.ca"
		else
			if session[:country] == "CA"
				@canonical_begin_url= "http://www.izishirt.ca"
			else
				if  session[:country] == "FR"
					@canonical_begin_url= "http://frch.izishirt.ca"
				else
					@canonical_begin_url= "http://www.izishirt.com"
				end
			end 
		end
	
		#@canonical_begin_url = @URL_ROOT
	end


  def set_url_root

    domain = request.domain#request.domain.downcase
    begin
      sub = request.subdomains[0]
    rescue
      sub = "www"
    end


    if (VALID_HOSTS.include?(domain) && ENV['RAILS_ENV'] == 'production') || (DEV_HOSTS.include?(domain) && ENV['RAILS_ENV'] != 'production')
      @SUBDOMAIN_NAME = sub
      root_sub = (@SUBDOMAIN_NAME == "www" || LANGUAGE_SUBDOMAINS.include?(@SUBDOMAIN_NAME)) ? @SUBDOMAIN_NAME : "www"
	  if session[:country] && session[:country]=="FR"
		root_sub="frch"
	  end
      @URL_ROOT = "http://#{root_sub}." + domain
      #SSLCHANGE
      @SECURE_URL_ROOT = "http://www." + domain
      @DOMAIN_NAME = domain
      @FULL_DOMAIN_NAME = "#{root_sub}.#{domain}"
      

    else
      @SUBDOMAIN_NAME = "www"
      @URL_ROOT = URL_ROOT
      @SECURE_URL_ROOT = SECURE_URL_ROOT
      @DOMAIN_NAME = "izishirt.ca"
      @FULL_DOMAIN_NAME = "www.izishirt.ca"

    end
Rails.logger.error("\n\n\nFULL DOMAIN NAME = #{@FULL_DOMAIN_NAME}\n\n\n")

    
  end

  def authorize
    user = User.find_by_id(session[:user_id])

    unless user && user.active
      session[:original_uri_login] = request.request_uri
      flash[:notice] = t(:application_ctl_login)
      redirect_to(:controller => "/login" )
    end
  end

  def find_username
    @logged_in_username = ""
    @logged_in_user = User.find(session[:user_id]) if session[:user_id]
    @logged_in_username = @logged_in_user.username if session[:user_id]
  end


  def dont_lang_redirect
    return top_domain? || request.post? || LANGUAGE_SUBDOMAINS.include?(@SUBDOMAIN_NAME) || params[:controller].index("create/") == 0 || params[:controller] == "erreur404" || params[:controller] == "landing_page" || params[:controller] == "facebook"
  end

  def  top_domain?
    return TOP_DOMAINS.include?(@DOMAIN_NAME)
  end

  def check_homepage_without_lang

	# oh and check if he is a user from CANADA
    #if params == {"action"=>"izishirt_2011", "controller"=>"display"}
    if ! params[:lang] && session[:lang] && session[:lang] != "" && ! params[:force_lang] && (! @logged_in_user || (@logged_in_user.country != "CA"))
      if !top_domain?
        redirect_to params.merge({:lang => session[:lang]})
        return true
      end
    end
    #end

    return false
  end


  def display_country
    if ! session[:country_long] || session[:country_long] == ""
      return "Canada"
    end

    return session[:country_long]
  end
  def get_country_for_meta_title
    if  session[:language] == "fr" || (@alt_country.downcase == "ca" && session[:language] == "en")
      return " " + display_country
    else
      return ".com"
    end
  end

	def do_some_conf_for_country()
		# some initializations for langs, countries:
		@langs_available = can_access_to_langs(session[:country], @logged_in_user)
		@currency = currency_of(session[:country])
		session[:currency] = @currency.label
		@lang_infos_for_layout = lang_infos_for_layout()
	end
  
  
  def prepare_cart_summary
    cart = session[:cart] ||= Cart.new()
    cart.currency = session[:currency]
    cart.country  = session[:country]
    @item_count = cart.total_qty
    case @item_count
    when 0:
      @human_cart = t(:cart_display_no_product)
    when 1:
      @human_cart = cart.total_qty.to_s + ' ' + t(:cart_display_product)
    else
      @human_cart = cart.total_qty.to_s + ' ' + t(:cart_display_product).pluralize
    end

  end

  def redirect_language_url()
    if !top_domain? && @SUBDOMAIN_NAME=="www" and params[:controller] == "display" and params[:action] == "izishirt_2011" and params[:lang].nil? and session[:language] == "fr"
      redirect_to :controller=>'/display', :action=>'izishirt_2011', :host=>"fr.#{@DOMAIN_NAME}"
    end
  end

  def set_locale
    I18n.locale = "#{session[:language]}-#{session[:country]}"
  end


  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "/usr/local/bin/rake #{task} #{args.join(' ')} --trace 2>&1 >> #{Rails.root}/log/rake.log &"
  end

  private

  def populate_select_design_validation_states()
    return DESIGN_VALIDATION_STATE_IDS.map { |id| [Image.approval_states(session[:language])[id], id] }
  end

  def populate_select_design_decline_reasons(language_id)
    return []
  end

  def order_by_top_rated_images()
    return "(select count(*) from sub_categories where category_id = images.category_id AND localized_images.sorting_rate >= 1) DESC, localized_images.sorting_rate DESC, images.id DESC"
  end

  def get_top_rated_images(category_id, country_id, limit = NB_TOP_RATED_DESIGNS, by_staff_pick = false, lang_id = session[:language_id])

    if by_staff_pick
      order_by = "localized_images.sorting_rate DESC, images.id DESC"
    else
      order_by = order_by_top_rated_images()
    end
    
    if by_staff_pick
      category_id = LocalizedCategory.find_by_name("custom_staff_picks_fr").category_id
    end

    if category_id
      by_staff_pick_or_category_ids = "localized_images.category_id = :category_id AND "
    else
      by_staff_pick_or_category_ids = ""
    end

    top_rated_images = Image.find :all,
      :include => [:localized_images],
      :conditions => ["#{by_staff_pick_or_category_ids} active = :active AND pending_approval = :pending_approval AND is_private = :is_private AND " +
                      "images.id = localized_images.image_id AND localized_images.country_id = :country_id AND localized_images.language_id = :language_id",
                      {:category_id => category_id, :active => 1, :pending_approval => 1, :is_private => 0, :country_id => country_id,
                      :language_id => lang_id}],
      :order => "#{order_by} LIMIT #{limit}"

    return top_rated_images
  end

  def build_ids(category)
    ids = []
    ids << category.id.to_i
    category.sub_categories.each do |sub_category|
      ids << build_ids(sub_category) if sub_category.active
    end
    ids.flatten
  end

  # Get the custom category
  def get_custom_category(str_id, language_id=session[:language_id])
    language = Language.find(language_id)

    begin
      localized = LocalizedCategory.find_by_name("#{str_id}#{language.shortname}")

      return Category.find(localized.category_id)
    rescue
      localized = LocalizedCategory.find_by_name("#{str_id}en")

      return Category.find(localized.category_id)
    end
  end

  def path_ordered_product(date)
    return OrderedProduct.path_ordered_product(date)
  end

  def get_order_status_label(status)
    Order.order_statuses(session[:language])[status]
  end
  
  def assignment_states(page)
    if page == "artwork_verification"
      return ArtworkOrderAssignmentState.find(:all, :conditions => ["str_id IN ('artworks_problem', 'artworks_sent')"]).map {|state| [state.str_id, state.id]}
    elsif page == "artwork_assignment"
      return ArtworkOrderAssignmentState.find(:all, :conditions => ["str_id IN ('artworks_ready')"]).map {|state| [state.str_id, state.id]}
    elsif page == "artworks_to_process" || page == "artworks_problem"
      return [] # ArtworkOrderAssignmentState.find(:all, :conditions => [""]).map {|state| [state.str_id, state.id]}
    elsif page == "production/artworks_to_process"
      return ArtworkOrderAssignmentState.find(:all, :conditions => ["str_id IN ('artworks_ready')"]).map {|state| [state.str_id, state.id]}
    else
      return []
    end
  end
  
  def populate_artwork_department_assignment_states(is_production = false)
    
    production = is_production ? "production/" : ""
    
    if @user_is_artwork_member
      begin
        assignment = ArtworkOrderAssignment.find_by_order_id(@order.id)
      rescue
        assignment = nil
      end

      if assignment && assignment.artwork_order_assignment_state
        if assignment.artwork_order_assignment_state.str_id == "artworks_ready"
          page_str_id = "#{production}artwork_verification"
        elsif ["artworks_to_process", "artworks_problem"].include?(assignment.artwork_order_assignment_state.str_id)
          
          page_str_id = "#{production}artworks_to_process"
        end
        
        return assignment_states(page_str_id)
      end
    end
    
    return []
  end
  
  def nb_artwork_comments_in_orders(orders)
    nb = 0
    
    orders.each do |order|
      nb += order.comments_per_comment_type("artwork", 1, 10000000).length
    end
    
    return nb
  end
  
  
  
  def generate_garments_according_to_order_and_model(listing, ordered_products, printer_id)
    OrderGarmentListing.generate_garments_according_to_order_and_model(listing, ordered_products, printer_id, 2)
  end
  
  def generate_garments_according_to_model(listing, ordered_products, printer_id)
    return OrderGarmentListing.generate_garments_according_to_model(listing, ordered_products, printer_id, 2)
  end
  
  def populate_for_generate_list()

	listing = nil

    begin
      garments_according_to_order_and_model = generate_garments_according_to_order_and_model(nil, params[:ordered_product], params[:printer])
      garments_according_to_model = generate_garments_according_to_model(nil, params[:ordered_product], params[:printer])
    rescue Exception => e
      garments_according_to_order_and_model = []
      garments_according_to_model = []
    end

	@garments_according_to_order_and_models = {}
	@garments_according_to_models = {}
	@garments_according_to_order_and_models[listing] = garments_according_to_order_and_model
	@garments_according_to_models[listing] = garments_according_to_model

  end

  def remove_accents(str)
    #return str.mb_chars.normalize(:kd).gsub(/[^-x00-\x7F]/n, '').to_s
    #return str.gsub(/[^a-z._0-9\ -]/i, "").tr(".", "_").gsub(/(\s+)/, "_").downcase
    return str

  end

  def create_callname(string)
    return StringUtil.create_callname(string)
  end

  def pretty_escape_url(str)
    return StringUtil.pretty_escape_url(str)
  end

  def pretty_escape(str)
    return StringUtil.pretty_escape(str)
  end

  def get_id_from_create_shirt_url(parameter)
    return StringUtil.get_id_from_url(parameter)
  end

  def root_categories()
	where = ["categories.category_type_id = 3 and categories.active = 1 and not exists (select category_id from sub_categories where sub_category_category_id = categories.id) AND is_custom_category = 0 "]
	tmp_cats = Category.find(:all, :conditions => where, :order => :position, :include => [:sub_categories , :localized_categories])
	return tmp_cats
  end

  def print_force_lang()
    return Language.print_force_lang(params[:lang])
  end

	def escape_string(str)
		return str.gsub("\"", "")
	end


  def create_tshirt_url()
    return "#{Language.print_force_lang(params[:lang])}#{t(:create_shirt_url)}"
  end

  # Get the cart from session or create a new one if none is present
  def get_cart
    c = session[:cart] ||= Cart.new
    c.currency = session[:currency]
    begin
      c.billingaddress
      c.billingaddress.phone
      c.shippingaddress
      c.shippingaddress.phone
    rescue
      c.billingaddress = nil
      c.shippingaddress = nil
    end
    c.shipping_type = SHIPPING_BASIC if c.shipping_type.nil?
    return c
  end


  def default_flash_vars(bulk_mode='0')

	language = @store ? @store.locale : session[:language]
	lang = (@store && @store.locale == "fr") ? "fr" : print_lang_flash_new


  logger.error("CURRENCY SYMBOL???")
    vars = "sessionVar=#{request.session_options[:id]}"
    vars+= "&currencySymbol=#{get_currency_symbol}"
    vars+= "&currencySymbolPosition=#{get_currency_position}"
    vars+= "&sessionLanguage=#{language}"
    vars+= "&sessionLang=#{lang}"
    vars+= "&url_base=#{@URL_ROOT}"
    vars+= "&bulkMode=#{bulk_mode}"
    vars+= "&tabColor=f37e1f"
    vars+= "&buttonColor=3b2053"

    vars+= "&borderColor=3b2053"
    vars+= "&priceColor=3b2053"
    return vars
  end

  def print_lang_flash_new
    return "fr" if @SUBDOMAIN_NAME == "fr"
    return "#{@SUBDOMAIN_NAME}" if LANGUAGE_SUBDOMAINS.include?(@SUBDOMAIN_NAME)
    return params[:lang] if params[:lang]
    return ""
  end


	def generate_invoice(order)
		#begin
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
		#rescue
		#end
	end


  def get_currency_symbol
    return "$"
  end

  def get_currency_position
    return session[:language] == "fr" ? "right" : "left"
  end

  def string_to_search(str)
    return str.parameterize("+")
  end

  def search_url(search,type)
    lang = params[:lang] ? params[:lang] + "/" : ""
    if session[:language] == "fr"
      return @URL_ROOT + "/" + lang + type + "+" + search
    else
      return @URL_ROOT + "/" + lang + search + "+" + type
    end
  end


end
