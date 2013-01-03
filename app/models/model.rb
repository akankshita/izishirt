class Model < ActiveRecord::Base
	has_attached_file :spec_file, :whiny => false,
		:path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
		:url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension"

	has_many :model_previews, :order => "the_order ASC", :dependent => :destroy

	has_attached_file :apparel_preview, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :styles => {
      "small" => ['115x176>', :jpg],
      "medium" => ['300x300>', :jpg],
      "big" => ['1000x1000>', :jpg]
    },
    :convert_options => {
      :all => "-strip -colorspace RGB",
      "small" => '-background white -flatten -quality 100',
      "medium" => '-background white -flatten -quality 100',
      "big" => '-background white -flatten -quality 100'
    }

  validates_presence_of :preview_photo
  validates_presence_of :price
  
  has_and_belongs_to_many :coupons
  belongs_to :category
  belongs_to :user #for premium users who have their own models
  belongs_to :apparel_supplier
  belongs_to :brand, :class_name=>'Category', :foreign_key=>'brand_id'
  #belongs_to :product_category, :class_name=>'Category', :foreign_key=>'product_category_id'
  belongs_to :size_type
  #has_many :bulk_discounts
  #has_many :products
  has_many :fabric_styles
  has_many :localized_models, 					:dependent => :destroy
  has_many :model_specifications, 			:dependent => :destroy
  has_many :model_ext_specifications, 			:dependent => :destroy
  #has_many :quote_products
  has_many :out_of_stocks, :dependent => :destroy
  has_many :model_zones
  has_many :model_sizes, :dependent => :destroy
  has_many :model_size_specs #To remove after model_sizes are live and functional 
  has_many :sizes, :through => :model_size_specs, :order => "`order` ASC" #To remove after model_sizes are live and functional
  has_many :colors, :through=>:model_specifications, :include=>[:localized_colors]
  has_many :order_garment_listing_products
	has_many :garment_stocks
  has_many :ordered_products
  has_many :vip_model_specifications, :dependent => :destroy

  after_save :save_uploaded_pictures
  after_save :check_for_inactive
  
  named_scope :active, :conditions=>{ :active=>true, :show_in_front_office => true }
  named_scope :wholesale, :joins=>:brand, :conditions=>"categories.wholesale = 1"
  named_scope :brand, lambda {|brand| 
    { :conditions => "brand_id = #{brand.id}" }
  }
  named_scope :category, lambda {|category|
    { :conditions => "category_id = #{category.id}" }
  }

  named_scope :top_five_by_sales, :joins => :ordered_products,
    :conditions => ["models.active = true and models.show_in_front_office = true AND models.model_category = 'custom'"],
    :limit => 5,
    :group => 'models.id', :order => "count(ordered_products.id) desc"

  named_scope :top_five_by_category_and_sales, lambda {|category| 
    {:joins => :ordered_products,
      :conditions => ["models.active = true and models.show_in_front_office = true and models.category_id = #{category} AND models.model_category = 'custom'"],
      :limit => 5,
      :group => 'models.id', :order => "count(ordered_products.id) desc"} }

  named_scope :top_five_by_brand_and_sales, lambda {|brand| 
    {:joins => :ordered_products,
      :conditions => ["models.active = true and models.show_in_front_office = true and models.brand_id = #{brand} AND models.model_category = 'custom'"],
      :limit => 5,
      :group => 'models.id', :order => "count(ordered_products.id) desc"} }

  named_scope :top_five_by_sales_and_not_printable, :joins => :ordered_products,
    :conditions => ["models.active = true and models.show_in_front_office = true and models.model_category = 'blank'"],
    :limit => 5,
    :group => 'models.id', :order => "count(ordered_products.id) desc"

  named_scope :top_five_by_category_and_sales_and_not_printable, lambda {|category|
    {:joins => :ordered_products,
      :conditions => ["models.active = true and models.show_in_front_office = true and models.category_id = #{category} and models.model_category = 'blank'"],
      :limit => 5,
      :group => 'models.id', :order => "count(ordered_products.id) desc"} }

  named_scope :top_five_by_brand_and_sales_and_not_printable, lambda {|brand|
    {:joins => :ordered_products,
      :conditions => ["models.active = true and models.show_in_front_office = true and models.brand_id = #{brand} and models.model_category = 'blank'"],
      :limit => 5,
      :group => 'models.id', :order => "count(ordered_products.id) desc"} }

	def contains_big_preview?()
		#return true
		return FileUtil.is_bigger?(apparel_preview.path("big"),apparel_preview.path("medium"))
	end

	def local_seo_name(language_id)
		begin
			lm = localized_models.find_by_language_id(language_id)
		
			if lm.seo_name != ""
				return lm.seo_name
			end
		rescue
		end

		return local_name(language_id)
	end

	def short_name(language_id)
		begin
			name = local_name(language_id)

			name_parts = name.split(" ")

			final_name = ""

			name_parts.each do |name_part|
				final_name << name_part.strip + " "

				if final_name.split(" ").length >= 3
					break
				end
			end

			return final_name.strip
		rescue
		end

		return ""
	end

	def reference_id
		name = local_name(2).upcase
		name_parts = name.split(" ")

		name_parts.each do |p|
			if p =~ /^\w+$/ && p =~ /\d+/
				return p
			end
		end

		return ""
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

	def min_price
		begin
			return BlankPrice.find(:first, :order => "price ASC", 
				:conditions => ["model_specification_id IN (SELECT ms.id FROM model_specifications ms WHERE ms.model_id = #{id}) AND price IS NOT NULL and price > 0"]).price
		rescue
		end

		return 0.0
	end

	def is_express_shipping=(new_val)
		begin
			model = Model.find(id)

			tmp_new_val = new_val == "true" || new_val == "1" || new_val == true

			if tmp_new_val && ! model.is_express_shipping
				model.update_attributes(:express_shipping_active_since => Time.current)
			else
				model.update_attributes(:express_shipping_active_since => nil)
			end
		rescue 
		end
		
		super
	end
  
  def self.apparel_list_including_sub_categories(category_id)
    category = Category.find(category_id)
    models = []
    models << Model.find_all_by_active_and_show_in_front_office_and_user_id_and_category_id_and_model_category(1,
      1,
      nil,
      category.id,
      "custom",
      :order => 'RAND()')
    category.sub_categories.each do |sub_category|
      models << Model.find_all_by_active_and_show_in_front_office_and_user_id_and_category_id_and_model_category(1,
        1,
        nil,
        sub_category.id,
        "custom",
        :order => 'RAND()')
    end

    models.flatten
  end

	def seo_model_name(language_id)
		begin
			return Category.find(garment_type_id).local_name(language_id)
		rescue
		end

		return "T-Shirt"
	end
  

  def store_url(lang, lang_id)
    first_part = Category.store_url(product_category_id,lang,lang_id).split("-")
    first_part = first_part[0..(first_part.length-2)].join("-")
    return "#{first_part}/#{StringUtil.pretty_escape_url(local_name(lang_id))}-#{id}"
  end


  def front(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{id}/#{default_color_id}-front.jpg"
  end

  def apparel(base_url=nil)
	return apparel_preview.url("medium")
  end

  def front_of(color_id)
    f = File.join(DIRECTORY_MODEL, id.to_s, "#{color_id}-front.jpg")
    return f
  end
  
  def thumb(base_url=nil)
    base_url = base_url.nil? ? URL_ROOT : base_url
    "#{base_url}/izishirtfiles/models/#{id}/preview.jpg"
  end

  def active_model_sizes
    model_sizes.find_all_by_active(true)
  end

  def full_clone
    cloned_model = clone
    cloned_model.active = false
    
    cloned_model.model_sizes              = clone_model_sizes
    cloned_model.localized_models         = clone_localized_models  
    #cloned_model.fabric_styles            = clone_fabric_styles
    cloned_model.model_zones              = clone_model_zones
    cloned_model.model_specifications     = clone_model_specifications
    #cloned_model.model_ext_specifications = clone_model_ext_specifications
    cloned_model.save

    clone_model_images(cloned_model.id)

    return cloned_model
  end

  def active_in_stock_model_sizes(color_id)
    model_sizes.find(:all, 
      :conditions => ["active = ? and
                       not exists (select id from out_of_stocks 
                       where model_id = ? 
                       and color_id = ? 
                       and model_size_id = model_sizes.id)", true, id, color_id])
  end

  def self.default
    begin
      default_model_id = ApplicationSetting.find_by_name("default_model_id").value
      Model.find(default_model_id, :include=>[{:model_specifications => {:color => :localized_colors}}, 
          :localized_models])
    rescue
      Model.find(2, :include=>[{:model_specifications => {:color => :localized_colors}}, 
          :localized_models])
    end
  end
  
	def detailed_cost_price(model_size_id, quote_product_color_id)
		begin
			spec = ModelExtSpecification.find_by_model_id_and_model_size_id_and_quote_product_color_id(id, model_size_id, quote_product_color_id)
			return spec.cost_price
		rescue
			return cost_price
		end
	end

	def detailed_cost_price_with_color_id(model_size_id, color_id)
		begin
			color = Color.find(color_id)
			spec = ModelExtSpecification.find_by_model_id_and_model_size_id_and_quote_product_color_id(id, model_size_id, color.get_quote_product_color.id)
			return spec.cost_price
		rescue
			return cost_price
		end
	end

	def max_cost_price()
		specs = ModelExtSpecification.find_all_by_model_id(id)

		max_price = 0

		specs.each do |spec|
			if spec.cost_price > max_price
				max_price = spec.cost_price
			end
		end

		return max_price
	end

  def clothing_id(model, lang_id)
    # Changer URL flash qui load un model de t-shirt :
    # FR : izishirt.ca/fr/creation-t-shirt-personnalise/vetement-<nickname_tshirt>-<id>
    # EN : izishirt.ca/create-custom-t-shirt/clothing-<nickname_tshirt>-<id>

    return "#{I18n.t(:front_office_clothing, :locale => Language.find(lang_id).shortname)}-#{StringUtil.pretty_escape_url(model.localized_models.find_by_language_id(lang_id).nickname)}-#{model.id}"
  end

  def url(lang, lang_id)
    return "#{Language.print_force_lang(lang)}#{I18n.t(:create_shirt_url, :locale => Language.find(lang_id).shortname)}/#{clothing_id(self, lang_id)}"
  end

  def detail_url(color_id,lang, lang_id)

	begin
		parts = localized_models.find_by_language_id(lang_id).name.split(" ")

		n = "#{parts[0]} #{parts[1]} #{parts[2]}"

	rescue
		n = ""
	end

    return "#{I18n.t(:url_buy_blank_apparel, :locale => Language.find(lang_id).shortname)}/#{StringUtil.pretty_escape_url(n)}-#{id}#{color_id ? "?color="+color_id.to_s : ""}"
  end

  def buy_blank_url(color_id,lang, lang_id)
	return detail_url(color_id, lang, lang_id)
  end

  def in_stock?(model_size_id, color_id)
    !OutOfStock.exists?(:model_id => id, :color_id => color_id, :model_size_id => model_size_id)
  end

  def self.in_stock?(model_id, model_size_id, color_id)
    !OutOfStock.exists?(:model_id => model_id, :color_id => color_id, :size_id => model_size_id)
  end

  def self.print_stock(model_id, color_id, model_size_id)
    if Model.in_stock?(model_id, model_size_id, color_id)
      "in"
    else
      "out"
    end
  end

  def sorted_out_of_stocks(locale, lang)
    out_of_stocks.sort_by{|a| [a.color.local_name(lang), a.model_size.local_name(locale)]}
  end

  def get_bulk_discounts
    if bulk_discounts == [] || !ApplicationSetting.use_per_model_discount?
      BulkDiscount.defaults 
    else
      bulk_discounts
    end
  end

  def sorted_bulk_discounts
    bulk_discounts.sort{|x,y| x.start <=> y.start }
  end
  
  def percentage_wholesale_savings
    return 0 if retail_price == price
    (100.0-(price/retail_price*100.0)).to_i
  end
  
  def name(language_id)
    begin 
      return localized_models.find_by_language_id(language_id).name
    rescue
      return ""
    end
  end
  #
  #  def colors
  #    model_specifications.map {|s|s.color}
  #  end
  
  def has_color?(color_id)
    logger.debug("Colors!")
    model_colors = colors    
    begin
      color_to_find = Color.find(color_id)
      return model_colors.include?(color_to_find)
    rescue
      return false
    end    
  end
  
  def wholesale?
    brand.wholesale
  end

  def self.active_models
    Model.find_all_by_active_and_show_in_front_office_and_model_category(1,1, "custom",
      :include=>[{:model_specifications => {:color => :localized_colors}},
        :localized_models])
  end

  def self.mens_promo
    return 71
  end

  def local_name(language)
    name = ''
    localized_models.each { |lm| lm.language_id == language ? name = lm.name : nil }
    return name
  end

  def local_description(language)
    desc = ''
    localized_models.each { |lm| lm.language_id == language ? desc = lm.description : nil }
    return desc
  end


  def local_nickname(language)
    name = ''
    localized_models.each { |lm| lm.language_id == language ? name = lm.nickname : nil }
    return name
  end

  def brand_name(language)
    Category.find(brand_id).local_name(language)
  end

  def description(language)
    localized_models.find_by_language_id(language).description
  end

  def information(language)
    localized_models.find_by_language_id(language).model_info
  end

  def warning(language)
    localized_models.find_by_language_id(language).warning_text
  end

  def preview_photo_upload=(pic)
    if !pic.to_s.empty?
      @uploaded_preview_photo = pic
      write_attribute 'preview_photo', 'preview.jpg'
  	end
  end  

  def save_uploaded_pictures
    if (@uploaded_preview_photo)
      FileUtils.mkdir_p(File.join(DIRECTORY_MODEL, id.to_s))
      File.open(File.join(DIRECTORY_MODEL, id.to_s, preview_photo),'wb') do |file|
        file.puts @uploaded_preview_photo.read
      end
    end	
  end

  def check_for_inactive

  end
    
  def print_available_colors_html(language_id)
    model_specifications.collect {|ms| ms.color}.map {|c|
      unless c.nil?
        colors = " <img id='order_color_#{c.id}' class='color_block'  alt='#{c.localized_colors[language_id-1].name}'  src='/izishirtfiles/colors/#{c.preview_image}' onclick='set_order_color(#{c.id},#{id})'"
        if (c.id == default_color_id)
          colors += " style='border: 1px solid rgb(0,0,0)'"
        else
          colors += " style='border: 1px solid #999999;'"
        end
        colors += " />"
      end
    }
  end

  def self.prepare_index_for_flex(models, lang, base_url)
    
		models.map{ |model|		  
	    model.write_attribute('model_name', model.local_name(lang))
      model.write_attribute('image', model.front(base_url))
      model.write_attribute('thumbnail', model.thumb(base_url))
      model.write_attribute('show_sizes',model.show_sizes_in_flash)
	  
      model
		}
  end
    
  def self.prepare_show_for_flex(models, locale, lang, base_url, user_id=nil, countrycode="CA")
  #def self.prepare_show_for_flex(models, locale, lang, base_url, user_id=nil)
    
		models.map{ |model|		  
	    model.write_attribute('model_name', model.local_name(lang))
			model.write_attribute('desc', model.description(lang))
			model.write_attribute('info', model.information(lang))
			model.write_attribute('warning_text', model.warning(lang))
      model.write_attribute('default_zone', 1)
      model.write_attribute('image',model.front(base_url))
      model.write_attribute('thumbnail', model.thumb(base_url))
      model.write_attribute('show_sizes',model.show_sizes_in_flash)
      model.write_attribute('bulk_discount', BulkDiscount.discount_string(model.id))

      model.write_attribute('minimum_sale_price',0)
      model.write_attribute('designs_per_zone',2)
	  
	  
	  if  countrycode=="FR"
		if model.pricefr.to_f>0
			model.write_attribute('price',model.pricefr)
		else
			currencyinfo=Currency.find_by_label("EUR")
			priceconvert=model.price.to_f*currencyinfo.ratio
			priceconvert = priceconvert.round(2)
			model.write_attribute('price',priceconvert)
		end
	  else
		if countrycode=="US"
			currencylabel="USD"
		else 
			currencylabel="CAD"
		end
		currencyinfo=Currency.find_by_label(currencylabel)
		priceconvert=model.price.to_f*currencyinfo.ratio
		priceconvert = priceconvert.round(2)
		model.write_attribute('price',priceconvert)
	  end

      model.model_specifications.delete_if{|ms|ms.sizes == []}
      model.model_specifications.map{|spec|
        spec.sizes.map{|model_size| 
          model_size.write_attribute('name', model_size.local_name(locale))
          model_size
        }
        spec.img_front = spec.front(base_url)
        spec.write_attribute("thumb_front", spec.thumbnail_front(base_url))
        spec.img_back = spec.back(base_url)
        spec.write_attribute("thumb_back", spec.thumbnail_back(base_url))
        spec.img_left = spec.left(base_url)
        spec.write_attribute("thumb_left", spec.thumbnail_left(base_url))
        spec.img_right = spec.right(base_url)
        spec.write_attribute("thumb_right", spec.thumbnail_right(base_url))
        spec.color.write_attribute('name',spec.color.local_name(lang))
        spec.color.write_attribute('image',"#{base_url}/izishirtfiles/colors/#{spec.color.preview_image}")
        spec
      }
      model
		}
  end

	def default_model_size
		begin
			return active_model_sizes.first
		rescue
		end

		return nil
	end

  private

  def clone_model_sizes
    cloned_model_sizes = []

    model_sizes.each do |model_size| 
      cloned_model_size =  model_size.clone
      model_size.localized_model_sizes.each do |localized_model_size|
        cloned_model_size.localized_model_sizes << localized_model_size.clone
      end
      cloned_model_sizes << cloned_model_size
    end

    return cloned_model_sizes
  end

  def clone_localized_models
    cloned_localized_models = []
    
    localized_models.each do |localized_model|
      cloned_localized_models << localized_model.clone
    end

    return cloned_localized_models
  end

  def clone_fabric_styles
    cloned_fabric_styles = []

    fabric_styles.each do |fabric_style|
      cloned_fabric_style = fabric_style.clone
      fabric_style.localized_fabric_styles.each do |localized_fabric_style|
        cloned_fabric_style.localized_fabric_styles << localized_fabric_style.clone 
      end
      cloned_fabric_styles << cloned_fabric_style
    end

    return cloned_fabric_styles
  end

  def clone_model_zones
    cloned_model_zones = []

    model_zones.each do |model_zone|
      cloned_model_zones << model_zone.clone
    end 

    return cloned_model_zones
  end

  def clone_model_ext_specifications
    cloned_model_ext_specifications = []

    model_ext_specifications.each do |model_ext_specification|
      cloned_model_ext_specifications << model_ext_specification.clone
    end 

    return cloned_model_ext_specifications
  end 

  def clone_model_specifications
    cloned_model_specifications = []

    model_specifications.each do |model_specification|
      cloned_model_specification = model_specification.clone
      model_specification.model_prices.each do |model_price|
        cloned_model_specification.model_prices << model_price.clone
      end
      cloned_model_specifications << cloned_model_specification
    end 

    return cloned_model_specifications
  end

  def clone_model_images(cloned_model_id)
    system "cp -r #{DIRECTORY_MODEL}/#{id} #{DIRECTORY_MODEL}/#{cloned_model_id}"
  end

end
