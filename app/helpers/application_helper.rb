# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include GetText

  def get_phone_number(country = nil)

    north_american_toll_free = "514 495 1771<br/>1 (888) 800-5787 (" +t(:no_fees) + ")"
    if country.nil? then country = session[:country] end
    case country.upcase
      when "US"
       north_american_toll_free
      when "CA"
        #return "1 514 658 4449"
        #session[:language] == "fr" ? "1 514 286 2446" : north_american_toll_free
        #north_american_toll_free
        north_american_toll_free
      else
        north_american_toll_free
    end
  end

	 def print_blank_colors(section,model)

		links = []

		model.colors.each do |c|

			if ! c
				next
			end

			links << (link_to image_tag("/izishirtfiles/colors/#{c.preview_image}", {:id => "#{model.id}_#{c.id}", :class => 'aparelColor', :height => 10, :width => 10, :alt => "" }), model_buy_blank_url(model.id, c.id))

			if links.length > 6
				break
			end
		end

		return links
	  end

	def options_for_model_categories()
		return [["custom", "custom"]]
	end

  def toll_free
    if (session[:language] == 'en' && (session[:country] == "US" || session[:country] == "CA")) || session[:country] == "CA"
      return t(:toll_free) + ':'
    else
      return ""
    end
  end

  def get_country_name(country = nil)
	if country.nil? then country = session[:country] end

	begin
		return Country.find_by_shortname(country.upcase).name
	rescue
		return "Canada"
	end
  end

  def params_hash(lang,country)
    f_lang_param = ! lang ? "en" : nil
	dev_lang = lang

	first_host_part = @username

	if ! first_host_part || first_host_part == ""
		first_host_part = "www"
	end

    if country == "US"
      host = "#{first_host_part}.izishirt.com"
      lang = nil
      dev_lang = "us"
    else
      host = "#{first_host_part}.izishirt.com"
    end

    if RAILS_ENV != "production"
      t = params.merge({:controller => "/#{params[:controller]}", :action => params[:action], :lang => dev_lang, :force_lang => f_lang_param,
      :search => params[:search] ? params[:search] : nil,
      :page => params[:page] ? params[:page] : nil})
    elsif @controller.controller_name != 'local'
      t = params.merge({:host=>host, :controller => "/#{params[:controller]}", :action => params[:action], :lang => lang, :force_lang => f_lang_param,
      :search => params[:search] ? params[:search] : nil,
      :page => params[:page] ? params[:page] : nil})
    else
      t = url_for :host=>host, :controller => "/display", :action => "izishirt_2011", :lang => lang, :force_lang => f_lang_param

    end

    return t
  end

  def country_home(lang,country)
    f_lang_param = ! lang ? "en" : nil
	dev_lang = lang

	first_host_part = @username

	if ! first_host_part || first_host_part == ""
		first_host_part = "www"
	end

    main_domain = (RAILS_ENV =="production") ? "izishirt" : "izishirtdev"

    if country == "US"

	    host = "http://www.#{main_domain}.com/"

    else
      host = "http://#{first_host_part}.#{main_domain}.ca/"
		if country=="FR"
	
			host = "http://frch.#{main_domain}.ca/"
		else
	
		  if lang == "fr"
			if first_host_part != "www" && !LANGUAGE_SUBDOMAINS.include?(first_host_part)
			  host += "fr"
			else 
				host.sub!("www", "fr")
			end

		  end
		end
    end

    t = host

    return t
  end

  def link_to_with_sort(name, sort_field, options = {}, html_options = nil)
    current_sort = params[:order].split(' ')[0] unless params[:order].nil?
    current_way = params[:order].split(' ')[1] unless params[:order].nil?

    if (sort_field == current_sort)
      way = (current_way == 'desc') ? 'asc' : 'desc';
      arrow = "&nbsp;#{image_tag('admin-arrow-th.gif')}" 
    else
      way = 'asc'
      arrow = ''
    end

    options[:order] = "#{sort_field} #{way}"
    return "#{link_to(name, options, html_options)}#{arrow}"
  end


  def analytics_number
    if @DOMAIN_NAME == "izishirt.ca" && session[:language] == 'en'
      return 'UA-23153029-1'
    elsif @DOMAIN_NAME == "izishirt.ca" && session[:language] == 'fr'
      return 'UA-23153029-2'
    else
      return 'UA-23153029-3'
    end
  end

  def get_title_link_adding(text, add)

	if text == nil
		text = ""
	end

	if add == nil
		add = ""
	end

    if session[:language] == 'fr'
      return add + " " + text
    end
    return text + " " + add
  end
	
  def create_tshirt_title(image)
   t_name = image ? image.name : ''
   res = t(:meta_title_flash_seo, :name=>t_name, :country=>session[:country_long]) #t_name << t(:create_tshirt_title)
  end
  
  def create_shop1_title(image)
   my_id = image.id
   t_name = image.name
   d_name = image.user.username
   c_name = image.category.nil? ? "" : image.category.localized_categories.find_by_language_id(session[:language_id]).name
   res = t(:display_shop1_title).gsub(/SHIRT_NAME/, t_name)
   res = res.gsub(/DESIGNER_NAME/,d_name)
   res = res.gsub(/CATEGORY_NAME/,c_name.capitalize)
  end
  
  def create_shop2_title(image)
   my_id = image.id
   t_name = image.name.nil? ? "" : image.name
   d_name = ""
   res = t(:display_shop2_title).gsub(/SHIRT_NAME/, t_name)
   res = res.gsub(/DESIGNER_NAME/,d_name)
  end 
  
  def get_page_title(image)
	my_action = params[:action]
	if my_action == 'create_tshirt' #&& image
		res = create_tshirt_title(image)  
	elsif my_action == 'shop1' && image
		res = create_shop1_title(image)
	elsif my_action = 'shop2' && image
		res = create_shop2_title(image)
	else
    if ! session[:country_long] || session[:country_long] == ""
      session[:country_long] = "Canada"
    end

		res = t(:meta_title_default, :country=>session[:country_long].capitalize)
	end
  end

  def display_category_select(category,selected,depth=0)
    ret = "<option value='#{category.id}'"
    ret += " selected='selected' " if selected.to_s == category.id.to_s
    ret += ">"
    ret += "&nbsp;&nbsp;&nbsp;" * depth
    ret += "#{category.local_name(session[:language_id])}</option>"
    category.sub_categories.each do |sub_category| 
      ret += display_category_select(sub_category,selected,depth+1)    
    end
    ret
  end
  
  
		
  #check if custom dir exist
  def DoesCustomDirExist(id)
      res = false
	  path = CUSTOM_ORDER_PATH  + id
	  if File.exists?(path) && File.directory?(path)
		res = true
	  end
	  return res
	end
 
  #There are 2 possible files upload with custom orders, we want to check if the file exist and if so return string with path.
  def CustomFilePath(id,num)
	  ret = '';
      begin
		  dirname = CUSTOM_ORDER_PATH + id
		  dir = Dir.entries(dirname)
			  dir.each do |file|
			  # do something with dirname/file
			  temp = 'file'+ num
			  if(file.include? temp)
			      ret =  '../../../' + CUSTOM_ORDER_DOWNLOAD_PATH + id + '/' + file
			  end
		  end
	  rescue
		  return '';
	  end
	 return ret; 
  end

  def get_currency_symbol(currency = session[:currency])
	
	if currency
		curr=Currency.find_by_label(currency)
		unit = curr.symbol
	else
		unit = "$"
	end
	
    return unit
  end

  def number_to_currency_custom(number, opt={})

    if opt[:currency]
      currency = opt[:currency]
    end
    
    if opt[:language]
      language = opt[:language]
    end
    
    # session are not defined with sendmail...
    begin
      currency ||= session[:currency]
    rescue
    end
    
    # session are not defined with sendmail...
    begin
      language ||= session[:language]
    rescue
    end
    
    begin
      if language == 'fr'
        format = "%n %u"
      else
        format = "%u%n"
      end
    rescue
      format = "%u%n"
    end
	
	#if session[:country] && session[:country] == "FR"
	#	session[:currency] = "EUR"
	#end	
		
	#if session[:currency]
	#	curr=Currency.find_by_label(session[:currency])
	#	unit = curr.symbol
		
	#else
		if session[:country] && session[:country] == "FR"
		session[:currency] = "EUR"
		unit = "&euro;"
		else
			if  session[:country] && session[:country] =="CA"
			session[:currency] = "CAD"
			unit = "$"
			else
			session[:currency] = "USD"
			unit = "$"
			end
		end
	#end
	
	#curr=Currency.find_by_label(session[:currency])
	#	unit = session[:currency]  #curr.symbol
	#session[:currency] = "CA"
	#currency = session[:currency]
    #unit = "$"
	
    number_to_currency(number, :unit => unit, :precision=>2, :delimiter=>" ", :separator=>".", :format => format)
  end
  
  def path_ordered_product(date)
    return OrderedProduct.path_ordered_product(date)
  end

  def get_order_status_label(status)
    Order.order_statuses(session[:language])[status]
  end

  def text_to_tab(text)
    result = "<table cellspacing=10>"
    lines = text.split("\r\n")
    lines.each do |l|
      result += "<tr>"
      cells = l.split("\t")
      cells.each do |c|
        result += "<td style='min-width:150px'>" + c + "</td>"
      end
      result += "</tr>"
    end
    result += "</table>"
    return result
  end

  def nl2br(text)
    text = text.gsub(/\r\n/, "<br/>")
    return text.gsub(/\n/, "<br/>")
  end

  
  def get_sort_way(sort_field, search_name = "search_order")
    current_sort = params[search_name].split(' ')[0] unless params[search_name].nil?
    current_way = params[search_name].split(' ')[1] unless params[search_name].nil?
    
    if (sort_field == current_sort)
      way = (current_way == 'desc') ? 'asc' : 'desc';
    else
      way = 'asc'
    end
    
    return way
  end
  
  def display_printer_name(order)
    begin 
      order.assigned_to.username 
    rescue 
      "no_printer"
    end   
  end
  
  def display_user_name(order, language_id = nil)
    
    begin
      language = ( ! language_id.nil?) ? " (#{Language.find(language_id).shortname.upcase})" : ""
    rescue
      language = ""
    end
    
    begin 
      return order.fullname + language
    rescue 
      return "" + language
    end   
  end

  def display_printer_name_from_id(id)
    begin 
      User.find(id).username 
    rescue 
      "no_printer"
    end   
  end

  def general_timestamp()
    return Time.now.to_s.gsub(/\D/, '')
  end
  
  def garments_reordered(order)
      order.ordered_products.each do |item|
        return true if item.garments_reordered
      end
      return false
    end

  def remove_accents(str)
    return str.mb_chars.normalize(:kd).gsub(/[^-x00-\x7F]/n, '').to_s
  end

  def get_shipping_name(shipping_type,locale=nil)

    locale = I18n.locale if locale == nil
    text = case shipping_type
      when SHIPPING_BASIC then t(:standard_shipping, :locale=>locale)
      when SHIPPING_EXPRESS then t(:express_shipping, :locale=>locale)
      when SHIPPING_PICKUP then t(:pick_up_in_store, :locale=>locale)
      when SHIPPING_RUSH_PICKUP then t(:rush_pick_up_in_store, :locale=>locale)
    end
    return text
  end


  def create_callname(string)
    return StringUtil.create_callname(string)
  end

  def pretty_escape_url(str)
    return pretty_escape(StringUtil.create_callname(str))
  end

  def pretty_escape(str)
    return StringUtil.pretty_escape(str)
  end

  def print_force_lang()
    return Language.print_force_lang(params[:lang])
  end


  #################################################################################################
  # PRETTY URL DEFINITIONS
  #

  def category_url(cat_id, lang = params[:lang], lang_id = session[:language_id], per_page = session[:shop_per_page])
    begin
      return Category.url(cat_id, lang, lang_id, per_page)
    rescue

    end
    return create_tshirt_url()
  end

  def model_url(model_id, lang = params[:lang], lang_id = session[:language_id])

    begin

      model = Model.find(model_id)

      if ! model
        return create_tshirt_url(lang, lang_id)
      end
      return model.url(lang, lang_id)
    rescue
    end

    return create_tshirt_url(lang, lang_id)
  end


  def design_url(design_id, lang = params[:lang], lang_id = session[:language_id], per_page = session[:shop_per_page])

    begin
      design = Image.find(design_id)

      if !design
        return create_tshirt_url(lang, language_id)
      end

      return design.url(lang, lang_id, per_page)
    rescue
    end

    return create_tshirt_url(lang, lang_id)
  end

	# /display/design/id
	def design_info_url(design_id, lang = params[:lang], lang_id = session[:language_id], per_page = session[:shop_per_page])
		begin
			design = Image.find(design_id)

			if ! design
				return create_tshirt_url(lang, lang_id)
			end

			return design.info_url(lang, lang_id, per_page)
		rescue
		end

		return create_tshirt_url(lang, lang_id)
	end

  def create_tshirt_url(lang = params[:lang], lang_id = session[:language_id])
    return "#{Language.print_force_lang(lang)}#{I18n.t(:create_shirt_url, :locale => Language.find(lang_id).shortname)}"
  end

  def create_tshirt_url_with_promo_model(lang = params[:lang], lang_id = session[:language_id])
    return "#{Language.print_force_lang(lang)}#{I18n.t(:create_shirt_url, :locale => Language.find(lang_id).shortname)}?model=#{Model.mens_promo}"
  end


  def create_tshirt_product_url(product_id, lang = params[:lang], lang_id = session[:language_id])
    begin
      product = Product.find(product_id)

      if ! product
        return create_tshirt_url(lang, lang_id)
      end

      return product.url(lang, lang_id)
    rescue
    end

    return create_tshirt_url(lang, lang_id)
  end


	def fix_canonical_url(url)

		final_url = url

		begin
			if final_url[final_url.length - 1, 1].to_s == "/"
				final_url = final_url[0..(final_url.length-2)]
			end
		rescue
		end

