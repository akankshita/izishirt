class Create::DesignsController < ApplicationController
  cache_sweeper :flash_design_sweeper
  #caches_action :index, :cache_path => Proc.new { |controller| controller.params }, :if => Proc.new{|c|c.params[:category] == nil && c.params[:search] == nil}, :expires_in=>60.minutes

  skip_before_filter :set_domain_language

  # GET /designs
  # GET /designs.xml
  # GET /designs.fxml
  def index
    #Category Load
    if params[:category] && !["my_shop_designs", "my_designs", "top_designs", "staff_picks", "new_submissions"].include?(params[:category])
      @designs = get_category_designs()
    elsif params[:category] && params[:category] == "my_designs"  
      @designs = get_my_designs()
    elsif params[:category] && params[:category] == "my_shop_designs"  
      @designs = get_my_shop_designs()
    elsif params[:category] && params[:category] == "staff_picks"
      @designs = get_staff_designs()
    elsif params[:category] && params[:category] == "new_submissions"  
      @designs = get_new_designs()
    elsif params[:search]
      @designs = get_search_designs()
    else 
      @designs = get_top_designs()
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @designs.to_xml(:only => attribute_array)}
      format.fxml  { render :fxml => @designs.to_fxml(:only => attribute_array)}
    end
  end
  
  def show
    @designs = [Image.find(params[:id])]
    @designs = Image.prepare_show_for_flex(@designs, false, @URL_ROOT)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @designs[0].to_xml(:only => attribute_array)}
      format.fxml  { render :fxml => @designs[0].to_fxml(:only => attribute_array)}
    end    
  end
  
  def get_image
    if params[:id].match '_'
      @uploaded_image = UploadedImage.find_by_timestamp(params[:id])
      @image_url = "#{@uploaded_image.relative_path}#{params[:id]}_png340.png"

      
    else
      @image = Image.find(params[:id])
      if @image.orig_image.file? && File.exists?(@image.orig_image.path("png340"))
        @image_url = @image.orig_image.url('png340')
      elsif @image.orig_image.file? && File.exists?(@image.orig_image.path("png200"))
        @image_url = @image.orig_image.url('png200')
      else
        @image_url = @image.orig_image.url("png")
      end
      
    end
    #render :text=>@image_url, :layout=>false
    respond_to do |format|
      format.html { redirect_to @image_url }
    end
  end

  def get_magnify
    if params[:id].match '_'
      @image = UploadedImage.find_by_timestamp(params[:id])
    else
      @image = Image.find(params[:id])
    end
    @image_url = @image.orig_image.url("340")

    respond_to do |format|
      format.html { redirect_to @image_url }
    end
  end
  
  def get_original
    begin
      if params[:id].match '_'
        @image = UploadedImage.find_by_timestamp(params[:id])
      else
        @image = Image.find(params[:id])
      end
      @image_url = @image.orig_image.url
      img = Magick::Image::read(@image.orig_image.path).first
      size = [img.columns, img.rows] 
      respond_to do |format|
        format.html { 
          #If can't find size set as 100x100 
          if size == nil
            render :text => "500x500"
          else
            render :text => size.join("x").to_s
          end
        }
      end
    rescue
      render :text => "0x0"
    end
  end  
  
  def upload

    require 'RMagick'

    directory = DIRECTORY_UPLOADED_IMAGE
    path = File.join(directory, "tmp/", params['uploadId'])
    File.open(path, "wb") { |f| f.write(params['Filedata'].read) }
    img = Magick::Image::read(path).first
    size = [img.columns, img.rows] 
    File.delete(path)

    #Don't crash if size calculation fails...just trust that its ok
    if size == nil || ( size[0] < 4000 && size[1] < 4000)
      @img = UploadedImage.create( :session_var=>params['sessionVar'], :orig_image => params['Filedata'], :timestamp=>params['uploadId'] )
      @img.uploaded = true
      @img.save
      render :text => 'success', :layout => false    
    else
      logger.debug("File upload failed")
      render :text => 'fail', :layout => false    
    end
  end
  
  private

  def get_category_designs
    @category_ids = Category.find(params[:category]).sub_category_ids
    @category_ids << params[:category]
    @category_ids.join(",")
    
    country_id = Country.find_by_shortname(session[:country]).id
    top_rated_images = get_top_rated_images(params[:category], country_id, NB_TOP_RATED_DESIGNS)
    top_rated_ids = top_rated_images.map { |image| image.id }
    where_top_rated = (top_rated_ids.length > 0) ? "AND localized_images.image_id IN (#{top_rated_ids.collect { |e| e.to_s}.join(",")}) " : ""
    order_by = order_by_top_rated_images()

    @designs = Image.paginate(:per_page => 20, :page=>params[:page],
      :conditions => ["images.category_id IN (:category_ids) AND active = :active AND pending_approval = :pending_approval AND is_private = :is_private ",
                      {:category_ids => @category_ids, :active => 1, :pending_approval => 1, :is_private => 0}],
      :joins => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{session[:language_id]} AND localized_images.category_id = #{params[:category]} #{where_top_rated}",
      :order => "#{order_by}")      

    Image.prepare_index_for_flex(@designs, true, @URL_ROOT)
  end

  def get_my_designs
    @designs = Image.paginate(:page=>params[:page],
      :per_page => 20,
      :include => :fast_tag_images,
      :order => "images.date_approved DESC",
      :conditions => ["user_id = ? and images.show_in_boutique = ?",
      session[:user_id], 1])

    Image.prepare_index_for_flex(@designs, true, @URL_ROOT)
  end

  def get_my_shop_designs
    @designs = Image.paginate(:page=>params[:page],
      :per_page => 20,
      :include => :fast_tag_images,
      :order => "images.date_approved DESC",
      :conditions => ["user_id = ? and images.show_in_boutique = ?",
      params[:user_id], 1])
    Image.prepare_index_for_flex(@designs, true, @URL_ROOT)
  end

  def get_staff_designs
    @category = get_custom_category("custom_staff_picks_")
    country_id = Country.find_by_shortname(session[:country]).id   
       
    @designs = Image.paginate(:page=>params[:page],
      :per_page => 20,
      :include => :fast_tag_images,
      :order => "localized_images.sorting_rate DESC, images.id DESC",
      :conditions => ["images.staff_pick = 1 and images.active = ? and images.pending_approval = ? and images.is_private = ?", 1, 1, 0],
      :joins => "LEFT JOIN localized_images ON localized_images.image_id = images.id AND localized_images.category_id = #{@category.id} AND localized_images.country_id = #{country_id} AND localized_images.language_id = #{session[:language_id]}")

    Image.prepare_index_for_flex(@designs, true, @URL_ROOT)    
  end

  def get_new_designs
    @designs = Image.paginate(:page=>params[:page],
      :per_page => 20,
      :order => "images.date_approved DESC",
      :conditions => ["active = ? and pending_approval = ? and is_private = ? and always_private = ?",
      1, 1, 0, 0])

    Image.prepare_index_for_flex(@designs, true, @URL_ROOT)
  end

  def get_search_designs
    @designs = Image.paginate(:per_page => 20,
      :page => params[:page],
      :conditions => ["(EXISTS(SELECT * FROM fast_tag_images, fast_tags WHERE fast_tag_images.image_id = images.id AND fast_tag_images.fast_tag_id = fast_tags.id AND  fast_tags.name = ? ) OR images.name like ? ) and active = ? and pending_approval = ? and is_private = ?",
      "#{params[:search]}", "%#{params[:search]}%", 1, 1, 0], :limit => 10)

    Image.prepare_index_for_flex(@designs, true, @URL_ROOT)
  end

  def get_top_designs
    @designs = Image.find_all_by_active(1, :limit=>20, :order=>"id DESC")#TopDesign.find_by_region(session[:country], session[:language_id]).map { |td| td.image }[0...20]
    Image.prepare_index_for_flex(@designs, false, @URL_ROOT)
  end

  def attribute_array
	    [:id,
			:filetype,
			:category_id,
      :thumbnail,
			:image,
      :big_image,
			:name,
			:lockcolor,
			:printtype,
			:imagetype,
			:minzoom,
			:maxzoom,
			:defaultzoom,
			:rotation,
			:pages,
			:page]
  end
  
  def minimal_attribute_array
	    [:id,
			:category_id,
      :thumbnail,
			:name,
			:pages,
			:page]
  end  

  def index_cache_path
    if params[:lang] != nil && params[:lang] != ''
      "flash/#{params[:lang]}/designs/designs.fxml"
    else
      "flash/designs/designs.fxml"
    end
  end
end
