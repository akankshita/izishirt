class LocalizedCountry < ActiveRecord::Base
  belongs_to :language
  belongs_to :country
end
