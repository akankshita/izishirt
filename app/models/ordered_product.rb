class OrderedProduct < ActiveRecord::Base
	#belongs_to :coupon
	belongs_to :model
	belongs_to :color
	belongs_to :curency
	belongs_to :language
	belongs_to :store
	has_many :ordered_zones, :dependent => :destroy
	has_many :ordered_txt_lines, :through => :ordered_zones
	#has_many :images, :through => :ordered_zones
	#has_many :uploaded_images, :through => :ordered_zones
  has_many :earnings
	belongs_to :product
	belongs_to :order
	belongs_to :size #To remove after model_sizes are live and functional
  belongs_to :model_size
	has_one :user
	belongs_to :affiliate_user, :class_name => 'User', :foreign_key => 'affiliate_user_id'
  has_many :ordered_product_history
  belongs_to :apparel_supplier
  belongs_to :order_garment_listing
  belongs_to :purchase_source
  has_many :order_garment_listing_products
  belongs_to :ordered_product
	has_many :printer_statistics
	has_many :artwork_file_ordered_products
	has_many :ordered_product_shipping_histories
  has_one :ordered_product_comment


  def get_str_type
    return "Custom T-Shirt"
  end


  def coupon
    return false
  end


	def quantity_shipped
		begin
			return ordered_product_shipping_histories.sum(:quantity)
		rescue
		end

		return 0
	end

	def quantity_not_shipped

		n = quantity

		begin
			n = quantity - quantity_shipped

			if n < 0
				n = 0
			end 
		rescue
		end

		return n
	end

	def estimate_print_cost
		begin
			# find the printer
			the_printer = User.find(printer)

			if the_printer
				variable = AccountingVariable.find(:first, :conditions => ["name = 'encre' AND user_id = #{the_printer.id}"])
			end

			ink_cost = variable.value_at(created_on)

			if ! ink_cost
				ink_cost = variable.current_amount
			end

			return ink_cost * quantity.to_f
		rescue Exception => e
		end
	
		return 0.0
	end

	def printing_machine_user

		u = nil

		begin
			u = User.find(printer)
		rescue
		end

		if ! u
			begin
				u = User.find(order.printer)
			rescue
			end
		end

		return u
	end

	def recursive_ordered_products()
		prods = [self]

		sub_products_checked = []

		while true

			current_product = nil

			prods.each do |prod|
				if ! sub_products_checked.include?(prod)
					current_product = prod
					sub_products_checked << prod
					break
				end
			end

			if ! current_product
				break
			end
			
			sub_prods = OrderedProduct.find(:all, :conditions => ["ordered_product_id = #{current_product.id}"])

			sub_prods.each do |sub_prod|
				prods << sub_prod
			end
		end
		
		return prods
	end

	def out_of_stock?
		begin
			return ! model.in_stock?(model_size_id, color_id)
		rescue
		end

		return false
	end

	def printer_username
		begin
			return User.find(printer).username
		rescue
		end

		return "N/A"
	end

	def contains_non_ordered_missed?
		begin
			return printer_statistics.sum(:nb_missed, :conditions => ["reordered_missed = 0"]) > 0
		rescue
		end

		return false
	end

	def total_nb_printed
		begin
			return printer_statistics.sum(:nb_printed)
		rescue
		end

		return 0
	end

	def total_pretreatment
		begin
			return printer_statistics.sum(:pretreatment)
		rescue
		end

		return 0
	end

	def total_nb_prints
		begin
			return printer_statistics.sum(:nb_prints)
		rescue
		end

		return 0
	end

	def total_nb_missed
		begin
			return printer_statistics.sum(:nb_missed)
		rescue
		end

		return 0
	end

	# 
	def to_pretty_string(language_id = 1)
		begin
			return "#{model.local_name(language_id)}, #{color.local_name(language_id)}, #{model_size.local_name(language_id)}"
		rescue
			return "N/A"
		end
	end

	def to_s()
		return to_pretty_string(2)
	end
  
  def izishirt_cost(user_id)

	if coupon
		return 0.0
	end

    if model.vip_model_specifications.exists?(:user_id => user_id)
      izishirt_cost = model.vip_model_specifications.find_by_user_id(user_id).izishirt_cost
      print_cost   = model.vip_model_specifications.find_by_user_id(user_id).izishirt_print_cost
      izishirt_cost+= print_cost*ordered_zones.map{|oz|oz.ordered_zone_artworks}.flatten.size
    else
      izishirt_cost = 0
    end
    return izishirt_cost
  end


	def nb_prints_per_shirt

