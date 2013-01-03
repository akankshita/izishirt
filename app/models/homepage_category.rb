class HomepageCategory < ActiveRecord::Base
  has_many :homepage_category_images
  has_many :homepage_category_links
  accepts_nested_attributes_for :homepage_category_links, :allow_destroy => true
  accepts_nested_attributes_for :homepage_category_images, :allow_destroy => true

  belongs_to :language
end
