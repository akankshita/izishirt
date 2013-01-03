class Category < ActiveRecord::Base

  after_create :expire_cache
  after_update :expire_cache
  after_destroy :expire_cache
  


    belongs_to :category_type
    has_many :localized_categories
    has_many :images
    has_many :models
    #has_many :wholesale_models, :class_name=>'Model', :foreign_key=>'brand_id', :include=>:model_specifications
    #has_and_belongs_to_many :stores
  #has_many :product_categories, :dependent => :destroy
    #has_many :products, :through => :product_categories
	#has_many :quote_products
    #has_and_belongs_to_many :stores
    
    named_scope :brands, :conditions=>"category_type_id = 4"
    
   has_and_belongs_to_many :sub_categories,
                           :join_table => 'sub_categories',
                           :foreign_key => 'category_id',
                           :association_foreign_key => 'sub_category_category_id',
                           :order => "position",
                           :class_name => 'Category'
                           
   has_and_belongs_to_many :parent_categories,
                           :join_table => 'sub_categories',
                           :foreign_key => 'sub_category_category_id',
                           :association_foreign_key => 'category_id',
                           :order => "position",
                           :class_name => 'Category'

  has_attached_file :image,
                    :styles => { :thumb => "184x60>" }

  def self.url(cat_id, lang, lang_id, per_page = 25)
    if ! cat_id || cat_id.to_i <= 0
      return ""
    end

    parent_category_name, sub_category_name = self.get_parent_sub_name(cat_id, lang_id)

    # Fr : izishirt.ca/fr/t-shirt-design/t-shirt-<category_name>
    # En : izishirt.ca/custom-t-shirt-design/<category_name>-t-shirt

    if lang_id == 2
      if sub_category_name == ""
        return "#{Language.print_force_lang(lang)}custom-t-shirt-design/#{StringUtil.pretty_escape_url(parent_category_name)}-t-shirt-#{@category.id}"
      else
        return "#{Language.print_force_lang(lang)}custom-t-shirt-design/#{StringUtil.pretty_escape_url(parent_category_name)}-t-shirt/#{StringUtil.pretty_escape_url(sub_category_name)}-#{@category.id}"
      end

    else
      if sub_category_name == ""
        return "#{Language.print_force_lang(lang)}t-shirt-design/t-shirt-#{StringUtil.pretty_escape_url(parent_category_name)}-#{@category.id}"
      else
        return "#{Language.print_force_lang(lang)}t-shirt-design/t-shirt-#{StringUtil.pretty_escape_url(parent_category_name)}/#{StringUtil.pretty_escape_url(sub_category_name)}-#{@category.id}"
      end
    end
  end

  def self.get_parent_sub_name(cat_id, lang_id)
    @category = Category.find(cat_id, :include=>[:localized_categories])
    current_localized_category_name = @category.local_name(lang_id)

    # Search for the parent:
    localized_parent_category = @category.localized_parent_category(lang_id)

    # Get the parent and sub-cat-names in order to have category/parent/sub-cat
    parent_category_name = (localized_parent_category) ? localized_parent_category.name : current_localized_category_name
    sub_category_name = (localized_parent_category) ? current_localized_category_name : ""

    return parent_category_name, sub_category_name
  end

  def self.marketplace_url(cat_id, lang, lang_id, filter_by, per_page = 15)

    category_id = -1
    is_new_products = false

    if cat_id == "new_products" || cat_id == "nouveaux_produits"
      parent_category_name = cat_id
      sub_category_name = ""
      category_id = cat_id
      is_new_products = true
    else
      if ! cat_id || cat_id.to_i <= 0
        return ""
      end

      parent_category_name, sub_category_name = self.get_parent_sub_name(cat_id, lang_id)
      category_id = @category.id
    end

    # Fr : izishirt.ca/fr/t-shirt-design/t-shirt-<category_name>
    # En : izishirt.ca/custom-t-shirt-design/<category_name>-t-shirt

    if lang_id == 2
      if sub_category_name == ""
        if is_new_products
          return "#{Language.print_force_lang(lang)}t-shirt-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/#{category_id}"
        else
          return "#{Language.print_force_lang(lang)}t-shirt-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/#{StringUtil.pretty_escape_url(parent_category_name)}-t-shirt-#{category_id}"
        end

      else
        return "#{Language.print_force_lang(lang)}t-shirt-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/#{StringUtil.pretty_escape_url(parent_category_name)}-t-shirt/#{StringUtil.pretty_escape_url(sub_category_name)}-#{category_id}"
      end

    else
      if sub_category_name == ""
        if is_new_products
          return "#{Language.print_force_lang(lang)}t-shirt-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/#{category_id}"
        else
          return "#{Language.print_force_lang(lang)}t-shirt-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/t-shirt-#{StringUtil.pretty_escape_url(parent_category_name)}-#{category_id}"
        end

      else
        return "#{Language.print_force_lang(lang)}t-shirt-marketplace/#{StringUtil.marketplace_filter_name_id(lang_id, filter_by)}/t-shirt-#{StringUtil.pretty_escape_url(parent_category_name)}/#{StringUtil.pretty_escape_url(sub_category_name)}-#{category_id}"
      end
    end
  end


  def self.store_url(cat_id, lang, lang_id)

    category_id = -1
    is_new_products = false

    if ! cat_id || cat_id.to_i <= 0
      return ""
    end
    parent_category_name, sub_category_name = self.get_parent_sub_name(cat_id, lang_id)
    category_id = cat_id

    # Fr : izishirt.ca/fr/t-shirt-design/t-shirt-<category_name>
    # En : izishirt.ca/custom-t-shirt-design/<category_name>-t-shirt

    if lang_id == 2
      if sub_category_name == ""
          return "#{Language.print_force_lang(lang)}store-#{StringUtil.pretty_escape_url(parent_category_name)}-#{category_id}"
      else
        return "#{Language.print_force_lang(lang)}store-#{StringUtil.pretty_escape_url(parent_category_name)}-#{StringUtil.pretty_escape_url(sub_category_name)}-#{category_id}"
      end

    else
      if sub_category_name == ""
          return "#{Language.print_force_lang(lang)}magasin-#{StringUtil.pretty_escape_url(parent_category_name)}-#{category_id}"
      else
        return "#{Language.print_force_lang(lang)}magasin-#{StringUtil.pretty_escape_url(parent_category_name)}-#{StringUtil.pretty_escape_url(sub_category_name)}-#{category_id}"
      end
    end
  end


  def self.boutique_url(cat_id, lang, lang_id)
    parent_category_name, sub_category_name = self.get_parent_sub_name(cat_id, lang_id)

    if lang_id == 1
      return "#{Language.print_force_lang(lang)}t-shirt-category/t-shirts-#{StringUtil.pretty_escape_url(parent_category_name)}-#{cat_id}"
    else
      return "#{Language.print_force_lang(lang)}t-shirt-category/#{StringUtil.pretty_escape_url(parent_category_name)}-t-shirts-#{cat_id}"
    end
  end

  def sub_categories_with_marketplace_products

    cats = []

    sub_categories.each do |cat|
      if cat.contains_marketplace_products_category() && cat.active
        cats << cat
      end
    end

    return cats
  end

  def contains_marketplace_products
    if contains_marketplace_products_category()
      return true
    end

    subs = sub_categories_with_marketplace_products

    subs.each do |sub|
      if sub.contains_marketplace_products_category
        return true
      end
    end

    return false
  end

  def contains_marketplace_products_category()
    begin
      if Product.find_all_by_category_id_and_product_removed(id, 0).length > 0
        return true
      end      
    rescue
    end

    return false
  end

  def self.parent_categories(type)
    where = ["active = :active and category_type_id = :type and (select count(category_id) from sub_categories where sub_category_category_id = categories.id) = 0", {:type => type, :active => true}]
    Category.find(:all, :conditions => where, :order => "position ASC")
  end

  def self.sub_categories(parent)
    Category.find(parent).sub_categories
  end

  def self.active_parent_categories(type)
    where = ["active = 1 and category_type_id = :type and (select count(category_id) from sub_categories where sub_category_category_id = categories.id) = 0", {:type => type}]
    Category.find(:all, :conditions => where)
    
  end

  def self.active_parent_categories_for_flash(lang)
    where = "categories.active = 1"
    where += " and is_custom_category = false"
    where += " and categories.category_type_id = 3"
    where += " and not exists (select category_id from sub_categories where sub_category_category_id = categories.id)"
    where = [where]
    categories = []
    Category.find(:all, :conditions => where, :include => [:sub_categories, :localized_categories])
  end
  
  def self.active_parent_categories_for_flex(lang)
    where = "categories.active = 1"
    where += " and is_custom_category = false"
    where += " and categories.category_type_id in (2,3)"
    where += " and not exists (select category_id from sub_categories where sub_category_category_id = categories.id)"
    where = [where]
    categories = []
    Category.find(:all, :conditions => where, :include => {:sub_categories => [:localized_categories], :localized_categories => []})
  end  

  #not used...too slow
  def self.display_category_for_flash(category,lang,depth=0)                                                                                            
    categories = []
    blanks = "   "*depth
    categories << {:blanks => blanks, :name => category.localized_categories[lang.to_i-1].name, :id => category.id, :images => category.images[0..10] }
    category.sub_categories.each do |sub_category|                                                                                                 
      categories << Category.display_category_for_flash(sub_category,lang,depth+1)                                                                 
    end                                                                                                                                                   
    categories                                                                                                                                           
  end     

	def self.garment_types_to_str(language_id)

		str = ""

		garment_types = Category.find(:all, :conditions => ["active = 1 AND category_type_id = #{CategoryType.find_by_name("Garment Type").id}"])

		garment_types = garment_types.sort_by { rand }

		cpt = 0

		garment_types.each do |cat| 
			cpt += 1

			str += cat.local_name(language_id) 

			str += ", " if cpt < 2

			if cpt == 2
				break
			end
		end

		return str
	end

  def self.model_categories()
    Category.find_all_by_active_and_category_type_id(1,2, :order => "ID desc")
  end

  def active_models
    models.find_all_by_active_and_show_in_front_office(1,1)
  end

	def local_search_str(lang_id)
		begin
			return localized_categories.find_by_language_id(lang_id).search_str
		rescue
		end

		return ""
	end

  def local_name(language)
    name = ''
    localized_categories.each { |lc| lc.language_id == language ? name = lc.name : nil }
    return name
  end
    
  def local_meta_title(language,country,domain="izishirt.ca")
    name = local_name(language)

    if name == "New Designs"
       title = I18n.t(:meta_title_category_added_2, :category=>name, :country=>country)
    else
       title = I18n.t(:meta_title_category_added_2, :category=>name, :country=>country)
    end
   


    return title
    
  end

  def local_title(language,country)
    name = local_name(language)

    if language == 1

      title = "T-shirts #{name.capitalize} - #{I18n.t(:buy, :locale => Language.find(language).shortname)} "
      title+= country != "CA" ? I18n.t(:tshirts_and_apparel_2, :locale => Language.find(language).shortname) :  I18n.t(:tshirts_and_apparel, :locale => Language.find(language).shortname)
      title+= " #{name.capitalize}"
    else
      title = "#{name.capitalize} T-shirts - #{I18n.t(:buy, :locale => Language.find(language).shortname)} "
      title+= "#{name.capitalize} #{I18n.t(:tshirts_and_apparel, :locale => Language.find(language).shortname)}"
    end

    title = localized_categories[language-1].meta_title if (localized_categories[language-1].meta_title != "")

    return title

  end
    
  def local_meta_description(language)
      name = local_name(language)
      father = localized_parent_category(language)
    
      if language == 1

        description = "Choisit parmi des centaines de designs de T-shirt #{name} et cr&eacute;e tes propre T-shirts #{name} sur mesure. Achète ou cr&eacute;er des chandails personnalis&eacute;s avec des designs #{name}!"
      else
        description = "Choose from hundreds of #{name} T-shirt designs or use your images and text to make your own #{name} shirts! Create or buy #{name} T-shirts!"
      end    
      #description = localized_categories[language-1].meta_description if localized_categories[language-1].meta_description != ""
      if name == nil 
        description += I18n.t(:meta_description_category_added)      
      elsif father == nil
        description += I18n.t(:meta_description_category_added_2, :category=>name)
      else
        description += I18n.t(:meta_description_category_added_3, :father=>father.name)
      end
      return description      
  end
  
  def local_meta_keywords(language)
      name = local_name(language)
      father = localized_parent_category(language)
      Rails.logger.error("father = #{father}")
    
      if language == 1

        keywords = name+", "+name+" T-shirts, "+name+" "+I18n.t(:display_home_meta_keywords, :locale => Language.find(language).shortname)
      else
        keywords = name+", "+name+" T-shirts, "+name+" "+I18n.t(:display_home_meta_keywords, :locale => Language.find(language).shortname)
      end
      keywords += ", " + ((language == 1) ? "T-shirts #{father.name}" : "#{father.name} T-shirts") if father

      
      keywords= localized_categories[language-1].meta_keywords if localized_categories[language-1].meta_keywords != ""
      
      return keywords      
  end

  def localized_parent_category(language_id)
    begin
      if parent_categories.length > 0
        return LocalizedCategory.find_by_category_id_and_language_id(parent_categories[0].category_id, language_id)
      end
    rescue
      return nil
    end

    return nil
  end

  def banner(currency, language_id)
    localized_cat = LocalizedCategory.find_by_category_id_and_language_id(id, language_id)

    images = localized_cat.images_currency(currency)

    if images == []
      localized_cat = localized_parent_category(language_id)

      if localized_cat
        images = localized_cat.images_currency(currency)
      end
      
    end

    return images
  end
  
	def self.prepare_for_flex(categories,lang)	  	 
	  categories.map{ |category|
	    category.write_attribute('name',category.local_name(lang))
      category.write_attribute('cat_type',category.category_type_id)
      category.write_attribute('is_parent_category', true)
      category.sub_categories.each do |sub|
        sub.write_attribute('name',sub.local_name(lang))
        sub.write_attribute('is_parent_category', false)
        sub.write_attribute('cat_type',sub.category_type_id)        
      end
      category
		}
	end
  

  def active_images
    images.select{|i| i if i.active and !i.is_private and !i.always_private}
  end

  def expire_cache
    if category_type_id == 3 and is_custom_category == false
      folder = File.join(CACHEDIRECTORY, VIEWS_FOLDER, "products/categories")
      FileUtils.rm_rf(folder)
    end
  end

  def is_wall_decals
    return (local_name(2).match("Wall") || parent_categories && parent_categories.length > 0 && parent_categories[0].local_name(2).match("Wall"))
  end

  def is_universal
    return (local_name(2).match("Universal") || parent_categories && parent_categories.length > 0 && parent_categories[0].local_name(2).match("Universal"))
  end

end
