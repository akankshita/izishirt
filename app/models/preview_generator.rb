# Supports many images and many texts

require 'RMagick'

class PreviewGenerator 
  def initialize (model_id, color_id, id_zone, preview_size = "340x340")
    
    @model = Magick::ImageList.new(File.join(DIRECTORY_MODEL, model_id, color_id+"-"+ZONES_POSITION[id_zone].to_s+".jpg")){ self.background_color = 'transparent' }
    @preview_size = preview_size
    @id_zone = id_zone
    
    # The order of the design is important.
    @designs = []
    
    @txts_from_xml = []
    @txts_from_zone = []
  end
  
  # Takes a PreviewGeneratorDesign object
  def add_design(design)
    @designs << design
  end
  
  def add_txt_from_xml(lines)
    @txts_from_xml << lines
  end
  
  def add_txt_from_zone(lines)
    @txts_from_zone << lines
  end
  
  def write(folder_name, id_folder)
    # generate everything here
    @designs.each do |design|
      draw_design(design)
    end
    
    @txts_from_xml.each do |lines|
      draw_txt_from_xml(lines)
    end
    
    @txts_from_zone.each do |lines|
      draw_txt_from_zone(lines)
    end
    
    # then write the preview
    dir_created = File.join("public/izishirtfiles/", folder_name.to_s, id_folder.to_s)
    
    FileUtils.mkdir_p(dir_created)
    
    @model.change_geometry!(@preview_size) { |cols, rows, img|
      img.resize!(cols, rows)
    }
    
    # Write the main preview:
    @model.write("public/izishirtfiles/"+folder_name.to_s+"/"+id_folder.to_s+"/"+id_folder.to_s+"-"+ZONES_POSITION[@id_zone].to_s+".jpg")
    
    # and some smaller:    
    write_smaller_preview("100x100", folder_name.to_s+"/"+id_folder.to_s, @id_zone)  
    write_smaller_preview("60x60", folder_name.to_s+"/"+id_folder.to_s) if @id_zone == 1
  end
  
  private
  
  
  def write_smaller_preview(new_size, folder2, zone_name = "")
    @model.change_geometry!(new_size) { |cols, rows, img|
      img.resize!(cols, rows)
    }
    @model.write("public/izishirtfiles/"+folder2.to_s+"/preview"+zone_name.to_s+".jpg")
  end
  
  # Generates the text image from the xml passed from flash app
  def draw_txt_from_xml(lines)
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
      if !lines[i].nil? && !lines[i].text.nil?
        txt =  lines[i].text      
        
        #Calculate the x position of the current text line
        if lines[i].attributes['align'] == "center"
          current_x = box_width/2 - lines[i].attributes['width'].to_i/2 
        elsif lines[i].attributes['align'] == "right"
          current_x = box_width - lines[i].attributes['width'].to_i
        else
          current_x = 0
        end

        #Get text color or default to black
        begin
          text_color = Color.find(lines[i].attributes['color'].to_i).color_code
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
        end

        #Increment Y value for the next line
        current_y += lines[i].attributes['height'].to_i
      end
    end 
    
    background.rotate!(lines.attributes['rotation'].to_i){ self.background_color = 'transparent' }
    @product2 = Magick::Draw.new()    
    @product2.composite(lines.attributes["x"].to_i, lines.attributes["y"].to_i, 0, 0, background, Magick::OverCompositeOp)
    @product2.draw(@model)      
  end

  # TODO: CHANGE !

  #Function used to re-generate preview images given that the order has already been created
  def draw_txt_from_zone(lines)
    ordered_zone = lines.first.ordered_zone
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
          text_color = Color.find(lines[i].color_id).color_code
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
        gc.annotate(background, lines[i].width, lines[i].height, current_x, current_y, txt) do |gc|
          gc.font = File.join("public/flash/datastorage/fonts/", font)
          gc.pointsize = lines[i].size.to_i
          gc.gravity = Magick::NorthWestGravity#Makes 0,0 coordinate in the top left corner
          gc.fill = '#' + text_color.to_s
          gc.stroke = 'transparent'
        end 

        #Increment Y value for the next line
        current_y += lines[i].height
      end
    end 
    
    # Rotate the background
    background.rotate!(ordered_zone.line_rotation.to_i){ self.background_color = 'transparent' }

    # Add background including text to the model
    @product2 = Magick::Draw.new()    
    @product2.composite(ordered_zone.line_x, ordered_zone.line_y, 0, 0 ,background, Magick::OverCompositeOp)
    @product2.draw(@model)      
  end
  
  def draw_design(design)
    # read
    image = Magick::ImageList.new(design.design_path)
    image.background_color = 'none'
    
    # change
    image.flop! if design.v_reflection == "true"
    image.flip! if design.h_reflection == "true"
    image.resize!(design.zoom / 100)     
    image.rotate!(design.rotation){ self.background_color = 'none' } 
    
    # finalize
    image_design = Magick::Draw.new()
    image_design.composite(design.x, design.y, 0, 0, image, Magick::OverCompositeOp)
    image_design.draw(@model){ self.background_color = 'none' }  
  end
end