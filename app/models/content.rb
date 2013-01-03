class Content < ActiveRecord::Base
  has_many :localized_contents, :dependent => :destroy
  belongs_to :user
  belongs_to :user_level
  
  validates_presence_of :name
end