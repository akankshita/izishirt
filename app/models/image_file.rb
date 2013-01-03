class ImageFile < ActiveRecord::Base
  belongs_to :image

  has_attached_file :file, :url => "/izishirtfiles/image_files/:attachment/:id/:style/:filename", :path => ":rails_root/public/izishirtfiles/image_files/:attachment/:id/:style/:filename"
end
