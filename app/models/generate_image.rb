require 'RMagick'

class GenerateImage 
						
  def initialize (model_id, color_id, position, extra_supplier_path=false)
    #begin
      @product = Magick::Draw.new()

      @model = Magick::ImageList.new(File.join(DIRECTORY_MODEL, model_id.to_s, color_id.to_s+"-"+ZONES_POSITION[position].to_s+".jpg")){ self.background_color = 'transparent' }


    if extra_supplier_path
      @product2 = Magick::Draw.new()
      @model2 = Magick::ImageList.new(extra_supplier_path){ self.background_color = 'transparent' }
    end
    #rescue => e
    #  Rails.logger.error("ERROR during initialize generate image => model id = #{model_id}, color id = #{color_id}, position = #{position}")
    #  Rails.logger.error("Error: #{e}")
    #end
  end
  
  def read_artwork(design_path)

	@design = Magick::ImageList.new(design_path)
	@design.background_color = 'none'
  end

  def add_image_with_background_color(background_color)

#  gc = Magick::Draw.new
#  gc.fill background_color
#  image = Magick::Image.new(path)
#  image.background_color = background_color
#  image.flatten
  #gc.draw(image)

  color = Magick::Image.new(340, 340) do
     self.background_color = background_color
     #self.fill = background_color
  end


	@design = Magick::ImageList.new
  @design << color

  end
  
  def change_artwork(vreflection, hreflection, new_size, rotation, initial_width=100, initial_height=100)
    if initial_width > initial_height
      initial_size = initial_width
    else 
      initial_size = initial_height
    end
    @design.flop! if hreflection == "true"
    @design.flip! if vreflection == "true"
    @design.resize!(new_size / 100 * initial_size.to_i / 100)  		
    @design.rotate!(rotation){ self.background_color = 'none' }	
  end
  
  def write_artwork(x,y, extra_supplier = false)
     @product.composite(x, y, 0, 0, @design, Magick::OverCompositeOp)
     @product.draw(@model){ self.background_color = 'none' }
    if extra_supplier
      @product2.composite(x, y, 0, 0, @design, Magick::OverCompositeOp)
      @product2.draw(@model2){ self.background_color = 'none' }
    end
  end

  def write_artwork_only_supplier(x,y)
      @product2.composite(x, y, 0, 0, @design, Magick::OverCompositeOp)
      @product2.draw(@model2){ self.background_color = 'none' }
  end


  def finalize(folder_name, id_folder, id_zone, extra_supplier_zone=false)
    begin
      Rails.logger.debug "[+] Writing to public/izishirtfiles/#{folder_name}/#{id_folder}/#{id_folder}-#{ZONES_POSITION[id_zone]}.jpg"
      #EO Delete old product                                                                                           |_zone].to_s+".jpg"}"
      dir_created = File.join("public/izishirtfiles/", folder_name.to_s, id_folder.to_s)
      FileUtils.mkdir_p(dir_created)
      @model.write("public/izishirtfiles/"+folder_name.to_s+"/"+id_folder.to_s+"/"+id_folder.to_s+"-"+ZONES_POSITION[id_zone].to_s+".jpg")
      make_preview("100x100", folder_name.to_s+"/"+id_folder.to_s, id_zone)		
      make_preview("60x60", folder_name.to_s+"/"+id_folder.to_s) if id_zone == 1

      if extra_supplier_zone
        path = "#{RAILS_ROOT}/public/izishirtfiles/"+folder_name.to_s+"/"+id_folder.to_s+"/"+id_folder.to_s+"-"+ZONES_POSITION[id_zone].to_s+"_supplier.jpg"
        @model2.write(path)
      end

    rescue
    end
  end

	def self.finalize_with_image(image, folder_name, id_folder, id_zone)
	    begin
	      Rails.logger.debug "[+] Writing to public/izishirtfiles/#{folder_name}/#{id_folder}/#{id_folder}-#{ZONES_POSITION[id_zone]}.jpg"
		  #EO Delete old product                                                                                           |_zone].to_s+".jpg"}"
	      dir_created = File.join("public/izishirtfiles/", folder_name.to_s, id_folder.to_s)
	      FileUtils.mkdir_p(dir_created)
	      image.write("public/izishirtfiles/"+folder_name.to_s+"/"+id_folder.to_s+"/"+id_folder.to_s+"-"+ZONES_POSITION[id_zone].to_s+".jpg")
	      make_preview("100x100", folder_name.to_s+"/"+id_folder.to_s, id_zone)		
	      make_preview("60x60", folder_name.to_s+"/"+id_folder.to_s) if id_zone == 1
	    rescue
	    end
	end

  def finalize_product(product_color_zone_obj, extra_supplier=false)
    tmp_write_to = "#{RAILS_ROOT}/public/izishirtfiles/"+ product_color_zone_obj.product_color.product.relative_product_folder_without_id.to_s+"/"+product_color_zone_obj.product_color.product.id.to_s+"/"+product_color_zone_obj.product_color.product.id.to_s+"-"+ZONES_POSITION[product_color_zone_obj.zone_definition.id].to_s+"_tmp.jpg"




    dir = File.dirname(tmp_write_to)

    FileUtils.mkdir_p(dir)
    
    @model.write(tmp_write_to)
    
    product_color_zone_obj.update_attributes(:image => File.new(tmp_write_to), :image_logically_exists => true)

    # remove the tmp file
    File.delete(tmp_write_to)

    product_color_zone_obj.update_attributes(:image_logically_exists => true, :files_transfered => true)

    if extra_supplier
      path = product_color_zone_obj.product_path+"/"+product_color_zone_obj.product_color.color.id.to_s+"/"+product_color_zone_obj.zone_definition.str_id+"/supplier.jpg"
      Rails.logger.error("path="+path)
      @model2.write(path)
    end

    begin

	dir = product_color_zone_obj.product_path

      system("chown -R www-data:www-data #{dir} &")
      system("chmod -R 777 #{dir} &")
    rescue
    end
  end

  def make_preview(new_size, folder2, zone_name = "")
		@model.change_geometry!(new_size) { |cols, rows, img|
			img.resize!(cols, rows)
		}
		@model.write("public/izishirtfiles/"+folder2.to_s+"/preview"+zone_name.to_s+".jpg")
  end
  
  def get_design_dimensions
    #breakpoint
    dimensions = { :width=>@design[0].page.width, :height=>@design[0].page.height }  
  end
    
  def get_model_dimensions
    #breakpoint
    dimensions = { :width=>@model[0].page.width, :height=>@model[0].page.height }  
  end

  # Generates the text image from the xml passed from flash app
  def generate_txt_from_xml(lines, extra_supplier = false)
    lines_original = lines
    lines=lines.to_a
    #Calculate the width and height of the box containing the text
    box_height, box_width = 0, 0
    lines.each do |line|
      box_width = line.attributes['width'].to_i if line.attributes['width'].to_i > box_width
      box_height += line.attributes['height'].to_i
    end
    puts "box: #{box_width}x#{box_height}"
    
    #Create image of the calculated box size
		background = Magick::Image.new(box_width,box_height){ self.background_color = 'transparent' }

    #Iterate over lines
    current_y = 0

		for i in 0...lines.size		
      if !lines[i].nil? #&& !lines[i].text.nil?
        txt =  lines[i].text == "" || lines[i].text.nil? ? " " : lines[i].text
        
        #Calculate the x position of the current text line
        if lines[i].attributes['align'] == "center"
          current_x = box_width/2 - lines[i].attributes['width'].to_i/2 
        elsif lines[i].attributes['align'] == "right"
          current_x = box_width - lines[i].attributes['width'].to_i
        else
          current_x = 0
        end

        puts "pos: (#{current_x},#{current_y})"

        #Get text color or default to black
        begin
          if !lines[i].attributes['cmykColor'].nil? && lines[i].attributes['cmykColor'] != ""
            text_color = lines[i].attributes['color']
          else
            text_color = Color.find(lines[i].attributes['color'].to_i).color_code
          end
        rescue
          text_color = "000000"			
        end	
        
        #font file name
        font = lines[i].attributes['font'].to_s
        font+= "_bold" if lines[i].attributes['bold'].to_s == "true" 
        font+= "_italic" if lines[i].attributes['italic'].to_s == "true"
        font+= ".ttf"

        #Create a new draw object and add text one line at a time
        gc = Magick::Draw.new
        gc.annotate(background,  lines[i].attributes['width'].to_i ,  lines[i].attributes['height'].to_i , current_x, current_y,  txt) do |gc|
          gc.font = File.join("public/flash/datastorage/fonts/", font)
          gc.pointsize = lines[i].attributes['size'].to_i
          gc.gravity = Magick::NorthWestGravity#Makes 0,0 coordinate in the top left corner
          gc.fill = '#' + text_color.to_s
          gc.stroke = 'transparent'				
          gc.decorate = Magick::UnderlineDecoration if lines[i].attributes['underlined'].to_s == "true"	
        end

        #Increment Y value for the next line
        current_y += lines[i].attributes['height'].to_i
      end
		end	
		
		background.rotate!(lines_original.attributes['rotation'].to_i){ self.background_color = 'transparent' }

    #Weird fix, add 6 to x offset, TOCHECK
		@product.composite(lines_original.attributes["x"].to_i+6, lines_original.attributes["y"].to_i, 0, 0, background, Magick::OverCompositeOp )
		@product.draw(@model){ self.background_color = 'none' }

    if extra_supplier
    @product2.composite(lines_original.attributes["x"].to_i+6, lines_original.attributes["y"].to_i, 0, 0, background, Magick::OverCompositeOp )
		@product2.draw(@model2){ self.background_color = 'none' }
    end

	end

  #Function used to re-generate preview images given that the order has already been created
  def generate_txt_from_zone(lines, ordered_zone)

    rotate = ordered_zone.line_rotation.to_i

    #Calculate the width and height of the box containing the text
    box_height, box_width = 0, 0
    lines.each do |line|
      box_width = line.width if line.width > box_width
      box_height += line.height
    end

    #Create new image with transparent background
		background = Magick::Image.new(box_width, box_height){ self.background_color = 'transparent' }

    #Iterate over lines
    current_y = 0
		for i in 0...lines.size		
      # Do nothing if text is nil
      if !lines[i].nil? && !lines[i].content.nil?

        txt = lines[i].content			

        #Calculate the x position of the current text line
        if lines[i].align == "center"
          current_x = box_width/2 - lines[i].width/2 
        elsif lines[i].align == "right"
          current_x = box_width - lines[i].width
        else
          current_x = 0
        end

        begin
          if lines[i].color_code != nil
            text_color = lines[i].color_code
          else
            text_color = Color.find(lines[i].color_id).color_code
          end
        rescue
          text_color = "000000"			
        end	
        
        #font file name
        font = lines[i].font.to_s
        font+= "_bold" if lines[i].bold.to_s == "true" 
        font+= "_italic" if lines[i].italic.to_s == "true"
        font+= ".ttf"

        #Create new draw object 
        gc = Magick::Draw.new

        #Add text to the background
        begin
          gc.annotate(background, lines[i].width, lines[i].height, current_x, current_y, txt) do |gc|
            gc.font = File.join("public/flash/datastorage/fonts/", font)
            gc.pointsize = lines[i].size.to_i
            gc.gravity = Magick::NorthWestGravity#Makes 0,0 coordinate in the top left corner
            gc.fill = '#' + text_color.to_s
            gc.stroke = 'transparent'
          end
        rescue
        end

        #Increment Y value for the next line
        current_y += lines[i].height
      end
		end	
		
    # Rotate the background
		background.rotate!(ordered_zone.line_rotation.to_i){ self.background_color = 'transparent' }

    # Add background including text to the model
		@product.composite(ordered_zone.line_x, ordered_zone.line_y, 0, 0 ,background, Magick::OverCompositeOp)
		@product.draw(@model)
	end
end