#		if coupon
#			return 0
#		end

		nb_artworks = 0

		ordered_zones.each do |ordered_zone|
			if ordered_zone.contains_artwork_or_text()
				nb_artworks += 1
			end
		end

		return nb_artworks
	end

	def self.ordered_product_zone_id_from_products(products, current_zone)

	    ordered_zone_index = -1

	    products.each do |product|
	      if product.is_extra_garment
		next
	      end

	      product.ordered_zones.each do |zone|
		if zone && zone.contains_artwork_or_text()
		  ordered_zone_index += 1

		  if current_zone.id == zone.id
		    return self.ordered_product_zone_id(ordered_zone_index)
		  end
		end
	      end
	    end

	    return ""
	  end

	def self.all_possible_id_letters()
	    ids_letters = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
	    ids_all = []

	    nb_levels = 10

	    (1..nb_levels).each do |nb_levels_cur|
	      ids_letters.each do |id_letters|

		build_cur_id = ""
		(1..nb_levels_cur).each do |tmp|
		  build_cur_id += id_letters
		end

		ids_all << build_cur_id
	      end
	    end

		return ids_all
	end

	# extract the ordered_products from an artwork filename
	# not that easy hehe.
	def self.find_ordered_products_from_artwork_file(file_obj)

		filename = file_obj.filename

		products = []

		begin
			if ! filename || filename == ""
				return nil
			end

			# Un fichier artwork a TOUJOURS le format suivant: W_<order_id>_<letters>
			filename = File.basename(filename.downcase, File.extname(filename.downcase))

			parts = filename.split("_")

			if parts.length < 2
				raise "associate to entire order"
			end

			order_id = parts[1].to_i
			order = Order.find(order_id)

			if ! order
				raise "associate to entire order"
			end

			if parts.length == 2
				# there is no letter
				order.ordered_products.each do |prod|
					if prod.is_extra_garment || prod.coupon
						next
					end
			
					products << prod
				end
			else
				letters = parts[2]
			
				possible_letters = self.all_possible_id_letters().reverse

				# Trouver les lettres qui sont dans le paquet de lettres
				possible_letters.each do |possible_letter|
					letter_to_test = possible_letter.downcase

					if letters.include?(letter_to_test)
						# important to not do 'a' when there is only 'aa' for example.
						letters = letters.gsub("#{letter_to_test}", "")

						# recherche les produits qui ont ces lettres à travers les produits et les zones
						order.ordered_products.each do |prod|

							if prod.is_extra_garment || prod.coupon
								next
							end

							prod.ordered_zones.each do |zone|
								begin
									tmp_letter = self.ordered_product_zone_id_from_products(order.ordered_products, zone).downcase
								rescue
									tmp_letter = "NOTFOUND"
								end

								# ok la lettre de cette zone de produit est une bonne lettre
								if tmp_letter == letter_to_test
									if ! products.include?(prod)
										products << prod
									end
								end
							end
						end
					end
				end
			end
		rescue
		end

		if products.length == 0
			file_obj.artwork_order_assignment.active_order.ordered_products.each do |prod|
				if prod.is_extra_garment || prod.coupon
					next
				end

				products << prod
			end
		end

		return products
	end

	def self.ordered_product_zone_id(index)
		ids_all = self.all_possible_id_letters()

	    if index > ids_all.length - 1 || index < 0
	      return "A"
	    end

	    return ids_all[index]
	  end

  #Used in the checkout to determine if products have bulk discounts
  #applied to them. Bulk discounts aren't applied if they come from 
  #a user's boutique who has the apply_discounts flag set to false
  def apply_discounts?
    begin
      return affiliate_user.apply_discounts if affiliate_user 
      return store.user.apply_discounts if store
      return true
    rescue
      return true
    end
  end
  def apply_size_prices?
    begin
      return affiliate_user.apply_discounts if affiliate_user
      return store.user.apply_discounts if store
      return true
    rescue
      return true
    end
  end
  def affiliate_product?
    affiliate_user ? true : false
  end

	# only useful for order_garments script !
	def initial_quantity=(q)
		@initial_quantity = q
	end
	
	def initial_quantity()
		return @initial_quantity
	end

	def oz_weight
		return model.weight * quantity.to_f
	end

  def is_reordered_garment?
    return is_extra_garment && price == 0
  end

  def images
    list_images = []

    ordered_zones.each do |oz|
      oz.ordered_zone_artworks do |artwork|
        if artwork.image && ! list_images.include?(artwork.image)
          list_images << artwork.image
        end
      end
    end

    return list_images
  end

  

  def uploaded_images
    list_images = []

    ordered_zones.each do |oz|
      oz.ordered_zone_artworks do |artwork|
        if artwork.uploaded_image && ! list_images.include?(artwork.uploaded_image)
          list_images << artwork.uploaded_image
        end
      end
    end

    return list_images
  end

  # , , 
  def update_model(attribute, from, to)
    if from.to_s != to.to_s
     
      if id
        begin 
          OrderedProductHistory.create(:attribute_changed => attribute, :from_id => from, :to_id => to, :ordered_product_id => id, :changed_on => DateTime.now)
        rescue
        end
        
        update_attributes(:garments_changed => true)
      end
    end
  end
  
  def model_id=(new_model_id)
    update_model("model", model_id, new_model_id)
    super
    
    
  end

  def self.fast_sql_contains_prints
    return "EXISTS (SELECT * FROM ordered_zones zone WHERE zone.ordered_product_id = ordered_products.id AND (EXISTS (SELECT * FROM ordered_zone_artworks art WHERE art.ordered_zone_id = zone.id) OR EXISTS (SELECT * FROM ordered_txt_lines line WHERE line.ordered_zone_id = zone.id)))"
  end
  
  def contains_prints
    ordered_zones.each do |ordered_zone|
      if ordered_zone.contains_artwork_or_text()
        return true
      end
    end
    
    return false
  end
  
  def model_other=(new_value)
    
    update_model("model", model_other, new_value)
    super
  end
  
  def color_other=(new_value)
    update_model("color", color_other, new_value)
    super
  end
  
  def color_id=(new_value)
    update_model("color", color_id, new_value)
    super
  end
  
  def size_id=(new_value)
    update_model("size", size_id, new_value)
    super
  end

  def expected()
    if self.ordered_from == "Sanmar"
      return business_days_future(1, self.garments_ordered_on)
    elsif self.ordered_from == "Technosport Ground"
      return business_days_future(4, self.garments_ordered_on)
    elsif self.ordered_from == "Technosport Air"
      return business_days_future(2, self.garments_ordered_on)
    else
      
      return business_days_future(1, self.garments_ordered_on)
    end
  end
  
  def display_expected_date
    if expected_date == nil
      return expected()
    end
    
    return expected_date
  end
  
  def model_in_stock()
    
    if (model_other != "" && model_other != nil) || (color_other != "" && color_other != nil)
      return true
    end
    
    return Model.in_stock?(model_id, model_size_id, color_id)
  end
  
  def supplier_name()
    if ! ordered_from.nil? && ordered_from != ""
      return ordered_from
    end
    
    begin
      return apparel_supplier.name
    rescue
      return ""      
    end
  end

  def business_days_future(num,start_date=nil)
    # takes the number of days in the past you are looking for
    # like 10 business days ago
    start_date ||= Date.today
    start_day_of_week = start_date.cwday #Date.today.cwday
    ans = 0
    # find the number of weeks
    weeks = num / 5.0

    temp_num = num > 5 ? 5 : num

    begin

      ans += days_to_adjust_f(start_day_of_week,temp_num)

      weeks -= 1.0

      temp_num = (weeks >= 1) ? 5 : num % 5
    end while weeks > 0

    days_ago = start_date + num + ans

  end

  def days_to_adjust_f(start_day_of_week,num)
    ansr = 0
    case start_day_of_week
    when 1
      if 5 == num then ansr += 2 end
    when 2
      if (4..5).include?(num) then ansr += 2 end
    when 3
      if (3..5).include?(num) then ansr += 2 end
    when 4
      if (2..5).include?(num) then ansr += 2 end
    when 5
      if (1..5).include?(num) then ansr += 2 end
    when 6
      if (1..5).include?(num) then ansr += 1 end
    when 7
      #do nothing
    end
    return ansr
  end

  def self.path_ordered_product(date)

    date = (date) ? date : Date.today

    return "ordered_products/#{date.year}/#{date.month}/#{date.day}"
  end
    
  def self.create_with_image_and_color_and_model(image, color, model)
    
    @new_product = OrderedProduct.new
    @new_product.created_on = Date.today # Very important for the ordered_products/date/checksum images !!
    @new_product.color_id = color.id
    @new_product.model_id = model.id
    @new_product.cost_price = model.cost_price
    @new_product.print_cost_white = Price.find(:first, :conditions=>["name = 'Zone White'"]).price
    @new_product.print_cost_white_xxl = Price.find(:first, :conditions=>["name = 'Zone White XXL'"]).price
    @new_product.print_cost_other = Price.find(:first, :conditions=>["name = 'Zone Other'"]).price
    @new_product.print_cost_other_xxl = Price.find(:first, :conditions=>["name = 'Zone Other XXL'"]).price
	if  model.pricefr.to_f > 0
		@new_product.price = model.pricefr 
	else
		@new_product.price = model.price
	end
    @new_product.price += Price.find(1).price if image
    @new_product.commission = 0.0
    @new_product.store_id = 64 # izishirt store
    @new_product.checksum = Digest::MD5.hexdigest(Time.to_s + rand.to_s)
    
    @new_product.ordered_zones << OrderedZone.create_with_centered_image(image, @new_product)
    @new_product.ordered_zones << OrderedZone.create_empty_back(@new_product)
    
    
    #@new_product.save    
    
    return @new_product
  end

  def self.find_group_and_sort(ids,lang)
    @all_garments = OrderedProduct.find(ids)

    #Group by model, color and size
    @garments = @all_garments.group_by do |garment| 
      if garment.model_other != nil && garment.model_other != ""
        [garment.model_other, garment.color_name(lang),garment.size]
      else
        [garment.model,garment.color_name(lang),garment.size]
      end
    end

    #Complexe sort, if this page is ever slow its probably because of this
    # Complex things are not necessary the faster ;)
    @garments = @garments.sort_by do |garment| 
      @color = ""
      @color = garment[0][1]
      @model = garment[0][0].class.name == "Model" ? garment[0][0].local_name(lang) : garment[0][0]
      [
        @model,
        @color,
         garment[0][2].name
      ]
    end
    return @garments

