class Admin::ImageController < Administration

  before_filter :set_is_edit

 # cache_sweeper :image_sweeper, :only=>[:create, :update, :destroy, :active]

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }


  def set_is_edit
    @is_editing = false
  end
  
  def index
    list
    render :action => 'list'
  end

  def list

    if params[:id] && params[:id].to_i <= 0
      params[:id] = nil
    end

    get_page_status()
    @pending_approval_id = params[:id]

    where = ["images.pending_approval  = :approval", {:approval => params[:id]}] if params[:id]

    #@image_pages, @images = paginate_with_sort :images, :per_page => ITEMS_PER_PAGE, :conditions => where
    @images = Image.paginate(:per_page => ITEMS_PER_PAGE, :conditions => where,
                :page => params[:page], :order => params[:order] ? params[:order] : "id DESC")
    populate_for_views
  end

	def reported_as_copyright
		@images = Image.paginate(:conditions => "reported_as_copyright = 1", :page => params[:page], :per_page => 50, :order => "id DESC")
	end

	def ignore_reported_copyright
		begin
			image = Image.find(params[:id])
	
			image.update_attributes(:reported_as_copyright => false, :description_copyright => nil)
		rescue
		end
		
		redirect_to :back
	end

	def remove_front_office_reported_copyright
		begin
			image = Image.find(params[:id])

			image.update_attributes(:always_private => true, :reported_as_copyright => false, :description_copyright => nil)
		rescue
		end

		redirect_to :back
	end

	def remove_front_boutique_reported_copyright
		begin
			image = Image.find(params[:id])

			image.update_attributes(:pending_approval => DESIGN_VALIDATION_STATE_DECLINED_ID, :reported_as_copyright => false, :description_copyright => nil)
		rescue
		end

		redirect_to :back
	end

	def products_reported_as_copyright
		# @products = Product.paginate(:conditions => "reported_as_copyright = 1", :page => params[:page], :per_page => 50, :order => "id DESC")
		@products = Product.paginate(:conditions => "reported_as_copyright = 1", :page => params[:page], :per_page => 50, :order => "id DESC")
	end

	def unmark_product_as_copyright
		begin
			product = Product.find(params[:id])
			
			product.update_attributes(:reported_as_copyright => false, :description_copyright => nil)
		rescue
		end

		redirect_to :back
	end

  def list_selected_best_seller
    get_page_status()
    @pending_approval_id = params[:id]

    where = ["images.pending_approval  = :approval AND images.is_bestseller = 1", {:approval => DESIGN_VALIDATION_STATE_APPROVED_ID}]

    #@image_pages, @images = paginate_with_sort :images, :per_page => ITEMS_PER_PAGE, :conditions => where
    @images = Image.paginate(:per_page => ITEMS_PER_PAGE, :conditions => where,
                :page => params[:page], :order => params[:order] ? params[:order] : "id DESC")
    populate_for_views

    render :action => :list
  end

  def new
    @image = Image.new
    @image.user_id = User.find_by_username("izishirt").id
    @selected_pending_approval = DESIGN_VALIDATION_STATE_APPROVED_ID
    @image.active = true
    
	  populate_for_views
  end

  def create
    @image = Image.new(params[:image])
    @image.orig_image = params[:uploaded_image][:orig_image]
    @image.date_approved = DateTime.now
    @image.pending_approval=1
#
   if @image.save
