class DisplayController < FilterDisplayController
  require 'RMagick'
  require 'rubygems'
  require 'open-uri'
  require 'rexml/document'

  #caches_action :izishirt_2011, :expires_in => 24.hours, :cache_path => Proc.new { |controller| {:lang => controller.params[:lang], :p => controller.params[:p]} }, :layout => false

  #caches_action :design, :expires_in => 14.days, :cache_path => Proc.new { |controller| controller.params }, :layout => false
  #caches_action :shop, :expires_in => 24.hours, :cache_path => Proc.new { |controller| controller.params }, :layout => false
 # caches_action :new, :expires_in => 24.hours, :cache_path => Proc.new { |controller| controller.params }, :layout => false

  #caches_action :category, :expires_in => 72.hours, :cache_path => Proc.new { |controller| controller.params.merge({:version => 2}) }, :layout => false

  caches_action :sitemap, :expires_in => 7.days, :cache_path => Proc.new { |controller| controller.params }, :layout => false
  caches_action :sitemap_html, :expires_in => 7.days, :cache_path => Proc.new { |controller| controller.params }, :layout => false
  #caches_action :search, :expires_in => 24.hours, :cache_path => Proc.new { |controller| controller.params.merge({:version => 2}) }, :layout => false
  helper :product_colors, :application, "admin/homepage"

  #cache_sweeper :image_sweeper, :only=>[:idliketovalidatethisdesignwithoutusingthebackofficeabc654897poi, :idliketovalidatethisdesignwithoutusingthebackofficeabce5f897wrti]

  #Homepage => expirer toutes les 24 heures [DONE]
  #Flashpage => expirer toutes les 24 heures [DONE]
  #Page des categories => expirer toutes les 24 heures [DONE]
  #Page local/ => expirer tous les 7 jours [DONE]
  #Sitemap => expirer tous les 7 jours [DONE]

  ###################################################################################################################
  #                   C              A                       C             H                  E
  #
  #
  def contact_mail_send
    #params[:bulk_order][:wants_newsletter] = params[:bulk_order][:wants_newsletter] == "on"
    #params[:bulk_order][:contact_by_phone] = params[:bulk_order][:contact_by_phone] == "on"
    #params[:bulk_order][:contact_by_email] = params[:bulk_order][:contact_by_email] == "on"

    @contact = params[:contact]

  # begin
      SendMail.deliver_contact_mail_request(@contact)
   #rescue
   # end
   
    redirect_to :action=>:confirmation
  end

  def confirmation
    @meta_title     = t(:meta_title_contact, :country=>get_country_for_meta_title)
    @confirmation = true
  end

  def shipping_info
    @meta_title = t(:meta_title_shipping_info, :country=>get_country_for_meta_title)
  end
  def bulk_discounts
    @bulk_discounts = Model.find(params[:id]).get_bulk_discounts
	#@bulk_discounts = 0
    render :update do |page|
      page.replace_html "quantity_discount_wrapper", :partial => "layouts/quantity_discounts"
    end
  end

  def get_env_test
    render :text=>Socket.getaddrinfo(request.env["HTTP_X_FORWARDED_FOR"], nil)[0][2]
  end

  def clear_all_cache(is_rake)
    if is_rake
      expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/.*})
    end
  end

  def clear_category_cache(is_rake)
    if is_rake
      print "CLEARING CATEGORY CACHE.\n"

      cat_pages = ["t-shirt-design/", "custom-t-shirt-design/", "display/category/", "display/categorie/", "boutique", "display/shop", "display/staff_pick", "display/new"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end
    end
  end

  def clear_result_tag_cache(is_rake)
    if is_rake
      print "CLEARING RESULT TAG CACHE.\n"

      cat_pages = ["custom-t-shirt-design-tag/", "t-shirt-design-tag/", "custom-t-shirt-design-tags/", "t-shirt-design-tags/"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end
    end
  end

  def clear_marketplace_cache(is_rake)
    if is_rake
      print "CLEARING MARKETPLACE CACHE.\n"

      cat_pages = ["t-shirt-design-marketplace/", "t-shirt-designer-marketplace/", "t-shirt-marketplace/", "*-marketplace/", "t-shirt-design-marketplace/", "t-shirt-designer-marketplace/", "t-shirt-marketplace", "*-marketplace"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-design-marketplace/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-designer-marketplace/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-marketplace/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/*-marketplace/.*})

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-design-marketplace*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-designer-marketplace*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-marketplace*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/*-marketplace*})
    end
  end

  def clear_marketplace_search_cache(is_rake)
    if is_rake
      print "CLEARING MARKETPLACE SEARCH CACHE.\n"

      cat_pages = ["*+*.cache"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-design-marketplace/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-designer-marketplace/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-marketplace/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/*-marketplace/.*})

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-design-marketplace*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-designer-marketplace*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-marketplace*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/*-marketplace*})
    end
  end

  def clear_marketplace_shop_cache(is_rake)
    if is_rake
      print "CLEARING MARKETPLACE SHOP CACHE.\n"

      cat_pages = ["*-t-shirt-marketplace/"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/*-t-shirt-marketplace/.*})
    end
  end

  def clear_marketplace_shop_product_cache(is_rake, product_id)
    if is_rake
      print "CLEARING MARKETPLACE SHOP_PRODUCT CACHE.\n"

      cat_pages = ["*-t-shirt-marketplace/*#{product_id}*"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end

      # expire_fragment(%r{"(|fr|us|fr-eu|france|uk|australia|eu)/*-t-shirt-marketplace/.*#{product_id}.*"})
    end
  end

  def clear_create_tshirt_cache(is_rake)
    if is_rake
      print "CLEARING CREATE_TSHIRT CACHE.\n"

      cat_pages = ["myizishirt/display/create_tshirt", "myizishirt/display/create_tshirt/", "display/create_tshirt", "display/create_tshirt/", "t-shirt-personalise/", "create-custom-t-shirt/", "t-shirt-personalise", "create-custom-t-shirt", "creation-t-shirt-personnalise", "creation-t-shirt-personnalise/"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/myizishirt/display/create_tshirt*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/myizishirt/display/create_tshirt/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/display/create_tshirt*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/display/create_tshirt/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-personalise/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/create-custom-t-shirt/.*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/t-shirt-personalise*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/create-custom-t-shirt*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/creation-t-shirt-personnalise*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/creation-t-shirt-personnalise/.*})
    end
  end

  def clear_design_info_cache(is_rake)
    if is_rake
      print "CLEARING DESIGN INFO CACHE.\n"

      cat_pages = ["display/design/", "custom-t-shirt-design-details", "design-t-shirt-personnalise"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end

      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/display/design/*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/custom-t-shirt-design-details*})
      # expire_fragment(%r{(|fr|us|fr-eu|france|uk|australia|eu)/design-t-shirt-personnalise*})
    end
  end

  def clear_izishirt_2011_cache(is_rake)
    if is_rake
      print "CLEARING izishirt_2011 CACHE.\n"

#	cat_pages = ["index.cache", "*force_lang", "*force_country"]

#	cache_langs.each do |cache_lang|
#		lang = cache_lang.gsub("/", "")
#
#		cat_pages << "#{lang}.cache"
#	end

      cache_hosts.each do |host|
        cache_langs.each do |lang|
#			cat_pages.each do |cat_page|
#				f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
#				f = "#{f}*"
#				puts "#{f}"
#				`rm -rf #{f}`
          expire_fragment(Digest::SHA1.hexdigest(host+lang+"index"))
#			end
        end
      end

      # expire_fragment(%r{(|index|fr|us|fr-eu|france|uk|australia|eu).cache})
      # expire_fragment(%r{(|index|fr|us|fr-eu|france|uk|australia|eu).force_lang*.cache})
      # expire_fragment(%r{(|index|fr|us|fr-eu|france|uk|australia|eu).force_lang*})
      # expire_fragment(%r{(|index|fr|us|fr-eu|france|uk|australia|eu).force_country*})
      # expire_fragment(%r{(|index|fr|us|fr-eu|france|uk|australia|eu).force_country*})
    end
  end

  def clear_local_cache(is_rake)
    if is_rake
      print "CLEARING LOCAL CACHE.\n"

      cat_pages = ["local/"]

      cache_hosts.each do |host|
        cache_langs.each do |lang|
          cat_pages.each do |cat_page|
            f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
            f = "#{f}*"
            puts "#{f}"
            `rm -rf #{f}`
          end
        end
      end
    end

    # expire_fragment(%r{(index|fr|us|fr-eu|france|uk|australia|eu)/local/.*})
  end

  def clear_sitemap_cache(is_rake)
    if is_rake
      print "CLEARING SITEMAP CACHE [disabled].\n"

      #cat_pages = ["display/sitemap*"]

      #cache_hosts.each do |host|
      #	cache_langs.each do |lang|
      #		cat_pages.each do |cat_page|
      #			f = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "#{host}#{lang}", cat_page)
      #			f = "#{f}*"
      #			FileUtils.rm_rf(f)
      #		end
      #	end
      #end

      #expire_fragment(%r{(index|fr|us|fr-eu|france|uk|australia|eu)/display/sitemap*})
    end
  end

  #
  # END                  C              A                       C             H                  E
  ###################################################################################################################


  def copyright
    render :layout => false
  end

  def hosted_by
    render :layout => false
  end

  def contact
    @time_end = Time.now
    logger.error("TIME BEFORE FILTER APPLICATION CONTROLLER = #{(@time_end - @time_start).to_s}")
    @now = Time.now.strftime("%I:%M:%S %p")
    if ((Time.now.wday > 0 &&
        Time.now.wday < 7 &&
        Time.now.hour > 10 &&
        Time.now.hour < 19) ||
        ((Time.now.wday == 0 ||
            Time.now.wday == 7) &&
            Time.now.hour > 10 &&
            Time.now.hour < 18))
      @open = true
    else
      @open = false
    end

    @meta_title     = t(:meta_title_contact, :country=>get_country_for_meta_title)
   # @pick_up_stores = PickUpStore.find_all_by_active(1, :include=>[:address], :conditions=>"addresses.country_id=#{Country.find_by_shortname(session[:country]).id}", :order=>"addresses.province_id ASC")


  end

  def quantity_popup
    render :layout => false
  end

  def contact_request
    if SendMail.deliver_contact_request(params[:contact_request])
      flash[:success] = t(:we_have_received_your_email)
      if params[:contact_request]['wants_newsletter'] == "1" &&
          params[:contact_request]['email'] =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
        contact_request           = NewsletterRequest.new()
        contact_request.firstname = params[:contact_request]['firstname']
        contact_request.lastname  = params[:contact_request]['lastname']
        contact_request.email     = params[:contact_request]['email']
        contact_request.phone     = params[:contact_request]['phone']
        contact_request.country   = params[:contact_request]['country']
        contact_request.save
      end
    else
      flash[:success] = t(:an_error_has_occured_while_sending_your_email) + '.'
    end
    redirect_to request.referer
  end

  def subscribe_newsletter
    @message = ""
    if NewsletterRequest.exists?(:email=>params[:email_newsletter])
      @message = t(:newsletter_form_existing_email)
    else
      request             = NewsletterRequest.new()
      request.email       = params[:email_newsletter]
      request.country     = session[:country]
      request.language_id = session[:language_id]
      request.save!
      @message = t(:newsletter_form_success)
    end
  end

  def update_model_sizes
    @model = Model.find(params[:shirt])
  end


  def robots
    host             = @FULL_DOMAIN_NAME

    website_part     = "front"

    current_sub_host = get_user_from_url()

    if !["www", "fr", "au", "eu"].include?(current_sub_host)
      # boutique !
      website_part = "boutique"
    end

    robot = get_file_as_string("#{RAILS_ROOT}/public/#{host}_#{website_part}_robots.txt")

    render :text => "#{robot}", :layout => false, :content_type => "text/plain"
  end


  def sitemap
    headers['Content-Type'] = 'application/xml'
	@categories = root_categories()
  end

  def sitemap_html
    @categories = root_categories()
  end


  def izishirt_2011

    begin
      canonical_url fix_canonical_url("#{@canonical_begin_url}#{Language.print_force_lang(params[:lang])}")
    rescue
    end

    country_id     = Country.find_by_shortname(session[:country]).id

    #@staff_picks = Image.find_all_by_staff_pick(1, :limit => 5, :select => 'id, name', :order => 'rand()')

    @staff_picks   = get_top_rated_images(nil, country_id, 5, true)

    @top_products  = Model.find_all_by_top_product(1, :limit => 5, :include => [:localized_models])

    @top_designs   = TopDesign.find_by_region(session[:country], session[:language_id]).map { |td|
      td.image
    }

    country        = session[:country] == "CA" ? '_ca_' : '_'


    @all_categories = root_categories()


    @categories = @all_categories[0..16]

    @numbers    = ["one", "two", "three", "four", "five"]



    @model1 = Model.find(85)
    @model2 = Model.find(69)


    begin
      language_id          =session[:language_id]
      @featured_design     = Image.find(:all,
                                        :order      => "localized_images.sorting_rate DESC, images.id DESC",
                                        :conditions => ["images.staff_pick = 1 and images.active = ? and images.pending_approval = ? and images.is_private = ?", 1, 1, 0],
                                        :joins      => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.category_id = #{get_custom_category("custom_staff_picks_").id} AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{session[:language_id]}",
                                        :limit      =>1)[0]

      #Banners
      @banners_slider      = HomepageBanner.find(:all, :conditions=>["position=? AND display=?", "left", 1], :order=>"order_slider ASC")


      @homepage_categories = HomepageCategory.find(:all, :include=>[:homepage_category_links],
                                                   :conditions   => ["country = '#{session[:country]}' AND language_id = #{session[:language_id]} AND homepage_categories.order >= 0"], :order=>"homepage_categories.order asc")

    rescue
      country_id           =1
      country              = "CA"
      language_id          =2
      @featured_design     = Image.find(:all,
                                        :order      => "localized_images.sorting_rate DESC, images.id DESC",
                                        :conditions => ["images.staff_pick = 1 and images.active = ? and images.pending_approval = ? and images.is_private = ?", 1, 1, 0],
                                        :joins      => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.category_id = #{get_custom_category("custom_staff_picks_", language_id).id}
                   AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{language_id}",
                                        :limit      =>1)[0]

      #Banners
      @banners_slider      = HomepageBanner.find(:all, :conditions=>["position=? AND display=?", "left", 1], :order=>"order_slider ASC")
      @homepage_categories = HomepageCategory.find(:all, :include=>[:homepage_category_links],
                                                   :conditions   => ["country = '#{country}' AND language_id = #{language_id} AND homepage_categories.order >= 0"], :order=>"homepage_categories.order asc")
    end

   # respond_to do |format|
    #  format.html # index.html.erb
    #  format.rss { render "/display/izishirt_2011.rss" }
    #end


  end

  
  

  def page

    begin
      @lc = LocalizedContent.find_by_url(params[:id], :include=>[:content])
      if @lc.content.redirect_to && @lc.content.redirect_to.length > 0
        redirect_to :controller => @lc.content.redirect_to, :status=>:moved_permanently
        return
      end


      #@left_column = @lc.left_column && @lc.left_column.strip != ''
      @left_column=false
      @content    = @lc.content
      @meta_title = @lc.meta_title + " - #{@DOMAIN_NAME.capitalize}"

    rescue
      redirect_to :controller=>:display, :action=>:izishirt_2011
    end
  end


  def shop
    @title         = t(:meta_title_shop)
    @meta_title    = @title
    @meta_title    += I18n.t(:meta_title_category_added, :country => display_country)

    #Grab the top 25 designs dependent on region
    @img_result    = TopDesign.find_by_region(session[:country], session[:language_id]).map { |td|
      td.image
    }

    @numbers       = ["one", "two", "three", "four", "five"]
    @category      = get_custom_category("custom_top_25_")
    @local_name    = ""
    @tags          = FastTag.get_top_tags_name_with_images(7, @img_result)

    @no_pagination = true

    if request.xml_http_request?
      render :partial => "img_trendy", :layout => false if params[:i] == "1"
      render :partial => "image_list",
             :locals  => {:title  => 'NEW SUBMISSIONS',
                          :images => @new_submissions},
             :layout  => false if params[:i] == "2"
    else
      render :action=>:category
    end

  end

  def new

    generate_menu_left
    if session[:language] == "fr"
      @title = "Designs de t-shirts"
    else
      @title = "New T-Shirts Designs"
    end


    @meta_title = I18n.t(:meta_title_category_added, :category=>@title, :country => get_country_for_meta_title)

    @meta_description = t(:meta_description_category_added)
    @img_result = Image.paginate(:page       =>params[:page],
                                 :per_page   => 20,
                                 :order      => "images.date_approved DESC",
                                 :conditions => ["active = ? and pending_approval = ? and is_private = ? and always_private = ?",
                                                 1, 1, 0, 0])

   # @tags       = FastTag.get_top_tags_name_with_images(7, @img_result)

    @breadcrumb = []
    @breadcrumb << {:text => t(:menu_shop_designs), :url => url_for(:controller => 'display', :action => 'shop')}
    @breadcrumb << {:text => t(:new_submissions), :url => url_for(:controller => 'display', :action => 'new')}

    @category = get_custom_category("custom_new_design_")

    if session[:language_id] == 1
      @local_title = "Découvrez les nouveaux designs"
    else
      @local_title = "Shop Izishirt New Designs"
    end

    if request.xml_http_request?
      render :partial => "img_result", :layout => false
    else
      render :action => 'category'
    end

  end

  # Prints images of a selected category
  def category

    generate_menu_left
    #:country_id =>

    country_id                = Country.find_by_shortname(session[:country]).id

    top_rated_images          = Image.find_all_by_active(1, :limit=>25)

    top_rated_ids             = top_rated_images.map { |image| image.id }

    localized_parent_category = @category.localized_parent_category(session[:language_id])

    where_top_rated           = (top_rated_ids.length > 0) ? "AND localized_images.image_id IN (#{top_rated_ids.collect { |e| e.to_s }.join(",")}) " : ""
    order_by                  = order_by_top_rated_images()

    # WITH OLD TOP DESIGNS
    #@img_result = Image.paginate(:per_page => session[:shop_per_page], :page=>params[:page],
    #  :conditions => ["images.category_id IN (:category_ids) AND active = :active AND pending_approval = :pending_approval AND is_private = :is_private ",
    #    {:category_ids => @category_ids, :active => 1, :pending_approval => 1, :is_private => 0}],
    #  :joins => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{session[:language_id]} AND localized_images.category_id = #{@category.id} #{where_top_rated}",
    #  :order => "#{order_by}")

    @img_result               = Image.paginate(:per_page   => 20, :page=>params[:page],
                                               :conditions => ["images.category_id IN (:category_ids) AND active = :active AND pending_approval = :pending_approval AND is_private = :is_private ",
                                                               {:category_ids => @category_ids, :active => 1, :pending_approval => 1, :is_private => 0}],
                                               :order      => "images.created_on DESC")

    #@tags                     = FastTag.get_top_tags_name_with_images(7, @img_result)
    @local_name               = @category.local_name(session[:language_id])
    @breadcrumb               = []
    @breadcrumb << {:text => t(:menu_shop_designs), :url => url_for(:controller => 'display', :action => 'shop')}
    if localized_parent_category
      @breadcrumb << {:text => session[:language] == 'fr' ? "<strong>T-shirts #{localized_parent_category.name}</strong>" : "<strong>#{localized_parent_category.name} T-shirts</strong>",
                      :url  => url_for(:controller => 'display', :action => 'result', :id => @category.parent_categories[0].category_id)}
    end
    @breadcrumb << {:text => session[:language] == 'fr' ? "<strong>T-shirts #{@category.local_name(session[:language_id])}</strong>" : "<strong>#{@category.local_name(session[:language_id])} T-shirts</strong>",
                    :url  => url_for(:controller => 'display', :action => 'result', :id => @category.id)}

    if request.xml_http_request?
      if params[:i] == "2"
        render :partial => "image_list",
               :locals  => {:title  => 'NEW SUBMISSIONS',
                            :images => @new_submissions},
               :layout  => false
      else
        render :partial => "img_result", :layout => false
      end
    end
  end


  def search

    search     = @search_keyword

    country_id = Country.find_by_shortname(session[:country]).id

    session[:language_id] == 1 ? @title = "T-Shirts #{@search_keyword}" : @title = "#{@search_keyword.capitalize} T-Shirts"
    where           = ["category_type_id = 3 and active = 1 and not exists (select category_id from sub_categories where sub_category_category_id = categories.id) AND is_custom_category = 0"]


    @categories     = Category.find(:all, :conditions => where, :order => :position, :include => [:localized_categories])

    begin
      fast_tag = FastTag.find(:first, :conditions => "name = '#{@search_keyword}'")
    rescue
      fast_tag = nil
    end

    cond_fast_tags = fast_tag ? " EXISTS(SELECT * FROM fast_tag_images WHERE fast_tag_images.image_id = images.id AND fast_tag_images.fast_tag_id = #{fast_tag.id}) " : " 1 = 0 "

    @conditions    = []
    #Search by image name
    @conditions[0] = "(images.name LIKE '%#{search}%'"
    #Search by tag
    @conditions[0] += " OR #{cond_fast_tags}"
    @conditions[0] += " )"
    @conditions[0] += " AND images.active = :active"
    @conditions[0] += " AND images.pending_approval = :pending_approval"
    @conditions[0] += " AND images.is_private = :is_private "
    @conditions << {:category_ids => @category_ids, :active => 1, :pending_approval => 1, :is_private => 0}

    @img_result = Image.paginate(:per_page   => 20,
                                 :page       =>params[:page],
                                 :conditions => @conditions,
                                 :order      => "images.sorting_rate DESC")
  end




	def get_data_fromlink(link)
		uri = URI.parse(link)
		@path = []
		open(uri) do |data|
			doc, @posts = REXML::Document.new(data), []
			
			@root_name = doc.root.name
			if doc.root.length > 0
				for i in 1..doc.root.length
					if !doc.root.elements[i].nil?
						@name = []
						@name << doc.root.elements[i].name 
						@name.uniq
						for k in 1..@name.length
							input = @root_name + '/' + @name[k-1] + '/' + doc.root.elements[i].elements[k].name if !doc.root.elements[i].elements[k].nil? 
							@path << input
						end
					end
				end
			end
		end
	  return @path
#render :text => @path.inspect and return false
	end
  def create_tshirt


    if params[:format] == "swf"
      redirect_to "/bin/Izishirt6.swf", :status=>:moved_permanently
      return
    end

    #begin
    @category_country_id = get_category_country_id
    conditions_for_design = ["active = 1"]
    @top_designs         = get_top_designs(15, @image)
    @top_designs2         = Image.find(:all,:conditions=>conditions_for_design, :order=>"id DESC", :limit=>5)
   # if @image
   #   @tags = FastTag.get_top_tags_name_with_images(7, [@image])
   # else
   #   @tags = FastTag.get_top_tags_name(7)
   # end

    cart        = session[:cart] ||= Cart.new()
    @flash_vars = default_flash_vars
    @flash_vars += "&cartQty=#{cart.total_qty_for_rebate}"
    @flash_vars += "&updateDiscounts=true"

    @categories = root_categories()[0..9]
     
    
    if @defaultdesign &&
        Image.exists?({:id => @defaultdesign, :active => 1, :pending_approval => 1, :is_private => 0})
      @flash_vars+= "&designId=#{@defaultdesign}"
      if !@model_id && Model.exists?(Model.mens_promo)
        @model_id    = Model.mens_promo
        params[:tab] = 0
      end
      @design_rss = Image.find(@defaultdesign)
    end
    if @model_id &&
        Model.exists?({:id => @model_id, :active => 1})
      @flash_vars+= "&modelId=#{@model_id}"
    end
    if params[:model_category] &&
        Category.exists?({:id => params[:model_category], :active => 1})
      @flash_vars+= "&modelCategoryId=#{params[:model_category]}"
    end
    if params[:category] &&
        Category.exists?({:id => params[:category], :active => 1})
      @flash_vars+= "&categoryId=#{params[:category]}"
    end
    if params[:tab]
      @flash_vars+= "&tabId=#{params[:tab]}"
    end
    if params[:color]
      @flash_vars+= "&colorId=#{params[:color]}"
    end
    if params[:ordered_product]
      @flash_vars+= "&orderedProductId=#{params[:ordered_product]}"
      @flash_vars+= "&inputParam=#{cart.find_by_checksum(params[:ordered_product]).affiliate_user_id}"
    end
    if params[:product]

      begin
        @flash_vars+= "&productId=#{@product.id}"
      rescue
      end

    end
    if params[:id] &&
        Image.exists?({:id => params[:id], :active => 1, :pending_approval => 1, :is_private => 0})
      @flash_vars+= "&designId=#{params[:id]}"
    end
    #rescue
    #  # ERROR !!
    #  redirect_to create_tshirt_url()
    #  return
    #end

        #@flash_vars               += "&loadAnimation=loader5"

  end


  def generate_menu_left
    begin
      if (params[:id] && params[:id] != '0')
        @current_category = Category.find(params[:id])
      else
        @current_category = "none"
      end
    rescue
      @current_category = "none"
    end
    @categories = root_categories()
    @category_news   = Image.find_all_by_active_and_pending_approval_and_is_private(1, 1, 0, :limit => 5, :order => "id DESC")
    @category_trendy = Image.find_all_by_is_trendy_and_active_and_pending_approval_and_is_private(1, 1, 1, 0, :limit => 5, :order => "id DESC")
  end


  def about_us
    @meta_title = t(:meta_title_about_us, :country=>get_country_for_meta_title)
  end


  def verification_design_exist(image_url)
    if image_url.file? && File.exists?(image_url.path("png200"))
      return image_url.url('png200')
    else
      return image_url.url("png")
    end
  end

  ####Description of a design
  def design
	render :text => 'in' and return false
    if (@design)
      @design.name == "" ? @design.name = t(:no_name) : @design.name
#      @tab_tags = FastTagImage.find_all_by_image_id(@design.id, :conditions=>["fast_tags.name != ?", ""], :include=>[:fast_tag])
      params[:lang] != nil ? @param_lang = "#{params[:lang]}/" : @params_lang = ""
      @image_url = @design.orig_image.url("340")

      #continue shopping
      if request.referer == nil
        @continue_link = "/display/shop"
      else
        @continue_link = request.referer
      end

      #link for models
      model_category_men   = Model.find(71)
      @men_link            = create_tshirt_url()+"/model/#{model_category_men.id}/model_category/#{model_category_men.category_id}?image=#{@design.id}"
      model_category_women = Model.find(51)
      @women_link          = create_tshirt_url()+"/model/#{model_category_women.id}/model_category/#{model_category_women.category_id}?image=#{@design.id}"
      model_category_kids  = Model.find(9)
      @kids_link           = create_tshirt_url()+"/model/#{model_category_kids.id}/model_category/#{model_category_kids.category_id}?image=#{@design.id}"
      model_category_bags  = Model.find(85)
      @bags_link           = create_tshirt_url()+"/model/#{model_category_bags.id}/model_category/#{model_category_bags.category_id}?image=#{@design.id}"
      @categories = root_categories()[0..9]
      #list of tags
      #count_tags           = 1
     # @tab_tags.map { |t|
     #   @tab_tags.size != count_tags ? virgule = "," : virgule=""
     #   @list_tags = "#{@list_tags}<span class=\"tags_link\">
  	#		  <a href=\"#{t.fast_tag.url(params[:lang], session[:language_id], nil)}\">#{t.fast_tag.name}</a></span>#{virgule}"
     #   count_tags = count_tags + 1
     # }

      #list of categories
      @category_design = LocalizedCategory.find_by_category_id_and_language_id(@design.category_id, session[:language_id])
      name_category    = @category_design
      category_sub     = SubCategory.find_by_sub_category_category_id(@design.category_id)
      if category_sub != nil
        @categ_parent = LocalizedCategory.find_by_category_id_and_language_id(category_sub.category_id, session[:language_id])
      else
        @categ_parent = @category_design
      end

      #list of products of the same design category
      @list_products = []
      #@list_products = list_products_spec(@list_products, @design.category_id, "design")
      #design_child
      if @list_products.size < 10 && @categ_parent != @category_design
       # @list_products = list_products_spec(@list_products, @categ_parent.category_id, "design") #design_parent
      end
      if @list_products.size < 10
       # @list_products = list_products_spec(@list_products, @design.category_id, "product") #product_child
      end

      if @list_products.size < 10 && @categ_parent != @category_design
        #@list_products = list_products_spec(@list_products, @categ_parent.category_id, "product") #product_parent
      end
      #list of related product
      @related_products = []
      count_products    = 0
      while count_products < 4
        @related_products << @list_products[count_products] if @list_products[count_products] != nil
        count_products += 1
      end

      #list of other designs of the user
      conditions_for_design = ["active = 1 AND is_private = 0 AND category_id != 0 AND name != '' AND id != ?", @design.id]
      @tab_designs          = Image.find_all_by_user_id(@design.user.id, :conditions=>conditions_for_design, :order=>"id DESC", :limit=>4)
      @tab_designs.map { |td|
        image_current_url = td.orig_image.url('100')
        td.name != "" ? design_name = td.name : design_name = "No name"
        @list_designs = "#{@list_designs}<div class=\"part_other\">
					<div class=\"part_img\">
						<div class=\"part_img_link\">
							<a href=\"#{td.info_url(params[:lang], session[:language_id])}\"><img style=\"background-color: #{td.jpg_background_color};\" alt=\"#{td.name}\" src=\"#{image_current_url}\" /></a>
						</div>
					</div>
					<div class=\"part_img_desc\">
						#{I18n.t(:seo_tshirts, :locale => Language.find(session[:language_id]).shortname, :name => design_name)}
					</div>
				</div>"
      }

      #list of related designs
	  if @design.city_id.to_i > 0
		@related_designs = Image.find_all_by_city_id(@design.city_id, :conditions=>conditions_for_design, :order=>"id DESC", :limit=>12)
	  else 
		  @related_designs = Image.find_all_by_category_id(@design.category_id, :conditions=>conditions_for_design, :order=>"id DESC", :limit=>12)
		  if @related_designs.size < 12 && @categ_parent.category_id != @category_design.category_id
			limit_designs = 12 - @related_designs.size
			other_designs = Image.find_all_by_category_id(@categ_parent.category_id, :conditions=>conditions_for_design, :order=>"id DESC", :limit=>limit_designs)
			if other_designs.size != 0
			  other_designs.map { |op|
				@related_designs << op
			  }
			end
		  end
	  end
      @list_related_designs = @related_designs.map { |rd|
        image_current_url = rd.orig_image.url("340")
        "<div class=\"related_img\">
			    <a href=\"#{rd.info_url(params[:lang], session[:language_id])}\"><img style=\"background-color: #{rd.jpg_background_color};\" alt=\"#{rd.name}\" src=\"#{image_current_url}\" /></a>
			  </div>"
      }
      if @related_designs.size < 12
		if @design.city_id.to_i >0
			conditions_for_design = ["active = 1 AND is_private = 0 AND category_id != 0 AND name != '' AND city_id != ?", @design.city_id]
		end
        @related_designs2 = @related_designs = Image.find(:all,:conditions=>conditions_for_design, :order=>"id DESC", :limit=>12-@related_designs.size)
        @list_related_designs2 = @related_designs2.map { |rd|
          image_current_url = rd.orig_image.url("340")
          "<div class=\"related_img\">
            <a href=\"#{rd.info_url(params[:lang], session[:language_id])}\"><img style=\"background-color: #{rd.jpg_background_color};\" alt=\"#{rd.name}\" src=\"#{image_current_url}\" /></a>
          </div>"
        }
      else
         @list_related_designs2 = ""
      end
    end
  end


  private

  def cache_hosts
    return ["localhost:3000", "www.izishirt.com", "www.izishirt.ca", "fr.izishirt.ca"]
  end


  def get_category_country_id
    id = Country.find_by_shortname(session[:country]).id
    return 5 if id > 5
    return id
  end


  def get_top_designs(limit, design = nil)

    if design
      country_id       = Country.find_by_shortname(session[:country]).id
      top_rated_images = get_top_rated_images(design.category_id, country_id, limit)
      top_rated_ids    = top_rated_images.map { |image| image.id }
      where_top_rated  = (top_rated_ids.length > 0) ? "AND localized_images.image_id IN (#{top_rated_ids.collect { |e| e.to_s }.join(",")}) " : ""
      order_by         = order_by_top_rated_images()

      results          = Image.find(:all,
                                    :conditions => ["images.category_id = (:design_id) AND active = :active AND pending_approval = :pending_approval AND is_private = :is_private AND always_private=0",
                                                    {:design_id => design.category_id, :active => 1, :pending_approval => 1, :is_private => 0}],
                                    :joins      => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{session[:language_id]} AND localized_images.category_id = #{design.category_id} #{where_top_rated}",
                                    :order      => "#{order_by}", :limit=>limit)
    else
      results = TopDesign.find_by_region(session[:country], session[:language_id], limit).map { |td|
        td.image
      }
    end

    return results

  end

end


