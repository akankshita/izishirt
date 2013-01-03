class OrderedTxtLine < ActiveRecord::Base
	belongs_to :color
	belongs_to :ordered_zone
end
