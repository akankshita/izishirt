class ZoneArtwork < ActiveRecord::Base
  belongs_to :image
  belongs_to :zone
end
