class ApplicationSetting < ActiveRecord::Base
  def self.use_per_model_discount?
    if ApplicationSetting.exists?(:name => 'use_per_model_discount')
      ApplicationSetting.find_by_name("use_per_model_discount").value == 1  
    else
      false
    end
  end
end
