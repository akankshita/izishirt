class Admin::HomepageController < Administration
  require 'ftools'
  
  def index
    redirect_to :action=>"banners"
  end





	def prepare_categories
		@country = params[:country]
		@language = params[:language_id]

		if !params[:country]
			@country = "CA"
		end

		if !params[:language_id]
			@language = 2
		end
	end


  def categories
	prepare_categories

    @homepage_categories = HomepageCategory.find_all_by_country_and_language_id(@country, @language, :include=>[{:homepage_category_images=>:image}, :homepage_category_links])
    @categories = root_categories()
    
  end

  def define_image
    image_id = params[:id]
    hc_id = params[:category]
    order = params[:order_param]
    @homepage_image = HomepageCategoryImage.find_by_homepage_category_id_and_order(hc_id, order)
	
	image = Image.find(image_id)

	if image
		@homepage_image.model_id = nil
		@homepage_image.orig_image = File.new(image.orig_image.path)
		@homepage_image.image_id = image.id
	end

    @homepage_image.save!
  end

  def search
    from_pagination = false
    where = build_search_image_where(@category_ids)
    id = params[:id]

    if ! params[:search]
      from_pagination = true
    end

    @find_condition = where

    @images = Image.paginate(:all, #:order => :position,
      :conditions => where, :page => params[:page], :per_page => 50)

    @homepage_category = HomepageCategory.find(id)

    respond_to do |format|
    format.html {
    }
    format.js {
      if !from_pagination
        render :partial => "img_result"
      else
        render :update do |page|
          page.replace_html "img_result_#{@homepage_category.id}", :partial => 'img_result'
        end
      end
    }
    end
  end

	def change_nb_lines
		prepare_categories

		cats = HomepageCategory.find_all_by_country_and_language_id(@country, @language)

		nb_lines = params[:nb_lines].to_i

		max_order = 1

		cats.each do |cat|
			if cat.order > max_order
				max_order = cat.order
			end
		end

		# need to create
		if cats.length < nb_lines
			need_to_create = nb_lines - cats.length
			
			(1..need_to_create).each do |i|
				max_order += 1

				Locale.all.each do |locale|
					hc = HomepageCategory.create(:country => locale.country, :language_id => locale.language_id,
						:name => "", :order => -1)

					(1..6).each do |link_i|
						HomepageCategoryLink.create(:homepage_category_id => hc.id, :text => "", :link => "", :active => false, :order => link_i)
					end

					(1..4).each do |image_i|
						HomepageCategoryImage.create(:homepage_category_id => hc.id, :image_id => 0, :order => image_i)
					end
				end
			end
		elsif cats.length > nb_lines
			# need to remove some
			need_to_remove = cats.length - nb_lines
			logger.error("need to rem #{need_to_remove}, cur cats #{cats.length}, nb_lines #{nb_lines}")

			(1..need_to_remove).each do |i|
				cat = HomepageCategory.all.last
				logger.error("destroyu #{cat.id}")

				HomepageCategory.find_all_by_order(cat.order).each do |home_cat|
					home_cat.homepage_category_images.each do |img|
						img.destroy
					end

					home_cat.homepage_category_links.each do |link|
						link.destroy
					end

					home_cat.destroy
				end
			end
		end 

		redirect_to :back
	end

	def add_store_product

		hc = HomepageCategory.find(params[:homepage_category_id])

		order = params[:order].to_i

		hci = hc.homepage_category_images.find(:first, :conditions => ["`order` = #{order}"])
	
		if hci

			begin
				model = Model.find(params[:model_id])
				model_id = model.id
			rescue
				model = nil
				model_id = 0
			end

			if params[:orig_image]
				hci.update_attributes(:orig_image => params[:orig_image], :model_id => model_id, :image_id => nil, :manual_url => params[:manual_url])
			else
				begin
					o_image = File.new(model.model_previews.first.image.path)
				rescue
					o_image = nil
				end

				hci.update_attributes(:orig_image => o_image, :model_id => model_id, :image_id => nil, :manual_url => params[:manual_url])
			end
		end

		redirect_to :back
	end

  def save_hp_category
    language = params[:language_id].to_i
    homepage_category_id = params[:homepage_category_id].to_i
    country = params[:country]

    homepage_category = HomepageCategory.find(homepage_category_id)
    homepage_category.update_attributes(params[:homepage_category])

    homepage_category_links = HomepageCategoryLink.find_all_by_homepage_category_id(homepage_category_id, :order=>"homepage_category_links.order asc")
    homepage_category_images = HomepageCategoryImage.find_all_by_homepage_category_id(homepage_category_id, :order=>"homepage_category_images.order asc")

    apply_all = []
    if params[:apply_all_en]
      apply_all << HomepageCategory.find_all_by_language_id_and_order(2, homepage_category.order, :conditions=>"id != #{homepage_category_id.to_s}")
    end

    if params[:apply_all_fr]
      apply_all << HomepageCategory.find_all_by_language_id_and_order(1, homepage_category.order, :conditions=>"id != #{homepage_category_id.to_s}")
    end

    if params[:apply_all_es]
      apply_all << HomepageCategory.find_all_by_language_id_and_order(3, homepage_category.order, :conditions=>"id != #{homepage_category_id.to_s}")
    end

    if params[:apply_all_de]
      apply_all << HomepageCategory.find_all_by_language_id_and_order(4, homepage_category.order, :conditions=>"id != #{homepage_category_id.to_s}")
    end

    if params[:apply_all_pt]
      apply_all << HomepageCategory.find_all_by_language_id_and_order(5, homepage_category.order, :conditions=>"id != #{homepage_category_id.to_s}")
    end

    apply_all.flatten!

    for hpc in apply_all
      hpc.name = homepage_category.name
	hpc.order = homepage_category.order
      hpl = HomepageCategoryLink.find_all_by_homepage_category_id(hpc.id, :order=>"homepage_category_links.order asc")
      i = 0
      for l in hpl
        l.text = homepage_category_links[i].text
        l.link = homepage_category_links[i].link
        l.active = homepage_category_links[i].active
        l.save!
        i=i+1
      end

      hpi = HomepageCategoryImage.find_all_by_homepage_category_id(hpc.id, :order=>"homepage_category_images.order asc")
      i = 0
      for image in hpi
        image.image_id = homepage_category_images[i].image_id
        image.model_id = homepage_category_images[i].model_id
        image.orig_image = File.new(homepage_category_images[i].orig_image.path)
        image.save!
        i=i+1
      end

      hpc.save!

    end

    redirect_to :action=>:categories, :country=>country, :language_id=>language
    return
    
  end


  def apply_design_category
    language = params[:language_id].to_i
    category_id = params[:category_id]
    homepage_category_id = params[:homepage_category_id]
    country = params[:country]

	if params[:store_category_id] && params[:store_category_id].to_i > 0
		category_id = params[:store_category_id]
	end

    homepage_category = HomepageCategory.find(homepage_category_id)
    category = Category.find(category_id)
    homepage_category.name = category.local_name(language)

    homepage_category_links = HomepageCategoryLink.find_all_by_homepage_category_id(homepage_category_id, :order=>"homepage_category_links.order asc")


    i = 0

    for sub in category.sub_categories
      homepage_category_links[i].text = sub.local_name(language)
	

		homepage_category_links[i].link = Category.url(sub.id, '', language)

      homepage_category_links[i].active = true
      homepage_category_links[i].save!
      i = i+1
      break if i==6
    end
    while i<6
      homepage_category_links[i].active = false
      homepage_category_links[i].save!
      i = i+1
    end

    homepage_category.save!

    redirect_to :action=>:categories, :country=>country, :language_id=>language
    return
  end


	##################################################################################################
	# NEW NON SHIT BANNER.


	def add_image_banner
	end

	def exec_add_image_banner
		params[:banner_locale].each do |locale_id, value|
			if value == "1"
				wi = WebsiteBannerImage.create(params[:banner])
		
				wi.update_attributes(:locale_id => locale_id)
			end
		end

		redirect_to :action => :website_banners
	end

	def delete_website_banner_image
		begin
			banner_image = WebsiteBannerImage.find(params[:id])
		
			banner_image.destroy
		rescue
		end
		if  params[:pagename]
			redirect_to :action => params[:pagename]
		else
			redirect_to :action => :website_banners
		end
		#redirect_to :action => :website_banners
	end
	
	

	def update_infos_banners
		if ! params[:banner_image]
			params[:banner_image] = {}
		end

		params[:banner_image].each do |banner_id, infos|		
			banner_image = WebsiteBannerImage.find(banner_id)

			banner_image.update_attributes(params[:banner_image][banner_id])
		end

		redirect_to :action => :website_banners
	end

	# NON NEW NON SHIT BANNER.
	##################################################################################################

	def website_banners
		order = params[:order] ? params[:order] : "website_banner_id ASC, locale_id ASC, the_order ASC"

		@website_banners = WebsiteBannerImage.find(:all, :order => order, :conditions=>"website_banner_id = 1 OR website_banner_id = 2")
  end

  def update_infos_homepage_images
		if ! params[:yourtext_yourimage]
			params[:yourtext_yourimage] = {}
		end

		params[:yourtext_yourimage].each do |banner_id, infos|
			banner_image = WebsiteBannerImage.find(banner_id)
			banner_image.update_attributes(params[:yourtext_yourimage][banner_id])
		end

    if ! params[:homepage_images]
			params[:homepage_images] = {}
		end
	

		params[:homepage_images].each do |banner_id, infos|
			banner_image = WebsiteBannerImage.find(banner_id)
			banner_image.update_attributes(params[:homepage_images][banner_id])
		end
		if  params[:pagename]
			redirect_to :action => params[:pagename]
		else
			redirect_to :action => :homepage_images
		end
		
	end

  def homepage_images
      order = params[:order] ? params[:order] : "website_banner_id ASC, locale_id ASC, the_order ASC"
      wb = WebsiteBanner.find_by_name('yourtext_your_image')
      @yourtext_yourimage = WebsiteBannerImage.find(:all, :order => order, :conditions=>"website_banner_id = " +  wb.id.to_s)
      wb = WebsiteBanner.find_by_name('categories_images')
    	@homepage_images = WebsiteBannerImage.find(:all, :order => order, :conditions=>"website_banner_id = " +  wb.id.to_s)
  end
  
  def homepage_city_images
      order = params[:order] ? params[:order] : "website_banner_id ASC, locale_id ASC, city_id ASC, the_order ASC"
      wb = WebsiteBanner.find_by_name('homepage_city_images')
      @yourtext_yourimage = WebsiteBannerImage.find(:all, :order => order, :conditions=>"website_banner_id = " +  wb.id.to_s)
      
  end
   
  def banner_left_col_images
      order = params[:order] ? params[:order] : "website_banner_id ASC, locale_id ASC, the_order ASC"
      wb = WebsiteBanner.find_by_name('banner_left_col')
      @yourtext_yourimage = WebsiteBannerImage.find(:all, :order => order, :conditions=>"website_banner_id = " +  wb.id.to_s)
      
  end
  
  def homepage_city_top_right
      order = params[:order] ? params[:order] : "website_banner_id ASC, locale_id ASC, city_id ASC, the_order ASC"
      wb = WebsiteBanner.find_by_name('homepage_city_top_right')
      @yourtext_yourimage = WebsiteBannerImage.find(:all, :order => order, :conditions=>"website_banner_id = " +  wb.id.to_s)
      
  end

  def banners
    #ORDER
    @banners_order = HomepageBanner.find(:all, :conditions=>["position = ?", "left"], :order=>"order_slider ASC")
    
    #RIGHT BANNER
    banner_right = HomepageBanner.find(:all, :conditions=>["homepage_banners.index=? AND position=?", 0, "right"])
    if banner_right != nil && banner_right.size > 0
      @banner_right_index = banner_right.first.index
      @banner_right_position = banner_right.first.position
      banner_right.first.all_en == 0 ? @banner_right_all_en = "" : @banner_right_all_en = "checked=\"yes\""
		 	banner_right.first.all_fr == 0 ? @banner_right_all_fr = "" : @banner_right_all_fr = "checked=\"yes\""
		 	banner_right.first.display == 0 ? @banner_right_display = "" : @banner_right_display = "checked=\"yes\""

      path_lang_static = path_lang(session[:language_id], session[:country]).gsub("-", "_")
      if path_lang_static == nil
        path_lang_static = path_lang(session[:language_id], session[:country])
      end
      @banner_right_txt_lang = banner_right.first["text_"+path_lang_static]
      @banner_right_link = banner_right.first["link_"+path_lang_static]
    else
      @banner_right_index = 0
      @banner_right_position = "right"
      @banner_right_all_en = "checked=\"yes\""
      @banner_right_all_fr = "checked=\"yes\""
      @banner_right_display = "checked=\"yes\""
      @banner_right_txt_lang = ""
      @banner_right_link = ""
    end
    @banner_path_img = "/images/homepage/banners/#{path_lang(session[:language_id], session[:country])}/#{@banner_right_position}_#{@banner_right_index}.jpg"
  end

  def save_order
    set_info_from_params(params[:order_1], 1) if params[:order_1]
    set_info_from_params(params[:order_2], 2) if params[:order_2]
    set_info_from_params(params[:order_3], 3) if params[:order_3]
    set_info_from_params(params[:order_4], 4) if params[:order_4]
    
    render :text=>"update"
  end
  
  def save_link
    params["banner"]["display"] == "on" ? display = 1 : display = 0
    find_row = HomepageBanner.find(:all, :conditions=>["position=? AND homepage_banners.index=?", params["banner"]["position"], params["banner"]["index"]])
    txt_column_field = "text_"+path_lang(params["banner"]["lang"].to_i, params["banner"]["country"])
    link_column_field = "link_"+path_lang(params["banner"]["lang"].to_i, params["banner"]["country"])
    if link_column_field == "link_fr-eu"
      link_column_field = "link_fr_eu"
      txt_column_field = "text_fr_eu"
    end
    if params["banner"]["lang"] == 1
      find_row.first.update_attributes(txt_column_field=>params["banner"]["text_lang"], link_column_field=>params["banner"]["link"], :display=>display)
    else
      find_row.first.update_attributes(txt_column_field=>params["banner"]["text_lang"], link_column_field=>params["banner"]["link"], :display=>display)
    end
  end
  
  def set_info_from_params(param, order)
    index = param.gsub("banner_", "")
    
    #change the order of the current index
    find_row = HomepageBanner.find(:all, :conditions=>["position=? AND homepage_banners.index=?", "left", index])
    if find_row.size > 0
      find_row.first.update_attributes(:order_slider=>order)
    end
    
    return index
  end

  def path_lang(lang_id, country)
    case country
      when "CA"
        lang_id == 1 ? lang_path = "fr" : lang_path = "en"
      when "US"
        lang_path = "us"
      when "FR"
        lang_path = "france"
      when "GB"
        lang_path = "uk"
      when "BE"
        lang_path = "be"
      when "CH"
        lang_path = "ch"
      when "AU"
        lang_path = "australia"
      when "EU"
        lang_id == 1 ? lang_path = "fr-eu" : lang_path = "eu"
    end
    
    return lang_path
  end
  
  def delete_tmp
    #delete the tmp file
    path_tmp = "public"+params["file_remove"].gsub(":", "-").gsub("'", "")
    File.delete(path_tmp) if File.exist?(path_tmp)
    
    render :text=>"ok"
  end
end
