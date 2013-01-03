module Paperclip
  
  class BackgroundColorFilter < Processor  
    attr_accessor :current_geometry, :target_geometry, :format, :whiny, :convert_options, :overlay, :position, :background_color
    
    def initialize file, options = {}, attachment = nil
       super
       geometry          = options[:geometry]
       @file             = file
       @crop             = geometry[-1,1] == '#'
       @target_geometry  = Geometry.parse geometry
       @current_geometry = Geometry.from_file @file
       @convert_options  = options[:convert_options]
       @whiny            = options[:whiny].nil? ? true : options[:whiny]
       @format           = options[:format]
       @overlay          = options[:overlay].nil? ? true : false
       @current_format   = File.extname(@file.path)
       @basename         = File.basename(@file.path, @current_format)
       @background_color        = options[:background_color]
       @attachment = attachment

       @background_color = @attachment.instance.background_color

       @convert_options = @convert_options.gsub(":background_color", "\"#{@background_color}\"")
     end
     
     # Returns true if the +target_geometry+ is meant to crop.
      def crop?
        @crop
      end

      # Returns true if the image is meant to make use of additional convert options.
      def convert_options?
        not @convert_options.blank?
      end

      def make
        image = [@basename, @format].compact.join(".")
        dst = Tempfile.new(image)
        dst.binmode

        commands = []
        
        command = "convert"
        params = "#{fromfile} #{transformation_command} #{tofile(dst)}"
        commands << [command, params]

        begin
          commands.each do |cur_command|
            command = cur_command[0]
            params = cur_command[1]

            success = Paperclip.run(command, params)  
          end
          
        rescue PaperclipCommandLineError => e
          raise PaperclipError, "There was an error processing the background color filter for #{@basename} WITH c = #{command} AND params = #{params}, e = #{e}" if @whiny
        end

        dst
      end

      def fromfile
        "\"#{ File.expand_path(@file.path) }[0]\""
      end

      def tofile(destination)
        "\"#{ File.expand_path(destination.path) }[0]\""
      end    

      def transformation_command(with_conversions = true)
        scale, crop = @current_geometry.transformation_to(@target_geometry, crop?)
        trans = "-resize \"#{scale}\""
        trans << " -crop \"#{crop}\" +repage" if crop
        trans << " #{convert_options}" if convert_options? && with_conversions
        trans
      end


  end

end
