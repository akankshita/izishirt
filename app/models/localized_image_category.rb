class LocalizedImageCategory < ActiveRecord::Base
  belongs_to :localized_category
  has_many :localized_currency_image_categories, :dependent => :destroy

  has_attached_file :image, :styles => {:thumb => "125x38>" }, :path=>BULK_PICTURES_PATH, :url=>BULK_PICTURES_URL
end