end

  def color_name(lang_id)
    if color_other != nil && color_other != "" && color_other != "Other"
      return color_other
    else
      begin
        return color.localized_colors.find_by_language_id(lang_id).name
      rescue
        return ""
      end
    end
  end

  def name(lang_id)
    if model_other != nil && model_other != "" && model_other != "Other"
      return model_other  
    end
    
    begin
      localized_model = LocalizedModel.find_by_model_id_and_language_id(model_id, lang_id)
      return localized_model.name
    rescue
      return ""
    end
  end
  
  def relative_product_folder_without_id()
    return "ordered_products/#{created_on.year}/#{created_on.month}/#{created_on.day}"
  end

  def relative_product_folder()
    if id.nil?
      ident = checksum
    else
      ident = id
    end
    return "ordered_products/#{created_on.year}/#{created_on.month}/#{created_on.day}/#{ident}"
  end

  def garments_state_str(supplier_id = nil)
    begin
	cond_supplier = (supplier_id) ? " order_garment_listings.apparel_supplier_id = #{supplier_id} " : ""
      garment_product = OrderGarmentListingProduct.find_by_ordered_product_id(id, :include => [:order_garment_listing], :conditions => [cond_supplier], :order => "order_garment_listing_products.id DESC")

      return garment_product.order_garment_state.name
    rescue
      return "N/A"
    end
  end

  def garments_state_color(supplier_id = nil)
    begin
	cond_supplier = (supplier_id) ? " order_garment_listings.apparel_supplier_id = #{supplier_id} " : ""
	garment_product = OrderGarmentListingProduct.find_by_ordered_product_id(id, :include => [:order_garment_listing], :conditions => [cond_supplier], :order => "order_garment_listing_products.id DESC")

      return garment_product.order_garment_state.color_code
    rescue
      return "#ffffff"
    end
  end


  def preview
    img="/izishirtfiles/"+OrderedProduct.path_ordered_product(created_on)+"/#{checksum}/#{checksum}-front.jpg"
    return img
  end

  def back_preview
    img="/izishirtfiles/"+OrderedProduct.path_ordered_product(created_on)+"/#{checksum}/#{checksum}-back.jpg"
    if File.exist?(RAILS_ROOT + "/public" + img)
      return img
    else
      return nil
    end
  end

  def left_preview
    img="/izishirtfiles/"+OrderedProduct.path_ordered_product(created_on)+"/#{checksum}/#{checksum}-left.jpg"
    if File.exist?(RAILS_ROOT + "/public" + img)
      return img
    else
      return nil
    end
  end

  def right_preview
    img="/izishirtfiles/"+OrderedProduct.path_ordered_product(created_on)+"/#{checksum}/#{checksum}-right.jpg"
    if File.exist?(RAILS_ROOT + "/public" + img)
      return img
    else
      return nil
    end
  end

  def reordered?(supplier_id = nil)
    begin
      return garment_listing_product(supplier_id).order_garment_state_id == OrderGarmentState.find_by_str_id("reordered").id
    rescue
    end
  end

  def back_order?(supplier_id = nil)
    begin
      return garment_listing_product(supplier_id).order_garment_state_id == OrderGarmentState.find_by_str_id("back_order").id
    rescue
    end
  end

	def processed_by
		begin
			u = User.find(garment_listing_product.processor_user_id)
			return "#{u.firstname} #{u.lastname} #{garment_listing_product.processed_at}"
		rescue
	
		end
		
		return "N/A"
	end

  def garment_listing_product(supplier_id = nil)
    begin
	cond_supplier = (supplier_id) ? " order_garment_listings.apparel_supplier_id = #{supplier_id} " : ""
      return OrderGarmentListingProduct.find_by_ordered_product_id(id, :include => [:order_garment_listing], :conditions => [cond_supplier], :order => "order_garment_listing_products.id DESC")
    rescue
      return nil
    end
  end

  def garment_listing(supplier_id = nil)
    begin
	cond_supplier = (supplier_id) ? " order_garment_listings.apparel_supplier_id = #{supplier_id} " : ""
      return OrderGarmentListingProduct.find_by_ordered_product_id(id, :include => [:order_garment_listing], :conditions => [cond_supplier], :order => "order_garment_listing_products.id DESC").order_garment_listing
    rescue
      return nil
    end
  end
  
  def set_checkout_source(checkout_source=nil, refer=nil)
    if checkout_source && checkout_source == "facebook" 
      purchase_source_id = PurchaseSource.find_by_str_id("facebook").id
    elsif checkout_source && checkout_source == "iframe" 
      purchase_source_id = PurchaseSource.find_by_str_id("iframe_flash").id
    elsif refer && refer == "true"
      purchase_source_id = PurchaseSource.find_by_str_id("boutique").id
    else
      purchase_source_id = PurchaseSource.find_by_str_id("website").id
    end
  end


  def define_is_blank

    for zone in ordered_zones

      if zone.ordered_zone_artworks.length > 0
        return false
      end
      if zone.ordered_txt_lines.length > 0
        return false
      end
    end
    return true
  end

  def generate_preview_using_xml(doc)
    logger.debug "[+] generating ordered product preview"
    zones = doc.elements["//data/products/product/zones"]

    is_custom_case = (model.model_category == 'custom_case')
    model_spec = ModelSpecification.find_by_model_id_and_color_id(model_id,color_id)

    for j in 1..zones.size.to_i
      logger.debug "[+] creating preview for zone #{j}"
      if is_custom_case
        img = GenerateImage.new(model_id, color_id, j,model_spec.supplier_generation_picture.path(:medium))
      else
        img = GenerateImage.new(model_id, color_id, j)
      end


      if is_custom_case


        logger.error("[+] Trying to add background color")
        logger.error("my back color #{model_background_color}")
        logger.error("[+] Trying to add mask on top")


        img.add_image_with_background_color('#' + model_background_color)

        img.write_artwork(0,0,is_custom_case)
        

        img.read_artwork(model_spec.mask_generation_picture.path(:medium))
        logger.error("[+] Read image")
        img.write_artwork(0,0, false)
        logger.error("[+] Done writing image")

        img.read_artwork(model_spec.supplier_generation_picture.path(:medium))
        logger.error("[+] Read image")
        img.write_artwork_only_supplier(0,0)
        logger.error("[+] Done writing image")
        

      end


      #TEXT GENERATION if text at back
      lines = zones.elements['zone['+j.to_s+']/lines']
      text_added = false
      if lines && lines.attributes['first'] == 'true'
        text_added = true
        img.generate_txt_from_xml(lines, is_custom_case)
        logger.debug "[+] Added txt lines to zone"
      end

      #MULTIPLE ARTWORK GENERATION
      artworks =  zones.elements["zone["+j.to_s+"]/artworks"]
      if artworks
        for a in 1..artworks.size.to_i
          artwork = artworks.elements["artwork["+a.to_s+"]"]
          if artwork
            logger.debug "[+] Adding artwork #{artwork.attributes["id"]}"
            if artwork.attributes['userUpLoadImage'] == 'true' or artwork.attributes["id"].match('_')
              artwork.attributes['userUpLoadImage'] = 'true'
              obj_artwork = UploadedImage.find_by_timestamp(artwork.attributes["id"])
            else
              obj_artwork = Image.find(artwork.attributes["id"])
            end

            path_png    = obj_artwork.orig_image.path("png")
            path_png200 = obj_artwork.orig_image.path("png200")
            path_png340 = obj_artwork.orig_image.path("png340")
            design_path = ""
            zoom        = artwork.attributes["zoom"].to_d

            if File.exists?(path_png340)
              design_path = path_png340
              zoom        = zoom / 3.4
            elsif File.exists?(path_png200)
              design_path = path_png200
              zoom        = zoom / 2
            else
              design_path = path_png
            end

            img.read_artwork(design_path)
            img.change_artwork(artwork.attributes["vreflection"],
              artwork.attributes["hreflection"],
              zoom,
              artwork.attributes["rotation"].to_i,
              artwork.attributes['initialWidth'],
              artwork.attributes['initialHeight'])
            img.write_artwork(artwork.attributes["x"].to_i, artwork.attributes["y"].to_i, is_custom_case)
          end
        end
      end

      #TEXT GENERATION If text at front
      if lines && !text_added
        img.generate_txt_from_xml(lines, is_custom_case)
        logger.debug "[+] Added txt lines to zone"
      end

      if is_custom_case
        logger.error("[+] Trying to add mask")
        img.read_artwork(model_spec.mask_generation_picture.path(:medium))
        logger.error("[+] Read image")
        img.write_artwork(0,0)
        logger.error("[+] Done writing image")

        logger.error("[+] Trying to add mask")
        img.read_artwork(model_spec.supplier_generation_picture.path(:medium))
        logger.error("[+] Read image")
        img.write_artwork_only_supplier(0,0)
        logger.error("[+] Done writing image")
      end

      if is_custom_case
        img.finalize(OrderedProduct.path_ordered_product(created_on), checksum, j, true)
      else
        img.finalize(OrderedProduct.path_ordered_product(created_on), checksum, j)
      end

    end
  end

  def self.create_from_product(product, 
                               model_size_id, 
                               color_id,
                               quantity, 
                               marketplace_price=false, 
                               user_id=nil)

    color_id = product.color_id if color_id.nil?
    ordered_product                      = OrderedProduct.new
    ordered_product.created_on           = Date.today
    ordered_product.product_id           = product.id
    ordered_product.store_id             = product.store_id
    ordered_product.curency_id           = product.curency_id
    ordered_product.color_id             = color_id
    ordered_product.model_id             = product.model_id
    ordered_product.cost_price           = product.model.cost_price
    ordered_product.print_cost_white     = Price.find(:first, :conditions=>["name = 'Zone White'"]).price
    ordered_product.print_cost_white_xxl = Price.find(:first, :conditions=>["name = 'Zone White XXL'"]).price
    ordered_product.print_cost_other     = Price.find(:first, :conditions=>["name = 'Zone Other'"]).price
    ordered_product.print_cost_other_xxl = Price.find(:first, :conditions=>["name = 'Zone Other XXL'"]).price
    ordered_product.model_size_id        = model_size_id
    ordered_product.quantity             = quantity
    ordered_product.model_background_color = product.model_background_color

    if marketplace_price && marketplace_price == "true"
      ordered_product.price = product.boutique_price("CA", model_size_id, color_id) - product.commission
      ordered_product.purchase_source_id = PurchaseSource.find_by_str_id("marketplace").id
    else
      ordered_product.price = product.shop2_price("CA", model_size_id, color_id)
      ordered_product.purchase_source_id = PurchaseSource.find_by_str_id("shop2").id
    end
    
    ordered_product.commission = product.commission
    ordered_product.commission = 0 if user_id && user_id == product.store.user_id
    ordered_product.checksum   = Digest::MD5.hexdigest(Time.to_s + rand.to_s)

    #Create ordered zones
    product.zones.each do |z|
      ordered_zone = OrderedZone.new
      ordered_zone.ordered_product_id = ordered_product.id
      ordered_zone.zone_type          = z.zone_type

      #Create ordered zone artworks
      z.zone_artworks.each do |artwork|
        cpy_artwork = OrderedZoneArtwork.new
        cpy_artwork.image_id            = artwork.image_id
        cpy_artwork.artwork_printtype   = artwork.artwork_printtype
        cpy_artwork.artwork_rotation    = artwork.artwork_rotation
        cpy_artwork.artwork_hreflection = artwork.artwork_hreflection
        cpy_artwork.artwork_vreflection = artwork.artwork_vreflection
        cpy_artwork.artwork_y           = artwork.artwork_y
        cpy_artwork.artwork_x           = artwork.artwork_x
        cpy_artwork.artwork_zoom        = artwork.artwork_zoom

        ordered_zone.ordered_zone_artworks << cpy_artwork
      end
      #EO Create ordered zone artworks

      ordered_zone.line_printtype   = z.line_printtype
      ordered_zone.line_hreflection = z.line_hreflection
      ordered_zone.line_vreflection = z.line_vreflection
      ordered_zone.line_rotation    = z.line_rotation
      ordered_zone.line_y           = z.line_y
      ordered_zone.line_x           = z.line_x
      ordered_zone.line_width       = z.line_width
      ordered_zone.line_height      = z.line_height

      ordered_product.ordered_zones << ordered_zone

      #Create ordered txt lines
      z.txt_lines.each do |tl|
        ordered_txt_line = OrderedTxtLine.new
        ordered_txt_line.ordered_zone_id = ordered_zone.id
        ordered_txt_line.line_position   = tl.line_position
        ordered_txt_line.color_id        = tl.color_id
        ordered_txt_line.color_code      = tl.color_code
        ordered_txt_line.cmyk_color      = tl.cmyk_color
        ordered_txt_line.italic          = tl.italic
        ordered_txt_line.bold            = tl.bold
        ordered_txt_line.underlined      = tl.underlined
        ordered_txt_line.align           = tl.align
        ordered_txt_line.size            = tl.size
        ordered_txt_line.font            = tl.font
        ordered_txt_line.x               = tl.x
        ordered_txt_line.y               = tl.y
        ordered_txt_line.width           = tl.width
        ordered_txt_line.height          = tl.height
        ordered_txt_line.content         = tl.content

        ordered_zone.ordered_txt_lines << ordered_txt_line
      end
      #EO Create ordered txt lines
    end

    ordered_product.copy_images product.id, ordered_product.checksum, ordered_product.created_on, color_id

    return ordered_product
  end

  def self.create_from_xml(product_xml, doc, currency_rate=1)
    ordered_product = OrderedProduct.new
    logger.debug "[+] Ordered Product created"
    
    begin
      if (!doc.elements["data/"].attributes["inputParam"].nil?)
        ordered_product.affiliate_user_id  = Integer(doc.elements["data/"].attributes["inputParam"]) 
      end
    rescue
      ordered_product.affiliate_user_id = 1
    end

    model                                = Model.find(doc.elements['//data/products/product'].attributes['model'])
    unit_price                           = doc.elements["data/purchases"].attributes["unitPrice"].to_d
    ordered_product.created_on           = Date.today
    ordered_product.store_id             = doc.attributes["shop"]
    ordered_product.color_id             = doc.elements['//data/products/product'].attributes['color'].to_i
    ordered_product.model_id             = doc.elements['//data/products/product'].attributes['model'].to_i
    ordered_product.cost_price           = model.cost_price
    ordered_product.print_cost_white     = Price.find(:first, :conditions=>["name = 'Zone White'"]).price
    ordered_product.print_cost_white_xxl = Price.find(:first, :conditions=>["name = 'Zone White XXL'"]).price
    ordered_product.print_cost_other     = Price.find(:first, :conditions=>["name = 'Zone Other'"]).price
    ordered_product.print_cost_other_xxl = Price.find(:first, :conditions=>["name = 'Zone Other XXL'"]).price
    ordered_product.model_size_id        = product_xml.attributes["size"].to_i
    ordered_product.quantity             = product_xml.attributes['quantity'].to_i
    ordered_product.model_background_color     = doc.elements['//data/products/product'].attributes['modelBackgroundColor']
    
    ordered_product.price                = unit_price 

    if ordered_product.apply_size_prices?
      ordered_product.price += ordered_product.model_size.extra_cost 
    end

    ordered_product.checksum     = Digest::MD5.hexdigest(Time.now.to_s + product_xml.to_s)

    #Create Ordered zones
    doc.each_element("//data/products/product/zones/zone") do |doc|
      if  doc.elements[1]
        ordered_zone = OrderedZone.new
        ordered_zone.ordered_product_id = ordered_product.id
        ordered_zone.zone_type          = doc.attributes["type"]
        logger.debug "[+] Ordered Zone of type #{doc.attributes["type"]} created"

        #Create ordered zone artworks
        doc.each_element("artworks/artwork") do |artwork|
          ordered_zone_artwork = OrderedZoneArtwork.new
          logger.debug "[+] Adding ordered zone artwork #{artwork.attributes["id"]}"

          if  (artwork.attributes['userUpLoadImage'] == 'true' || 
               artwork.attributes["id"].match('_'))
            ordered_zone_artwork.uploaded_image_id   = artwork.attributes["id"]
          else
            ordered_zone_artwork.image_id            = artwork.attributes["id"]
          end

          ordered_zone_artwork.ordered_zone_id       = ordered_zone.id
          ordered_zone_artwork.artwork_printtype     = artwork.attributes["printtype"]
          ordered_zone_artwork.artwork_hreflection   = artwork.attributes["hreflection"]
          ordered_zone_artwork.artwork_vreflection   = artwork.attributes["vreflection"]
          ordered_zone_artwork.artwork_rotation      = artwork.attributes["rotation"]
          ordered_zone_artwork.artwork_y             = artwork.attributes["y"]
          ordered_zone_artwork.artwork_x             = artwork.attributes["x"]
          ordered_zone_artwork.artwork_z             = artwork.attributes["z"]
          ordered_zone_artwork.artwork_zoom          = artwork.attributes["zoom"]
          ordered_zone_artwork.artwork_initial_width = artwork.attributes["initialWidth"]
          ordered_zone_artwork.artwork_initial_height= artwork.attributes["initialHeight"]

          ordered_zone.ordered_zone_artworks << ordered_zone_artwork
        end
        #EO Create ordered zone artworks

        #Set lines attributes
        if  doc.elements["lines"]
          logger.debug "[+] Setting ordered zone line properties"
          ordered_zone.line_printtype      = doc.elements["lines"].attributes["printtype"]
          ordered_zone.line_hreflection    = doc.elements["lines"].attributes["hreflection"]
          ordered_zone.line_vreflection    = doc.elements["lines"].attributes["vreflection"]
          ordered_zone.line_rotation       = doc.elements["lines"].attributes["rotation"]
          ordered_zone.line_y              = doc.elements["lines"].attributes["y"]
          ordered_zone.line_x              = doc.elements["lines"].attributes["x"]
          ordered_zone.line_z              = doc.elements["lines"].attributes["z"]
          ordered_zone.line_width          = doc.elements["lines"].attributes["boxWidth"]
          ordered_zone.line_height         = doc.elements["lines"].attributes["boxHeight"]
        end
        #EO Set lines attributes

        ordered_product.ordered_zones << ordered_zone

        #Create ordered txt lines
        i=1
        doc.each_element("lines/line") do |line|
          logger.debug "[+] Adding ordered txt lines #{line.text}"
          ordered_txt_line = OrderedTxtLine.new
          ordered_txt_line.ordered_zone_id = ordered_zone.id
          ordered_txt_line.line_position   = i
          ordered_txt_line.color_id        = line.attributes["color"]
          ordered_txt_line.italic          = line.attributes["italic"]
          ordered_txt_line.bold            = line.attributes["bold"]
          ordered_txt_line.underlined      = line.attributes["underlined"]
          ordered_txt_line.align           = line.attributes["align"]
          ordered_txt_line.size            = line.attributes["size"]
          ordered_txt_line.font            = line.attributes["font"]
          ordered_txt_line.x               = line.attributes["x"]
          ordered_txt_line.y               = line.attributes["y"]
          ordered_txt_line.width           = line.attributes["width"]
          ordered_txt_line.height          = line.attributes["height"]
          ordered_txt_line.content         = line.text
          if line.attributes["cmykColor"]
            ordered_txt_line.color_code    = line.attributes["color"]
            ordered_txt_line.cmyk_color    = line.attributes["cmykColor"]
          end

          ordered_zone.ordered_txt_lines << ordered_txt_line
          i+=1
        end
        #EO Create ordered txt lines

      end
    end
    #EO Create ordered zones
    
    #Create ordered product preview images 
    ordered_product.generate_preview_using_xml(doc)

    return ordered_product
  end 


  def copy_images product_id, checksum, created_on, color_id=nil
    #copy product images into checksum folder
    product = Product.find(product_id)

    path_created_on = OrderedProduct.path_ordered_product(created_on)

    FileUtils.mkdir_p(File.join("public/izishirtfiles/#{path_created_on}", checksum))

    if RAILS_ENV=='development'
      FileUtils.cp( product.get_pretty_color_obj().get_zone("front").image.path("60") , File.join("public/izishirtfiles/#{path_created_on}", checksum, 'preview.jpg'))
    else
      FileUtils.ln( product.get_pretty_color_obj().get_zone("front").image.path("60") , File.join("public/izishirtfiles/#{path_created_on}", checksum, 'preview.jpg'),  {:force => true})
    end


    #if color_id is in params(colors in marketplace)
    if color_id.nil?
      prod_color_obj = product.get_pretty_color_obj()
    else
      prod_color_obj = ProductColor.find_by_color_id_and_product_id(color_id, product_id) 
    end

    if RAILS_ENV=='development'

    prod_color_obj.product_color_zones.each do |color_zone|
          splitted = color_zone.image.path.split("/")
    supplier_path = splitted[0, splitted.length-1].join("/")+"/supplier.jpg"
      if color_zone.image_physically_exists()
        FileUtils.cp(color_zone.image.path(), File.join("public/izishirtfiles/#{path_created_on}", checksum, checksum + "-" + color_zone.zone_definition.str_id + ".jpg"))
      end

      Rails.logger.error("PATH JPEG SUPPLIER ! =  " + supplier_path)
      if model.model_category == 'custom_case' && File.exists?(supplier_path)
        FileUtils.cp(supplier_path, File.join("public/izishirtfiles/#{path_created_on}", checksum, checksum + "-" + color_zone.zone_definition.str_id + "_supplier.jpg"))
      end
    end
    else
    prod_color_obj.product_color_zones.each do |color_zone|
      if color_zone.image_physically_exists()
        FileUtils.ln(color_zone.image.path(), File.join("public/izishirtfiles/#{path_created_on}", checksum, checksum + "-" + color_zone.zone_definition.str_id + ".jpg"),  {:force => true})
      end
      splitted = color_zone.image.path.split("/")
      supplier_path = splitted[0, splitted.length-1].join("/")+"/supplier.jpg"
      Rails.logger.error("PATH JPEG SUPPLIER ! =  " + supplier_path)
      if model.model_category == 'custom_case' && File.exists?(supplier_path)
        FileUtils.ln(supplier_path, File.join("public/izishirtfiles/#{path_created_on}", checksum, checksum + "-" + color_zone.zone_definition.str_id + "_supplier.jpg"),  {:force => true})
      end
    end
    end





  end
    
end
