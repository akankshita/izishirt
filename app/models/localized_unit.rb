class LocalizedUnit < ActiveRecord::Base
  belongs_to :language
  belongs_to :unit
end
