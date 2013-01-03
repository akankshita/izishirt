class OrderedZone < ActiveRecord::Base
	belongs_to :ordered_product
	
	has_many :ordered_txt_lines, :dependent => :destroy
  belongs_to :design_image_decline_reason
  
  has_many :ordered_zone_artworks
	has_many :earnings


  def self.create_with_centered_image(image, ordered_product)
    @new_zone = OrderedZone.new()
    @new_zone.ordered_product = ordered_product
    
    @new_zone.zone_type = 1

    if image
      artwork = OrderedZoneArtwork.new()

      artwork.image = image
      artwork.artwork_zoom = 100

      @new_zone.ordered_zone_artworks << artwork
    end
     
    @new_zone.generate_image

    return @new_zone
  end

  def contains_artwork_or_text()
    return (ordered_zone_artworks.length > 0) || ordered_txt_lines.length > 0
  end    
  
  def nb_artworks()
    return ordered_zone_artworks.length
  end  
  
  def contains_uploaded_image()
    ordered_zone_artworks.each do |artwork|
      Rails.logger.error("zone id = #{id}, uploaded image id = #{artwork.uploaded_image_id}")
      if artwork.uploaded_image
        Rails.logger.error("    OK...")
        return true
      end
      Rails.logger.error("    NA....")
    end    
    
    return false
  end  
  
  def contains_image()
    ordered_zone_artworks.each do |artwork|
      if artwork.image
        return true
      end
    end    
    
    return false
  end

  def contains_artwork
    return ordered_zone_artworks.length > 0
  end

  def self.create_empty_back(ordered_product)
    @new_zone = OrderedZone.new()
    @new_zone.ordered_product = ordered_product
    @new_zone.zone_type = 2


    #artwork.artwork_zoom = 100

    #@new_zone.ordered_zone_artworks << artwork

    @new_zone.generate_image

    return @new_zone

  end

  #Does not work with text
  def generate_image

    path_ordered_products = OrderedProduct.path_ordered_product(ordered_product.created_on)

    if contains_image
      model = Model.find(ordered_product.model_id)
      img = GenerateImage.new(ordered_product.model_id.to_s, ordered_product.color_id.to_s, zone_type.to_i)

      ordered_zone_artworks.each do |artwork|
        if artwork.image
          design_path = artwork.image.orig_image.path("png")#File.join(DIRECTORY_IMAGE, image_id.to_s, image_id.to_s+".png")
          img.read_artwork(design_path)
          design_dimensions = img.get_design_dimensions
          model_dimensions = img.get_model_dimensions

          artwork.artwork_x = (model_dimensions[:width]/2) - (design_dimensions[:width]/2) + model.design_offset_x
          artwork.artwork_y = 90 + model.design_offset_y
          img.write_artwork(artwork.artwork_x, artwork.artwork_y)
        end
      end
      
      img.finalize("#{path_ordered_products}/", ordered_product.checksum, zone_type)
    else
      img = GenerateImage.new(ordered_product.model_id.to_s, ordered_product.color_id.to_s, zone_type.to_i)
      img.finalize("#{path_ordered_products}/", ordered_product.checksum, zone_type)
    end
  end

  def generate_preview
    path_ordered_products = OrderedProduct.path_ordered_product(ordered_product.created_on)
    img = GenerateImage.new(ordered_product.model_id.to_s, ordered_product.color_id.to_s, zone_type.to_i)

    #ARTWORK GENERATION
    if contains_image || contains_uploaded_image

      ordered_zone_artworks.each do |artwork|
        if artwork.image || artwork.uploaded_image_id
          if artwork.image
            design_path = artwork.image.orig_image.path("png")#File.join(DIRECTORY_IMAGE, image_id.to_s, image_id.to_s+".png")
          elsif artwork.uploaded_image
            design_path = UploadedImage.find_by_timestamp(artwork.uploaded_image_id).orig_image.path("png")
          end

          img.read_artwork(design_path)
          img.change_artwork(artwork.artwork_vreflection, artwork.artwork_hreflection, artwork.artwork_zoom.to_f, artwork.artwork_rotation || 0)
          img.write_artwork(artwork.artwork_x.to_f, artwork.artwork_y.to_f)
        end
      end

      
    end
    

    #TEXT GENERATION
    if ordered_txt_lines != []   
      img.generate_txt_from_zone(ordered_txt_lines, self)
    end

    img.finalize("#{path_ordered_products}/", ordered_product.checksum, zone_type)
  end
end
