class LocalizedColor < ActiveRecord::Base
  belongs_to :color
  belongs_to :language
  validates_presence_of :name
end
