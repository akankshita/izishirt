class Zone < ActiveRecord::Base
	belongs_to :product
	belongs_to :image
	has_many :zone_artworks
	has_many :txt_lines, :dependent => :destroy

  def contains_txt?
    return txt_lines.length > 0
  end
    
  def to_s
    description = ""
    #description += image.name+" " if !image.nil?
    txt_lines.each {|txt|
      description += txt.content.to_s+" "
    }
          
    return description.strip
    
  end

  def contains_artwork
    return zone_artworks.length > 0
  end


  def has_two_designs?
    return true if zone_artworks && zone_artworks.length > 1
    return false
  end


  def has_designs?
    return true if zone_artworks && zone_artworks.length > 0
    return false
  end

  def first_preview_image
    begin
      return zone_artworks[0].image.orig_image.url("popup", true)
    rescue
      return ''
    end
  end

  def first_image
    begin
      return zone_artworks[0].image
    rescue
      return nil
    end
  end

  def first_image_jpg_background
    begin
      return zone_artworks[0].image.jpb_background_color
    rescue
      return '#FFFFFF'
    end
  end

  def second_preview_image
    begin
      return zone_artworks[1].image.orig_image.url("popup", true)
    rescue
      return ''
    end
  end

  
  def create_zone_artwork(artwork)
    art = ZoneArtwork.create(:zone_id => id)
    art.image_id            = artwork.attributes["id"]
    art.artwork_printtype   = artwork.attributes["printtype"]
    art.artwork_hreflection = artwork.attributes["hreflection"]
    art.artwork_vreflection = artwork.attributes["vreflection"]
    art.artwork_rotation    = artwork.attributes["rotation"]
    art.artwork_y           = artwork.attributes["y"]
    art.artwork_x           = artwork.attributes["x"]
    art.artwork_z           = artwork.attributes["z"]
    art.artwork_zoom        = artwork.attributes["zoom"]
    art.artwork_initial_width = artwork.attributes["initialWidth"]
    art.artwork_initial_height= artwork.attributes["initialHeight"]
    art.save    
  end
  
  def create_txt_lines(lines)
    self.line_printtype  	= lines.attributes["printtype"]
    self.line_hreflection = lines.attributes["hreflection"]
    self.line_vreflection = lines.attributes["vreflection"]
    self.line_rotation  	= lines.attributes["rotation"]
    self.line_y  					= lines.attributes["y"]
    self.line_x  					= lines.attributes["x"]
    self.line_z           = lines.attributes["z"]	
    self.line_width 			= lines.attributes["boxWidth"]
    self.line_height			= lines.attributes["boxHeight"]
    self.save
    
    lines.each_element("line") do |line|
      i=1
			@line = TxtLine.new
			@line.zone_id 				= self.id 
			@line.line_position 	= i
			@line.color_id 				= line.attributes["color"]
			@line.color_code      = line.attributes["color"] 
			@line.cmyk_color      = line.attributes["cmykColor"]         
			@line.italic 					= line.attributes["italic"]
			@line.bold 					  = line.attributes["bold"]
			@line.underlined      = line.attributes["underlined"]
			@line.align 					= line.attributes["align"]
			@line.size 					  = line.attributes["size"]
			@line.font 					  = line.attributes["font"]
			@line.x    					  = line.attributes["x"]
			@line.y 	    				= line.attributes["y"]
			@line.width 					= line.attributes["width"]
			@line.height 					= line.attributes["height"]
			@line.content 				= line.text
			@line.save	
			i+=1
    end
  end

end
