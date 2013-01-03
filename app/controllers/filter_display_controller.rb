class FilterDisplayController < ApplicationController
  require 'RMagick'
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  before_filter :authorize_validation, :only=>[:idliketovalidatethisdesignwithoutusingthebackofficeabc654897poi, :idliketovalidatethisdesignwithoutusingthebackofficeabce5f897wrti, :idliketovalidatethisdesignwithoutusingthebackofficeabce9jd47halwpr]
  before_filter :setup_shop, :only => [:new, :shop, :result_search, :result_tag, :staff_pick, :designers, :category]
  before_filter :prepare_create_tshirt, :only => [:create_tshirt, :flash_test]
  before_filter :prepare_category, :only => [:category]
  before_filter :prepare_sitemap, :only => [:sitemap]
  before_filter :prepare_sitemap_html, :only => [:sitemap_html]
  before_filter :prepare_design, :only => [:design]
  before_filter :prepare_js_homepage, :only=>[:izishirt_2011]
  before_filter :prepare_search, :only=>[:search]
  before_filter :prepare_top25, :only=>[:shop]
  before_filter :prepare_staff_pick, :only=>[:staff_pick]
  before_filter :prepare_new, :only=>[:new]
  
  layout proc { |controller| controller.action_name == "sitemap" ? "sitemap" : "izishirt_2011" }

  private

  def prepare_top25
    @meta_title = t(:meta_title_top25)
  end

  def prepare_new
    @meta_title = t(:meta_title_new_designs)
  end

  def prepare_staff_pick
    @meta_title = t(:meta_title_staff_picks)
  end

  def setup_shop
    session[:shop_page]=params[:action]
    session[:shop_page_id]=params[:id] ? params[:id] : nil
    session[:shop_page_parent_category]=params[:parent_category] ? params[:parent_category] : nil
    session[:shop_page_sub_category]=params[:sub_category] ? params[:sub_category] : nil
    session[:shop_page_search]=params[:search] ? params[:search] : nil
    session[:shop_page_num]=params[:page] ? params[:page] : 1
    session[:shop_per_page]= (params[:per_page] && params[:per_page] != "") ? params[:per_page] : 25
    session[:shop_per_page] = 100 if session[:shop_per_page].to_i > 100

    @categories = root_categories()

    cat_cond = ""
    if params[:parent_category] && (params[:action] == 'category' || params[:action] == 'marketplace')

      # remove t-shirt- and -t-shirt
      params[:parent_category] = params[:parent_category].gsub("t-shirt-", "")
      params[:parent_category] = params[:parent_category].gsub("-t-shirt", "")

      begin
        if params[:sub_category]
          @category = Category.find(StringUtil.get_id_from_url(params[:sub_category]))
        else
          @category = Category.find(StringUtil.get_id_from_url(params[:parent_category]))
        end
      rescue

        # OLD FORMAT !
        begin
          if params[:sub_category]
            conditions = ["categories.active = true " +
                "AND EXISTS (SELECT sc.* FROM sub_categories AS sc WHERE sc.sub_category_category_id = localized_categories.category_id AND " +
                "sc.category_id IN (SELECT l3.category_id FROM localized_categories l3 WHERE l3.name = :parent_category))",
              {:parent_category => params[:parent_category]}]
            @category = LocalizedCategory.find_by_name(params[:sub_category], :include=>[:category], :conditions => conditions).category
          else
            @category = LocalizedCategory.find_by_name(params[:parent_category], :include=>[:category], :conditions => ["categories.active = true"]).category
          end

          redirect_to Category.url(@category.id, params[:lang], session[:language_id]), :status => :moved_permanently
          return
        rescue
          @category = Category.find(:first, :conditions => ["category_type_id = 3 AND active = 1 AND is_custom_category = 0"], :order => "position ASC")
        end
      end

      #@tags = FastTag.get_top_tags_name(18)


      @category_ids = build_ids(@category)
      cat_cond = "category_id = #{@category.id} and "
    elsif params[:id] && params[:action] != 'result_tag'
      @category = Category.find(params[:id], :include=>[:localized_categories])

      @category_ids = build_ids(Category.find(params[:id]))
      cat_cond = "category_id = #{params[:id]} and "
    end

    if params[:page_sub]
      session[:page_sub] = params[:page_sub]
    end

	if action_name == "staff_pick"
		begin
			canonical_url fix_canonical_url(@canonical_begin_url + "#{Language.print_force_lang(params[:lang])}#{t(:staff_pick_url)}")
		rescue
		end
	elsif action_name == "new"
		begin
			canonical_url fix_canonical_url(@canonical_begin_url + "#{Language.print_force_lang(params[:lang])}#{t(:new_designs_url)}")
		rescue
		end
	end

    #Grab a list of new images
    if action_name == "shop"

	begin
		# default.
		canonical_url fix_canonical_url(@canonical_begin_url + "#{Language.print_force_lang(params[:lang])}boutique")
	rescue
	end

      country_id = Country.find_by_shortname(session[:country]).id
      @new_submissions=  Image.find(:all,
        :order => "localized_images.sorting_rate DESC, images.id DESC",
        :conditions => ["images.staff_pick = 1 and images.active = ? and images.pending_approval = ? and images.is_private = ?", 1, 1, 0],
        :joins => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.category_id = #{get_custom_category("custom_staff_picks_").id} AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{session[:language_id]}",
        :limit=>5)
    else
      @new_submissions= TopDesign.find_by_region(session[:country], session[:language_id], 5).map { |td|
        td.image
      }
    end

  end

	def prepare_search
		if !params[:search]
			redirect_to :controller=>"/display", :action=>"shop", :status=>:moved_permanently
			return
		end

		search = params[:search]

		search = search.gsub("'", "''") if search

		begin
			@category = Category.find(:first, :conditions => ["category_type_id = #{CategoryType.find_by_name("Images").id} AND EXISTS(SELECT * from localized_categories lc WHERE lc.category_id = categories.id AND lc.search_str = '#{search}')"])
		rescue
		end

		search = search.gsub("+", " ") if search

		@search_keyword = search

		@meta_title = t(:meta_title_search_seo, :name => search.capitalize, :type => t(:design_search), :country => session[:country_long])
		@meta_keywords = t(:meta_keyword_search_seo, :name => search.capitalize, :domain_name => @DOMAIN_NAME, :country => session[:country_long], :type => t(:design_search))
		@meta_description = t(:meta_description_search_design_seo, :name => search.capitalize, :domain_name => @DOMAIN_NAME, :country => session[:country_long], :type => t(:design_search))

	end

  def prepare_js_homepage
    @meta_title = t(:meta_title_homepage, :country=>session[:country_long].capitalize)
    if @opera
      @js_homepage = ""
    else
      @js_homepage = "<script type=\"text/javascript\">

    function formatText(index, panel) {
	  return index + \"\";
    }
	
    
	
	
    $j(function () {
	
		$j('#slider1').responsiveSlides({
        maxwidth: 880,
        speed: 300
      });

        
	$j('#ca-container').contentcarousel();
	
	
    });
