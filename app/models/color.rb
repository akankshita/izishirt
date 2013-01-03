class Color < ActiveRecord::Base
  belongs_to :color_type
  belongs_to :technology
  has_many :color_pricings
  has_many :model_specifications
  has_many :models, :through =>  :model_specification
  has_many :localized_colors
  has_many :txt_lines
  has_many :ordered_products
  has_many :products
  has_many :out_of_stocks, :dependent => :destroy
  has_many :order_garment_listing_products
  has_many :quote_products
  has_many :product_colors, :dependent => :destroy
	has_many :garment_stocks
  
  validates_presence_of :color_code
  validates_presence_of :preview_image
  # validates_format_of :image_preview, 
  #                     :with    => %r{^http:.+\.(gif|jpg|png)$}i,
  #                     :message => "doit �tre un URL sur une image GIF, JPG, ou PNG"
  
  #DIRECTORY = 'public/izishirtfiles/colors'

	def get_quote_product_color()
		begin
			if local_name(2).downcase == "white"
				return QuoteProductColor.find_by_str_id("white")
			elsif local_name(2).downcase == "black"
				return QuoteProductColor.find_by_str_id("black")
			else
				return QuoteProductColor.find_by_str_id("other")
			end
		rescue
		end

		return QuoteProductColor.find_by_str_id("black")
	end
  
  after_save :process
  after_update :process
  
  attr_reader :uploaded_image

	def self.black
		return Color.find_by_color_code("000000")
	end
  
  def uploaded_image=(uploaded_image)
    if uploaded_image.to_s != "" 
      @uploaded_image = uploaded_image	
      write_attribute 'extension', uploaded_image.original_filename.split('.').last.downcase
    end
  end

	def gen_preview_with_file(file)
		# `convert "#{file}" -crop 16x16 /tmp/preview_output.gif`
		begin

			out = File.new(file)

			self.uploaded_image = out
			save
			puts "generated color #{id} #{file}"
		rescue Exception => e
			puts "ER;LAKSDJF;LKJASDF;LKJASDF IMAGE #{e}"
		end
	end

	def auto_generate_preview
		begin
			# let's find a preview
			begin
				model_spec = ModelSpecification.find(:first, :conditions => ["color_id = #{id}"])
			rescue
				model_spec = nil;
			end
		
			if ! model_spec
				return
			end

			path_preview = File.join(DIRECTORY_MODEL, model_spec.model.id.to_s, model_spec.img_front)

			`convert "#{path_preview}" -crop 16x16+94+150 /tmp/preview_output.jpg`

			out = File.new("/tmp/preview_output.jpg")

			self.uploaded_image = out
			save
			puts "generated color #{id}"
		rescue Exception => e
			puts "c = #{id} E = #{e}"
		end
	end

	def self.gen_broken_previews
		colors = Color.find_all_by_preview_image("Missing")

		colors.each do |c|
			c.auto_generate_preview
		end
	end
  
  def url
    path.sub(/^public/,'')
  end

  def pretty_url
    pretty_path.sub(/^public/,'')
  end
  
  def path
    File.join(DIRECTORY_COLOR, "#{id}.#{extension}")
  end

  def pretty_path
    File.join(DIRECTORY_COLOR, preview_image)
  end

  def local_name(lang_id)
    begin
      return localized_colors.find_by_language_id(lang_id).name
    rescue
      return ""
    end
  end
  
  def localized_name(language_id)
    localized_colors[language_id-1].name
  end
  
  private
  
  def process
    if @uploaded_image
      create_directory
      save_fullsize
      @uploaded_image = nil
      update_attribute("preview_image", "#{id}.#{extension}")
    end
  end
  
  def save_fullsize
    File.open(path,'wb') do |file|
      file.puts @uploaded_image.read
    end
  end
  
  def create_directory
    FileUtils.mkdir_p DIRECTORY_COLOR
  end
  
  def self.lookup name
    p "name like '%#{name}%'"
    localized_colors = LocalizedColor.find(:all, :conditions => "name like '#{name}'")
    localized_colors.each  do |lc|
      return lc.color if lc.color
    end
    nil
    
  end
  
  
  
  
  
end
