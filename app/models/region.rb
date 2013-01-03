class Region < ActiveRecord::Base
  has_many :countries
  validates_presence_of :name
  validates_uniqueness_of :name
end
