class ZoneDefinition < ActiveRecord::Base
  has_many :localized_zone_definitions
  has_many :product_color_zones
end
