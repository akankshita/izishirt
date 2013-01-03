class OutOfStock < ActiveRecord::Base
  belongs_to :model
  belongs_to :color
  belongs_to :size #To remove after model_sizes are live and functional
  belongs_to :model_size
end