#      #save_tags
      flash[:notice] = t(:admin_flash_created)
      redirect_to :action => 'list', :id => 0
    else
      populate_for_views
      render :action => 'new'
    end
  end



  def edit
    @image = Image.find(params[:id])
    @models_info = get_models_colors_for_preview()
    populate_for_views(@image.user.language_id)

    @tab_to_open = (params[:tab_to_open]) ? params[:tab_to_open] : "tab_image"
    @selected_pending_approval = @image.pending_approval

    populate_infos_user(@image.user)

    @is_editing = true
  end

  def update_jpg_background_color
    @image = Image.find(params[:id])

    save_images(@image)

    redirect_to :back
  end

  def update
    @image = Image.find(params[:id])
    @models_info = get_models_colors_for_preview()

    @tab_to_open = (params[:tab_to_open]) ? params[:tab_to_open] : "tab_image"
    @selected_pending_approval = @image.pending_approval

    save_design_modification('list', @image.pending_approval)
  end

  def destroy
    @image = Image.find(params[:id])
    @image.deactivate_products("image_deleted")
    @image.destroy
    redirect_to :action => 'list'
  end
  
  def search(list_page = "list", search_page = "search")
    from_pagination = perform_search()

    respond_to do |format|
    format.html {
      #if from_pagination
        #render :update do |page|
        #  page.replace_html 'search_screen', :partial => 'search'
        #end
        #render :text => "test1"
      #  render :action => :list
      #else
        
      #  render :text => "test2"
      #end
      render :action => list_page
    }
    format.js {
      if from_pagination
        render :text => "test3"
        #render :update do |page|
        #  page.replace_html 'search_screen', :partial => 'search'
        #end
      else
        #render :text => "test4"
        render :partial => search_page
        
      end
    }
    end
  end

  def download_image
    image_id = params[:id]
    image_type = params[:type]
    
    image = Image.find(image_id)

    image_path = ""
    image_content_type = ""

    if image_type == "original"
      image_path = image.orig_image.url
      image_content_type = image.orig_image_content_type
    elsif image_type == "jpg"
      image_path = image.image_jpg.url
      image_content_type = image.image_jpg_content_type
    elsif image_type == "swf"
      image_path = image.image_swf.url
      image_content_type = image.image_swf_content_type
    elsif image_type == "png"
      image_path = image.image_png.url
      image_content_type = image.image_png_content_type
    end

    #image_content_type = "image/x-photoshop"

    if image_path["?"]
      image_path = image_path.split("?")[0]
    end

    send_file "#{RAILS_ROOT}/public#{image_path}", :type => image_content_type, :disposition => 'attachment', :filename => "#{image_id}#{File.extname(image_path)}"
  end

  def actions
    @categories = Category.parent_categories(3)
    #if params[:keyword_search]
    #  key_search(params[:keyword_search])
    #  render :layout => false
    #end
    key_search()
  end

  def key_search()
    
    search("actions", "search_actions")
  end

  def keyword_search
    key_search()
  end
  
  def bulk_update
    action = params[:id]
    case action
      when "set_to_active"
        attribute = :active
        value = true
      when "set_to_inactive"  
        attribute = :active
        value = false
      when "make_private"  
        attribute = :is_private
        value = true
      when "decline_for_copyright_infringement"
        attribute = :decline_for_copyright_infringement
        value = true
      when "decline_for_quality"
        attribute = :decline_for_quality
        value = true
      when "remove_from_staff_pick"
        attribute = :remove_from_staff_pick
        value = true
    end
    if attribute
      params[:image].each do |id, check_value|
        image = Image.find(id)
        
        if attribute == :decline_for_copyright_infringement
          pending_approval = DESIGN_VALIDATION_STATE_DECLINED_ID
          reason_obj = DesignImageDeclineReason.find_by_str_id("copyright")
          design_image_decline_reason_id = reason_obj.id
          decline_reason = reason_obj.localized_design_image_decline_reasons.find_by_language_id(image.user.language_id).template

          image.update_attributes(:pending_approval => pending_approval, :design_image_decline_reason_id => design_image_decline_reason_id, :decline_reason => decline_reason, :active => false)
        elsif attribute == :decline_for_quality
          pending_approval = DESIGN_VALIDATION_STATE_DECLINED_ID
          reason_obj = DesignImageDeclineReason.find_by_str_id("quality")
          design_image_decline_reason_id = reason_obj.id
          decline_reason = reason_obj.localized_design_image_decline_reasons.find_by_language_id(image.user.language_id).template

          image.update_attributes(:pending_approval => pending_approval, :design_image_decline_reason_id => design_image_decline_reason_id, :decline_reason => decline_reason, :active => false)

        elsif attribute == :remove_from_staff_pick
          image.update_attributes(:staff_pick => false)

          # remove localized images obj for the order:
          cat_id_staff_pick = LocalizedCategory.find_by_name("custom_staff_picks_fr").category.id
          loc_images = LocalizedImage.find(:all, :conditions => ["image_id = #{image.id} AND category_id = #{cat_id_staff_pick}"])

          loc_images.each do |li|
            li.destroy
          end
        else
          image.update_attribute(attribute,value)
        end
      end
    end
    
    perform_search()
  end

  def category_update
    category = Category.find(params[:id])

    if params[:image]
      params[:image].each do |id,check_value|
        image = Image.find(id)
        image.category = category
        image.save
      end
    end
    
    perform_search()
  end
  
   def active
    @active = Image.find(params[:id])
    (@active.active == true) ? @active.update_attributes(:active => false ) : @active.update_attributes(:active => true)
    redirect_to :action => 'list', :id => 	(@active.pending_approval == 1) ? "1" : "0"
  end   
   def staff_pick
    @image = Image.find(params[:id])
    (@image.staff_pick == true) ? @image.update_attributes(:staff_pick => false ) : @image.update_attributes(:staff_pick => true)
    redirect_to :action => 'list', :id =>	(@image.pending_approval == 1) ? "1" : "0"
  end   
  


  # Design validation process
  def design_validation_process
    
    @models_info = get_models_colors_for_preview()

    last_id = (params[:image_id_to_skip]) ? params[:image_id_to_skip] : params[:id]

    @image = get_image_by_image_state(DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID, last_id)


    @nb_to_do = count_images_by_image_state(DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID)


    language_id = (@image) ? @image.user.language_id : session[:language_id]

    populate_for_views(language_id)

    @tab_to_open = (params[:tab_to_open]) ? params[:tab_to_open] : "tab_image"
    @selected_pending_approval = DESIGN_VALIDATION_STATE_IS_BEING_IMPROVED_ID
    
    if @image
      populate_infos_user(@image.user)
    end
  end

  # Validate the design, redirect to the next if valid.
  def validate_design
    next_image = get_image_by_image_state(DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID, params[:id])

    expire_page :action => :improve_design_process
    expire_page :action => :design_validation_process

    popup_image_id = do_popup_image_id(params[:image][:is_private], params[:image][:always_private])

    next_image_id = next_image ? next_image.id : nil

    save_design_modification("design_validation_process", next_image_id, popup_image_id)
  end
  
  def skip_validate_design
    image_id_to_skip = params[:image_id_to_skip]
    
    redirect_to :action => "design_validation_process", :image_id_to_skip => image_id_to_skip
  end
  
  def skip_validate_improve_design_process
    image_id_to_skip = params[:image_id_to_skip]
    
    redirect_to :action => "improve_design_process", :image_id_to_skip => image_id_to_skip
  end

  # Improve design process
  def improve_design_process
    @models_info = get_models_colors_for_preview()
    
    last_id = (params[:image_id_to_skip]) ? params[:image_id_to_skip] : params[:id]

    @image = get_image_by_image_state(DESIGN_VALIDATION_STATE_IS_BEING_IMPROVED_ID, last_id)
    @nb_to_do = count_images_by_image_state(DESIGN_VALIDATION_STATE_IS_BEING_IMPROVED_ID)

    language_id = (@image) ? @image.user.language_id : session[:language_id]

    populate_for_views(language_id)

    @tab_to_open = (params[:tab_to_open]) ? params[:tab_to_open] : "tab_image"
    @selected_pending_approval = DESIGN_VALIDATION_STATE_APPROVED_ID

    if @image
      populate_infos_user(@image.user)
    end
  end

  def validate_improve_design_process
    @image = get_image_by_image_state(DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID, params[:id])
    @current_image = Image.find(params[:id])

    expire_page :action => :improve_design_process
    expire_page :action => :design_validation_process

    is_private = (@current_image.is_private) ? "true" : "false"
    always_private = (@current_image.always_private) ? "true" : "false"
    popup_image_id = do_popup_image_id(is_private, always_private)

    image_id = @image ? @image.id : nil

    save_design_modification("improve_design_process", image_id, popup_image_id)
  end
  
  ########################## CHECK IMAGES PROCESS ###############
  def check_design_process
    @categories = Category.parent_categories(3)
    
  end
  
  def skip_validate_execute_check_design_process
    image_id_to_skip = params[:image_id_to_skip]
    
    redirect_to :action => "execute_check_design_process", :image_id_to_skip => image_id_to_skip
  end
  
  def validate_execute_check_design_process
    last_id = (params[:image_id_to_skip]) ? params[:image_id_to_skip] : params[:id]
    
    
    @image = get_image_by_image_state(DESIGN_VALIDATION_STATE_APPROVED_ID, last_id, session[:design_verification_process_search_category])
    
    @current_image = Image.find(params[:id])
    
    @current_image.verified = true
    @current_image.save

    is_private = (@current_image.is_private) ? "true" : "false"
    always_private = (@current_image.always_private) ? "true" : "false"
    popup_image_id = do_popup_image_id(is_private, always_private)

    save_design_modification("execute_check_design_process", @image.id, popup_image_id)
  end
  
  def execute_check_design_process
    # "redirect"=>"execute_check_design_process", "search"=>{"category_id"=>"141", "verify_all"=>"false"}}
    
    if params[:search] && params[:search][:category_id].to_i > 0
      set_category_id_session(params[:search][:category_id])
    end
    
    if params[:search] && params[:search][:verify_all] == "true"
      unverify_image_in_category(params[:search][:category_id])
    end
    
    @models_info = get_models_colors_for_preview()
    
    last_id = (params[:image_id_to_skip]) ? params[:image_id_to_skip] : params[:id]

    @image = get_image_by_image_state(DESIGN_VALIDATION_STATE_APPROVED_ID, last_id, session[:design_verification_process_search_category])
    @nb_to_do = count_images_by_image_state(DESIGN_VALIDATION_STATE_APPROVED_ID, session[:design_verification_process_search_category])

    language_id = (@image) ? @image.user.language_id : session[:language_id]

    populate_for_views(language_id)

    @tab_to_open = (params[:tab_to_open]) ? params[:tab_to_open] : "tab_image"
    @selected_pending_approval = DESIGN_VALIDATION_STATE_APPROVED_ID

    if @image
      populate_infos_user(@image.user)
    end
    
    
  end

  ########################## Image files #########################
  def create_file
    @image_file = ImageFile.new(params[:image_file])
    @image = Image.find(params[:image_file][:image_id])

    status = @image_file.save

    render :text => ""
  end

  def reload_files
    @image = Image.find(params[:id])
    list_id = params[:list_id]

    render :partial => "/admin/image/list_image_files", :locals => {:with_delete => true, :upload_files_id => list_id}
  end

  def destroy_file
    file_id = params[:id]
    list_id = params[:list_id]
    file = ImageFile.find(file_id)


    if file
      file.destroy
    end

    @image = Image.find(params[:image_id])

    render :partial => "list_image_files", :locals => {:with_delete => true, :upload_files_id => list_id}
  end

  def download_image_file
    file_id = params[:id]

    file = ImageFile.find(file_id)

    send_file "#{RAILS_ROOT}/public/#{file.file.url}", :type => file.file_content_type, :disposition => 'attachment'
  end
 
  private
  
  def set_category_id_session(category_id, with_check_verified = true)
    category = Category.find(category_id)
    categories = [category] | category.sub_categories
    
    search_category_id = "(1 = 0 "
    
    categories.each do |cur_category|
      
      condition_verified = with_check_verified ? " AND images.verified = 0 AND images.is_private = 0 AND images.active = 1 AND images.always_private = 0 " : " AND images.is_private = 0 AND images.active = 1 AND images.always_private = 0 "
      
      search_category_id += " OR (images.category_id = #{cur_category.id} #{condition_verified}) "
    end
    
    search_category_id += ")"
    
    session[:design_verification_process_search_category] = search_category_id
  end
  
  # USE session[:design_verification_process_search_category]
  def unverify_image_in_category(category_id)
    set_category_id_session(category_id)
    
    set_category_id_session(category_id, false)
    Image.update_all("verified = 0", session[:design_verification_process_search_category])
    set_category_id_session(category_id, true)
  end

  def perform_search()
    get_page_status()
    @pending_approval_id = params[:id]
    @categories = Category.parent_categories(3)

    where = build_search_image_where(@category_ids)

    @search_criteria = where
    from_pagination = false

    if ! params[:search] && ! params[:order]
      from_pagination = true
    end

    #@image_pages, @images = paginate_with_sort :images, :per_page => ITEMS_PER_PAGE, :conditions => where
    @images = Image.paginate(:per_page => ITEMS_PER_PAGE, :conditions => where,
                :page => params[:page], :order => params[:order] ? params[:order] : "id DESC")

    return from_pagination
  end

  def get_page_status()
    if params[:id] == DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID.to_s
      @status = 'Pending Approval'
    elsif params[:id] == DESIGN_VALIDATION_STATE_APPROVED_ID.to_s
      @status = 'Approved'
    elsif params[:id] == DESIGN_VALIDATION_STATE_IS_BEING_IMPROVED_ID.to_s
      @status = t(:admin_menu_image_is_being_improved)
    elsif params[:id] == DESIGN_VALIDATION_STATE_DECLINED_ID.to_s
      @status = t(:admin_menu_image_declined)
    end
  end
  
  def backup_original_files(image)
    copied_orig = false
    
    if image.orig_image?
      
      styles = ["original", "340", "popup", "100", "thumb", "png", "png200"]
      
      styles.each do |style|
        begin
          FileUtils.cp_r(image.orig_image.path(style), image.orig_image.path(style) + ".bak", :remove_destination => true)
        rescue
        end
      end
      
      copied_orig = true
    end
    
    return copied_orig
  end
  
  def reverb_original_files(image, copied_orig, old_orig_image_updated_at, old_image_jpg_updated_at, old_image_png_updated_at)
    if copied_orig
      #styles = ["original", "340", "popup", "100", "thumb", "png"]
      styles = []
      
      # orig not modified, restore it
      if old_orig_image_updated_at == image.orig_image_updated_at
        styles << "original"
      end
      
      # jpg not modified, restore it
      if old_image_jpg_updated_at == image.image_jpg_updated_at
        styles << "340"
        styles << "popup"
        styles << "100"
        styles << "thumb"
      end
      
      # png not modified, restore it
      if old_image_png_updated_at == image.image_png_updated_at
        styles << "png"
        styles << "png200"
      end
      
      if image.orig_image?
        styles.each do |style|
          if image.orig_image.path(style)
            begin
              FileUtils.cp_r(image.orig_image.path(style) + ".bak", image.orig_image.path(style), :remove_destination => true)
            rescue
            end
          end
        end
      end
    end
  end
  
  def save_images(image)
    orig_valid = true
    jpg_valid = true
    png_valid = true
    swf_valid = true
    
    # Force save order..
    if params[:uploaded_image]
      if params[:uploaded_image][:orig_image]
        image.orig_image = params[:uploaded_image][:orig_image]
        orig_valid = image.save
        image.orig_image.reprocess!
      end
      
      if params[:uploaded_image][:image_jpg]
        image.image_jpg = params[:uploaded_image][:image_jpg]
        jpg_valid = image.save
      end
      
      if params[:uploaded_image][:image_png]
        image.image_png = params[:uploaded_image][:image_png]
        png_valid = image.save
      end
      
      if params[:uploaded_image][:image_swf]
        image.image_swf = params[:uploaded_image][:image_swf]
        swf_valid = image.save
      end
    end

    if params[:custom] && params[:custom][:color_code] && params[:custom][:color_code] != ""
      image.background_color = params[:custom][:color_code]
      image.change_background_jpg_images = File.new(image.orig_image.path())
      image.image_jpg_updated_at = Time.current # we changed the jpgs, woo ! (import for for  the reverb method)
      image.jpg_background_color = params[:custom][:color_code]
      image.save
    end
    
    return orig_valid && jpg_valid && png_valid && swf_valid
  end

  def save_design_modification(action_redirect = nil, id_redirect = nil, popup_image_id = nil)
    @image = Image.find(params[:id])
    last_pending_approval = @image.pending_approval
    action_redirect = (action_redirect == nil ) ? params[:redirect] : action_redirect
    id_redirect = (id_redirect == nil) ? nil : id_redirect

    # @image.update_attributes(params[:image]) &&
    
    # ! DON'T REMOVE THE ORIGINAL !
    old_orig_image_updated_at = @image.orig_image_updated_at
    old_image_jpg_updated_at = @image.image_jpg_updated_at
    old_image_png_updated_at = @image.image_png_updated_at
    
    copied_orig = backup_original_files(@image)
    
    if @image.update_attributes(params[:image]) && save_images(@image)

      #reverb_original_files(@image, copied_orig, old_orig_image_updated_at, old_image_jpg_updated_at, old_image_png_updated_at)
      
      #save_tags
      flash[:notice] = t(:admin_flash_updated)


      if params[:redirect] == "back"
        redirect_to :back
      else
        redirect_to :action => action_redirect, :id => id_redirect, :popup_image_id => popup_image_id # Next !
      end
    else
      #reverb_original_files(@image, copied_orig, old_orig_image_updated_at, old_image_jpg_updated_at, old_image_png_updated_at)
      populate_for_views

      if params[:redirect] == "back"
        redirect_to :back
      else
        render :action => params[:redirect]
      end
    end
  end

  def get_image_by_image_state(pending_approval, last_image_id = nil, category_condition = "")
    image_id_to_validate = nil

    image = nil

    if ! image_id_to_validate
      begin
        #conditions = (last_image_id) ? ["id <> #{last_image_id}"] : []
        next_pending_image = nil
        condition = category_condition != "" ? category_condition + " " : ""
        if last_image_id         
          condition += " id > " + last_image_id.to_s
        end

        next_pending_image = Image.find_by_pending_approval_and_is_contest(pending_approval, 0, :conditions => [condition], :order => "id ASC")
      rescue 
        next_pending_image = nil
      end

      image = next_pending_image
    else
      image = Image.find(image_id_to_validate)
    end

    return image
  end

  

  # Returns array [[model, color], ...]
  def get_models_colors_for_preview()
    result = []

    colors = ["FFFFFF", "000000", "8A878E", "5E5E5E"]

    colors.each do |color|
      cur_colors = Color.find_all_by_color_code_and_color_type_id(color, 3)

      cur_colors.each do |cur_color|

        result << [nil, cur_color]
        break;

      end
    end

    return result
  end

  
  

  def save_tags
	@image.save_tags
  end
  
  def populate_for_views(language_id = nil)
	  @catcol = Category.parent_categories(3)

    @design_validation_states = populate_select_design_validation_states()

    if language_id == nil
      language_id = session[:language_id]
    end

    @image_decline_reasons = populate_select_design_decline_reasons(language_id)

    @popup_image_id = params[:popup_image_id]
  end

  def get_shop_url(user)
    shop_url = "http://www.izishirt.ca"



    return shop_url
  end

  def populate_infos_user(user)
    @shop_url = get_shop_url(user)

    #Append decimal point to number before it used for nice display
    begin
      @total_sales =	(user.total_earnings -  user.earnings_paid).round(2).to_s.split(//)
      @total_sales[@total_sales.index('.')-1] = @total_sales[@total_sales.index('.')-1]+"."
      @total_sales.delete('.')
    rescue
      @total_sales = "0.00"
    end
  end

  def do_popup_image_id(is_private, is_always_private)
    popup_image_id = nil

    logger.error("test private = #{is_private}, always private = #{is_always_private}, active = #{params[:image][:active]}")

    if params[:image][:pending_approval].to_i == DESIGN_VALIDATION_STATE_APPROVED_ID &&
        is_private == "false" && is_always_private == "false" && params[:image][:active] == "true"
      popup_image_id = params[:id].to_i
    end

    return popup_image_id
  end

end
