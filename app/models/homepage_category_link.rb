class HomepageCategoryLink < ActiveRecord::Base
  belongs_to :homepage_category
  belongs_to :image
end
