class LocalizedModelSize < ActiveRecord::Base
  belongs_to :model_size
  belongs_to :locale
end
