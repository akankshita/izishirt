class ModelSpecification < ActiveRecord::Base
  
  require 'RMagick'
  
  belongs_to :model
  belongs_to :color
  has_many :model_prices, :dependent => :destroy


	has_attached_file :apparel_preview, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :styles => {
      "medium" => ['300x300>', :jpg],
      "big" => ['1000x1000>', :jpg]
    },
    :convert_options => {
      :all => "-strip -colorspace RGB",
      "small" => '-background white -flatten -quality 100',
      "medium" => '-background white -flatten -quality 100',
      "big" => '-background white -flatten -quality 100'
    }

  has_attached_file :mask_picture, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/mask_:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/mask_:id_:style.:extension",
    :styles => {
      "medium" => ['340x340>', :png],
    }
  has_attached_file :mask_generation_picture, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/mask_generation_:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/mask_generation_:id_:style.:extension",
    :styles => {
      "medium" => ['340x340>', :png],
    }
  has_attached_file :supplier_generation_picture, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/supplier_generation_:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/supplier_generation_:id_:style.:extension",
    :styles => {
      "medium" => ['340x340>', :png],
    }

	def contains_big_preview?()
		#return true
		return FileUtil.is_bigger?(apparel_preview.path("big"),apparel_preview.path("medium"))
	end

	def year_created_on
		begin
			return created_at.to_date.year
		rescue
		end
		
		return nil
	end

	def month_created_on
		begin
			return created_at.to_date.month
		rescue
		end
		
		return nil
	end

	def day_created_on
		begin
			return created_at.to_date.day
		rescue
		end
		
		return nil
	end
  
  # Couldn't get this association quite right so i wrote sql for it
  # Models have specifications saying they are available in a certain 
  # color and specifications have sizes dependent on which sizes are available
  # for that model and which are in stock
  has_many :sizes, :class_name => "ModelSize", :finder_sql => 
    'SELECT model_sizes.* ' +
    'FROM model_sizes ' +
    'WHERE model_sizes.model_id = #{model_id} AND model_sizes.active = 1 ' +
    'AND NOT EXISTS (SELECT * from out_of_stocks ' +
      'WHERE out_of_stocks.model_id = #{model_id} ' +
      'AND out_of_stocks.model_size_id = model_sizes.id ' +
      'AND out_of_stocks.color_id = #{color_id})' 
  
    
  validates_presence_of :img_front  
  
  after_save :save_uploaded_pictures
  before_save :update_file_names
  attr_reader :img_front_upload, :img_back_upload, :img_right_upload, :img_left_upload

	def self.order_garment_comment_of(model_id, color_id)
		begin
			return ModelSpecification.find(:first, :conditions => ["model_id = #{model_id} AND color_id = #{color_id}"]).order_garment_comment
		rescue
		end
	
		return ""
	end

      
  def thumbnail_front(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{color_id}-front-preview.jpg"
  end
  
  def thumbnail_back(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{color_id}-back-preview.jpg"
  end
  
  def thumbnail_left(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{color_id}-left-preview.jpg"
  end
  
  def thumbnail_right(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{color_id}-right-preview.jpg"
  end
  
  def front(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{img_front}"
  end
  
  def back(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{img_back}"
  end
  
  def left(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{img_left}"
  end
  
  def right(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{model_id}/#{img_right}"
  end   

  def set_default_prices
    model_prices.each {|mp| mp.destroy}
    FlashConfig.find_all_by_config_type("price").each do |flash_config|
      desc = case flash_config.identifier
        when "one_design_price" then "1 img"
        when "two_design_price" then "2 img"
        when "text_price" then "txt"
        when "one_design_text_price" then "img + txt"
        when "two_design_text_price" then "2img + txt"
        when "design_stretch_price" then "big img"          
        when "text_stretch_price" then "big txt"          
        when "xl_price" then "XL"          
        when "xxl_price" then "XXL"
        when "xxxl_price" then "XXXL"
      end
      model_prices << ModelPrice.create({:model_specification_id => id,
        :identifier => flash_config.identifier,
        :description => desc,
        :price => flash_config.value.to_f
      })
    end
  end
  
  def img_front_upload=(pic)
    if !pic.to_s.empty?
      @uploaded_img_front = pic
      write_attribute 'img_front', color_id.to_s+'-front.jpg'
      write_attribute 'img_front_preview', color_id.to_s+'-front-preview.jpg'
  	end
  end
  
  def img_back_upload=(pic)
    if !pic.to_s.empty?
      @uploaded_img_back = pic
       write_attribute 'img_back', color_id.to_s+'-back.jpg'
       write_attribute 'img_back_preview', color_id.to_s+'-back-preview.jpg'
	end
  end  
  
  def img_left_upload=(pic)
    if !pic.to_s.empty?
      @uploaded_img_left = pic
      write_attribute 'img_left', color_id.to_s+'-left.jpg'
      write_attribute 'img_left_preview', color_id.to_s+'-left-preview.jpg'
  	end
  end  

  def img_right_upload=(pic)
    if !pic.to_s.empty?
      @uploaded_img_right = pic
       write_attribute 'img_right', color_id.to_s+'-right.jpg'
       write_attribute 'img_right_preview', color_id.to_s+'-right-preview.jpg'
  	end
  end       

  def resize_340(img, img_name)
    img.change_geometry!("340x340") { |cols, rows, img|
      img.resize!(cols, rows)
    }
	img.write File.join(DIRECTORY_MODEL, model_id.to_s, img_name)	  		
  end
  
  def resize_30(img, img_name)
	img.change_geometry!("30x30") { |cols, rows, img|
      img.resize!(cols, rows)
    }
	img.write File.join(DIRECTORY_MODEL, model_id.to_s, img_name)
  end
  
  def save_uploaded_pictures
  
    if (@uploaded_img_front)
	  File.open(File.join(DIRECTORY_MODEL, model_id.to_s, img_front),'wb') do |file|
        file.puts @uploaded_img_front.read
      end
	
	if model.model_category = 'custom'
	  resize_340(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_front)).first, img_front)
	  resize_30(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_front)).first, img_front_preview)
	end
    end
	
    if (@uploaded_img_back)
      File.open(File.join(DIRECTORY_MODEL, model_id.to_s, img_back),'wb') do |file|
        file.puts @uploaded_img_back.read
      end
      resize_340(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_back)).first, img_back)
	  resize_30(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_back)).first, img_back_preview)
    end
	
    if (@uploaded_img_left)
      File.open(File.join(DIRECTORY_MODEL, model_id.to_s, img_left),'wb') do |file|
        file.puts @uploaded_img_left.read
      end
      resize_340(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_left)).first, img_left)
	  resize_30(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_left)).first, img_left_preview)
    end
	
    if (@uploaded_img_right)
      File.open(File.join(DIRECTORY_MODEL, model_id.to_s, img_right),'wb') do |file|
        file.puts @uploaded_img_right.read
      end
      resize_340(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_right)).first, img_right)
	  resize_30(Magick::Image.read(File.join(DIRECTORY_MODEL, model_id.to_s, img_right)).first, img_right_preview)
    end			
	
  end

  def update_file_names
	begin
	    if img_front!="" && img_front != "#{color_id}-front.jpg"
	      File.rename("#{DIRECTORY_MODEL}/#{model_id}/#{img_front}","#{DIRECTORY_MODEL}/#{model_id}/#{color_id}-front.jpg") 
	      write_attribute 'img_front', color_id.to_s+'-front.jpg'
	    end
	    if img_back!="" && img_back != "#{color_id}-back.jpg"
	      File.rename("#{DIRECTORY_MODEL}/#{model_id}/#{img_back}","#{DIRECTORY_MODEL}/#{model_id}/#{color_id}-back.jpg") 
	      write_attribute 'img_back', color_id.to_s+'-back.jpg'
	    end
	    if img_left!="" && img_left != "#{color_id}-left.jpg"
	      File.rename("#{DIRECTORY_MODEL}/#{model_id}/#{img_left}","#{DIRECTORY_MODEL}/#{model_id}/#{color_id}-left.jpg") 
	      write_attribute 'img_left', color_id.to_s+'-left.jpg'
	    end
	    if img_right!="" && img_right != "#{color_id}-right.jpg"
	      File.rename("#{DIRECTORY_MODEL}/#{model_id}/#{img_right}","#{DIRECTORY_MODEL}/#{model_id}/#{color_id}-right.jpg") 
	      write_attribute 'img_right', color_id.to_s+'-right.jpg'
	    end
	rescue
	end
  end

  def check_deactivation_model
    #cmd = "rake products:deactivate_from_model_color RAILS_ENV=#{RAILS_ENV} &"

    #system cmd
  end


  def mask_picture_url(base_url = nil)
    begin
      if mask_picture_file_name && mask_picture_file_name.length > 0
        base_url = base_url.nil? ? URL_ROOT : base_url
        return base_url + mask_picture.url(:medium)
      else
        return ""
      end

    rescue
      return ""
    end
  end

  def mask_generation_picture_url(base_url = nil)
    begin
      if mask_generation_picture_file_name && mask_generation_picture_file_name.length > 0
        base_url = base_url.nil? ? URL_ROOT : base_url
        return base_url + mask_generation_picture.url(:medium)
      else
        return ""
      end

    rescue
      return ""
    end
  end

  def supplier_generation_picture_url(base_url = nil)
    begin
      if supplier_generation_picture_file_name && supplier_generation_picture_file_name.length > 0
        base_url = base_url.nil? ? URL_ROOT : base_url
        return base_url + supplier_generation_picture.url(:medium)
      else
        return ""
      end

    rescue
      return ""
    end
  end
  
end
