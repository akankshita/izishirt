class CategoryType < ActiveRecord::Base
  has_many :categories, :order => :position
  has_many :localized_categories, :through => :categories
end
