class City < ActiveRecord::Base

    belongs_to :province
    has_many :homepage_banners
    has_many :images
	has_many :website_banner_images
    has_many :models
    #has_many :wholesale_models, :class_name=>'Model', :foreign_key=>'brand_id', :include=>:model_specifications
    #has_and_belongs_to_many :stores
  #has_many :product_categories, :dependent => :destroy
    #has_many :products, :through => :product_categories
	#has_many :quote_products
    #has_and_belongs_to_many :stores
    

end
