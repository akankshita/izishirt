class LocalizedImage < ActiveRecord::Base
  belongs_to :image
  belongs_to :country
  belongs_to :language

  
end
