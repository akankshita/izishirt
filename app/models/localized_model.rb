class LocalizedModel < ActiveRecord::Base
  belongs_to :model
  belongs_to :language
  
  validates_presence_of :name

  after_save :save_uploaded_pictures
  attr_reader :model_info_upload

  def model_info_upload=(pic)
    if !pic.to_s.empty?
      @uploaded_model_info = pic
      write_attribute 'model_info', "#{URL_ROOT}/izishirtfiles/localized_models/#{id}/model_info.#{pic.original_filename.split('.').last.downcase}"
    end
  end
  
  def save_uploaded_pictures
    if (@uploaded_model_info)
      file_name = 'model_info.'+@uploaded_model_info.original_filename.split('.').last.downcase
      FileUtils.mkdir_p(File.join(DIRECTORY_LOCALIZED_MODEL, id.to_s))
      File.open(File.join(DIRECTORY_LOCALIZED_MODEL, id.to_s, file_name),'wb') do |file|
        file.puts @uploaded_model_info.read
      end
    end	
  end
end
