class Price < ActiveRecord::Base
     belongs_to :price_type
	 belongs_to :technology
	 
end
