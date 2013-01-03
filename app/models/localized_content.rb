class LocalizedContent < ActiveRecord::Base
  belongs_to :language
  belongs_to :content
  
  validates_presence_of :title
	#validates_uniqueness_of :url,:allow_nil => true
end
