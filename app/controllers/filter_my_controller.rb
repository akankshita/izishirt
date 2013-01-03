class FilterMyController < ApplicationController
  before_filter :find_user, :except => [:add_product_from_boutique, :get_cart_details]
  before_filter :fill_generic_seo_information

  before_filter :prepare_product, :only => [:product]

  def find_user




    if params[:bn]
      session[:bn] = params[:bn]
    end
    @username = session[:bn] || @username || params[:user] || @logged_in_username

    begin
      @cart = get_cart
      @user = User.find_by_username_and_active(@username, true)
      @username = @user.username
      @store = @user.store

	if (@DOMAIN_NAME != @store.shop_domain_name && @DOMAIN_NAME != @store.shop_domain_name) || ! [nil, ""].include?(params[:lang])
		redirect_to params.merge(:host => @store.shop_domain, :lang => nil, :force_lang => "en"), :status => :moved_permanently
		return
	end

      redirect_to @URL_ROOT  if @store.nil?
      (session[:user_id] and session[:user_id] == @user.id) ? @admin_mode = 1 : @admin_mode = 0
    rescue
      redirect_to @URL_ROOT
      return
    end
    begin
      @age = Date.today.year - @user.birthday.year
      @age -= 1 if Date.today.yday < @user.birthday.yday
    rescue
      @age = "N/A"
    end
    begin
      @theme = @user.store.general_background
    rescue
      @theme = "corp"
    end
    if @store.custom_theme && @store.active_theme.nil?
      @store.custom_theme = false
      @store.theme_name = "theme1"
      @store.save
    end

	@canonical_begin_url = "http://#{@username}.#{@DOMAIN_NAME}"
  setup_menu
    if @store
      logger.error("here's my store : #{@store.to_s}")
    end
  end


  def prepare_product

    product_id = StringUtil.get_id_from_url(params[:id])

    @product = Product.find(product_id)

    t_name = @product.name

    @meta_title = t(:meta_title_flash_seo, :name=>t_name, :country=>display_country, :locale => @store.locale)
    @meta_description = t(:boutique_product_meta_description, :name=>t_name, :locale => @store.locale)
    @meta_keywords = t(:meta_keyword_flash_seo, :name=>t_name, :locale => @store.locale)


	begin
		canonical_url @canonical_begin_url + boutique_product_url(@product.id)
	rescue
  end



	    
  end

  def fill_generic_seo_information
    begin
      #@meta_title = "#{@store.title_ref} | #{t(:boutique_default_meta_title, :locale => @store.locale)}"
      @meta_title = @store.title_ref
      @meta_description = @store.meta_description
      @meta_keywords = @store.meta_keys
      #@meta_description = "#{@store.meta_description} | #{t(:boutique_default_meta_title, :locale => @store.locale)}"
      #@meta_keywords = "#{@store.meta_keys}, #{t(:boutique_default_keywords, :locale => @store.locale)}"
    rescue
	if @store
	      @meta_title = "#{t(:boutique_default_meta_title, :locale => @store.locale)}"
	      @meta_description = "#{t(:boutique_default_meta_title, :locale => @store.locale)}"
	      @meta_keywords = "#{t(:boutique_default_keywords, :locale => @store.locale)}"
	end
    end
  end


      
end
