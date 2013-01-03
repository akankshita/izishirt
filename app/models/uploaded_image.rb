class UploadedImage < ActiveRecord::Base

  #validates_presence_of :img_design, :if => Proc.new {|img| img.new_record?}

  has_many :tags
  has_many :ordered_zone_artworks
  belongs_to :ordered_product
    
  require 'RMagick'

  has_attached_file :orig_image,
    :path => ":rails_root/public/izishirtfiles/images/useruploadedimage/:year_created_on/:month_created_on/:day_created_on/:timestamp/:timestamp_:style.:extension",
    :url => "/izishirtfiles/images/useruploadedimage/:year_created_on/:month_created_on/:day_created_on/:timestamp/:timestamp_:style.:extension",
    :styles => {
      "340" => ['340x340>',:jpg],
      "png" => ['100x100', :png],
      "png200" => ['200x200', :png],
      "png340" => ['340x340', :png],
      "popup" => ['200x200', :jpg],
      "jpg" => ['100x100', :jpg],
      "thumb" => ['60x60', :jpg]
    },
    :convert_options => {
      :all => "-strip",
      "340" => '-background white -flatten -quality 100',
      "popup" => '-background white -flatten -quality 100',
      "jpg" => '-background white -flatten -quality 100',
      "thumb" => '-background white -flatten -quality 100',
    }

  

  validates_attachment_content_type :orig_image,
    :content_type => ["image/jpg", "image/png", "image/gif", "image/png", "image/jpeg", "image/bmp", "image/gif", "application/octet-stream"]

  def self.supported_extensions()
    extensions = ['jpg', 'png', 'bmp', 'gif', 'jpeg']

    return extensions
  end

  def year_created_on
    return created_on.year
  end

  def month_created_on
    return created_on.month
  end

  def day_created_on
    return created_on.day
  end
  
  def relative_path
    year = created_on.year
    month = created_on.month
    day = created_on.day
    
    return "/izishirtfiles/images/useruploadedimage/#{year}/#{month}/#{day}/#{timestamp}/"
  end
  
  def self.uploaded_image_by_timestamp(timestamp)
    return UploadedImage.find_by_timestamp(timestamp)
  end

#######
  private
########
  
end