</script>"
    end

    canonical_url @canonical_begin_url

  end

  def prepare_sitemap
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end

  def prepare_sitemap_html
    @meta_title = t(:meta_title_sitemap_html)
  end


  def prepare_category


    session[:shop_per_page] = 20

    if @category
      @title = @category.local_meta_title(session[:language_id], get_country_for_meta_title, @DOMAIN_NAME)

      @meta_title = @title

      @meta_description = @category.local_meta_description(session[:language_id])

      @meta_keywords = @category.local_meta_keywords(session[:language_id])

	
	begin
		canonical_url fix_canonical_url(@canonical_begin_url + category_url(@category.id))
	rescue 
	end
    end
  end

	def prepare_design
		design_id = StringUtil.get_id_from_url(params[:id])

		begin
			@design = Image.find_by_id_and_active_and_always_private_and_is_private(design_id,1,0,0)
		rescue
			@design = nil
		end

		if @design && @design.user
      
      @meta_title = t(:meta_title_design_info_seo,:country=>get_country_for_meta_title, :name=>@design.name, :parent_category => @design.parent_category_name(session[:language_id]))

      @h1_title = t(:meta_h1_title_design_info_seo, :name=>@design.name, :parent_category => @design.parent_category_name(session[:language_id]))
			@meta_description = t(:meta_description_design_info_seo, :domain=>@DOMAIN_NAME.capitalize, :name=>@design.name, :parent_category => @design.parent_category_name(session[:language_id]))
			@meta_keywords = t(:meta_keyword_design_info_seo, :name=>@design.name)
			
			begin
				canonical_url fix_canonical_url(@canonical_begin_url + design_info_url(@design.id))
			rescue => e
			end
		else
			redirect_to "#{Language.print_force_lang(params[:lang])}boutique", :status => :moved_permanently
			return
		end

	end



  def authorize_validation
    session[:original_uri_login] = request.request_uri
    redirect_to :controller => '/myizishirt/login' unless User.verify_administrator session[:user_id]
  end

  def prepare_create_tshirt()


	begin
		# default.
		canonical_url fix_canonical_url(@canonical_begin_url + create_tshirt_url)
	rescue 
	end


    begin
      # Check for the model:
      @model_id = nil
      if params[:model]
        @model_id = params[:model]
      end
       begin
         seo_name = Model.find(@model_id).seo_model_name(session[:language_id])
       rescue
         seo_name = "T-Shirt"
       end


      image_id = nil

      [:image, :id].each do |param|
        if params[param]
          # this parameter can be use either for the image id or the model id
          # For the model, it must begins with vetement- or clothing-
          if params[param].index(I18n.t(:front_office_clothing, :locale => Language.find(1).shortname) + "-") == 0 || params[param].index(I18n.t(:front_office_clothing, :locale => Language.find(2).shortname) + "-") == 0

            @model_id = get_id_from_create_shirt_url(params[param])
            
          else
            image_id = get_id_from_create_shirt_url(params[param])
          end
        end
      end


      #@meta_title = t(:meta_title_flash_seo, :name=>@image.name) #t(:meta_title_create_shirt)
      @defaultdesign = (params[:id]) ?  params[:id] : ""
      @defaultdesign = image_id if @defaultdesign == "" && image_id

 

      @meta_title = t(:meta_title_create_shirt)

      if image_id
        @defaultdesign = image_id
      else
        begin
          if params[:id].to_i > 0
            @defaultdesign = (params[:id]) ?  params[:id] : ""
          end
        rescue
        end
      end


      begin
        if @defaultdesign && @defaultdesign != ""
          @image = Image.find_by_id_and_active_and_is_private_and_always_private(@defaultdesign,1,0,0)
          if @image.nil?
            redirect_to create_tshirt_url()
            return
          end


        end
      rescue
      end

      if @image
        t_name = @image.name

	begin
		m_name = Model.find(@model_id).seo_model_name(session[:language_id])
	rescue
		m_name = "T-Shirt"
	end
       
        @meta_title = t(:seo_create_tshirt, :title => truncate(t(:seo_model_title, :model_name => m_name, :name => t_name), :length => 25), :country=>get_country_for_meta_title)


        @meta_description = t(:meta_description_flash_seo, :name=>t_name)
        @meta_keywords = t(:meta_keyword_flash_seo, :name=>t_name)
         @flash_h1 = t(:seo_create_tshirt_h1, :title => truncate(seo_name, :length => 25))
        @flash_h1_text = t(:seo_create_tshirt_h1_text, :title =>truncate(seo_name, :length => 25) )

	begin
		canonical_url fix_canonical_url(@canonical_begin_url + design_url(@image.id))
	rescue
	end
      elsif params[:category]
        @category = Category.find(params[:category])
        if @category != nil
          t_name = @category.local_name(session[:language_id])
          
          @meta_title = t(:seo_create_tshirt, :title => truncate(t(:seo_model_title, :model_name => seo_name, :name => t_name), :length => 25), :country=>get_country_for_meta_title)

          @meta_description = t(:meta_description_flash_seo, :name=>t_name)
          @meta_keywords = t(:meta_keyword_flash_seo, :name=>t_name)
          @flash_h1 = t(:seo_create_tshirt_h1, :title => seo_name)
          @flash_h1_text = t(:seo_create_tshirt_h1_text, :title => seo_name)
        end
      elsif @model_id
        modelApparel = Model.find(@model_id)
        t_name = ''
        begin
            nameModel = modelApparel.local_seo_name(session[:language_id])            
          rescue
            nameModel = 'N/A'          
          end
          begin
            brandName = modelApparel.brand_name(session[:language_id])            
          rescue
            brandName = 'N/A'
          end
          begin
            genreName = modelApparel.category.local_name(session[:language_id])            
          rescue
            genreName = 'N/A'
          end
         seo_name = Model.find(@model_id).seo_model_name(session[:language_id])
         if seo_name == "T-Shirts"
           seo_name = "T-Shirt"
         end
         
        @meta_title = LocalizedModel.find_by_model_id_and_language_id(@model_id, session[:language_id]).create_meta_title
        @meta_description = LocalizedModel.find_by_model_id_and_language_id(@model_id, session[:language_id]).create_meta_description
        @meta_keywords = LocalizedModel.find_by_model_id_and_language_id(@model_id, session[:language_id]).create_meta_keywords
        @flash_h1 = LocalizedModel.find_by_model_id_and_language_id(@model_id, session[:language_id]).create_h1
        @flash_h1_text = LocalizedModel.find_by_model_id_and_language_id(@model_id, session[:language_id]).create_desc
	begin
		canonical_url fix_canonical_url(@canonical_begin_url + model_url(@model_id))
	rescue
	end

      elsif params[:product]
	begin
		product_id = get_id_from_create_shirt_url(params[:product])
		@product = Product.find(product_id)

		t_name = @product.name

		#@meta_title = t(:meta_title_flash_seo, :name => t_name, :country=>display_country)

		p_name = t(:seo_model_title, :model_name => @product.front_model_name(session[:language_id]), :name => @product.name)

    
	  @meta_title = t(:seo_create_tshirt, :title => truncate(p_name, :length => 25), :country=>get_country_for_meta_title)

		@meta_description = t(:meta_description_flash_seo, :name => t_name)
		@meta_keywords = t(:meta_keyword_flash_seo, :name =>t_name)
		@flash_h1 = t(:seo_create_tshirt_h1, :title => t_name)
    @flash_h1_text = t(:seo_create_tshirt_h1_text, :title => t_name)
		canonical_url fix_canonical_url(@canonical_begin_url + create_tshirt_product_url(@product.id))
	rescue
	end
      end
      
      if t_name.nil?
        t_name = @image ? @image.name : session[:country_long]
        @meta_title = t(:meta_title_flashpage, :country=>get_country_for_meta_title)
        @meta_description = t(:meta_description_flashpage, :country=>get_country_for_meta_title)
        @meta_keywords = t(:meta_keywords_flashpage, :country=>get_country_for_meta_title)
         @flash_h1 = t(:seo_create_tshirt_h1, :title => truncate(seo_name, :length => 25))
        @flash_h1_text = t(:seo_create_tshirt_h1_text, :title => truncate(seo_name, :length => 25))
      end

    rescue Exception => e
	logger.error("ERR => #{e}")
      # ERROR !!
      redirect_to create_tshirt_url()
      return
    end
  end

end