#		if params[:page] && params[:page].to_i > 1
#			final_url = final_url + "?page=#{params[:page]}"
#		end

		return final_url
	end
  #
  # END PRETTY URL DEFINITIONS
  #################################################################################################


  def open_category(current, selected)
	begin
	    return params[:action] && (params[:action] == 'category' || params[:action] == 'marketplace' || params[:action] == "search" || params[:action] == "marketplace_search") &&
	    (current.id == selected.id || current.sub_categories.include?(selected))
	rescue
	end

	return false
  end

  def size_select(model_id, color_id, selected=0, change=nil, id="model_size_id", show_select_text=true, locale = "en")
    select_tag id, 
      size_select_options(model_id, color_id, selected, show_select_text, locale),
      :onchange=>change
  end

  def size_select_options(model_id, color_id, selected=0, show_select_text=true, locale = "en")
    @model_sizes = Model.find(model_id).active_in_stock_model_sizes(color_id)
    @model_sizes.map!{ |model_size| [ model_size.local_name(I18n.locale), model_size.id] }
    @model_sizes = [[t(:my_izishirt_2011_no_size, :locale => locale), 0]] | @model_sizes if show_select_text
    options_for_select(@model_sizes, selected.to_i)
  end

  def ups_logo
    return image_tag("/images/ups.png")
  end

  def tnt_logo
    return ""
  end

  def purolator_logo
    return image_tag("/images/purolator.png") if session[:country] == "CA"
    return ""
  end

end