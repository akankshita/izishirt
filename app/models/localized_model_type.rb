class LocalizedModelType < ActiveRecord::Base
  belongs_to :language
  belongs_to :model_type
end
