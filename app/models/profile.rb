class Profile < ActiveRecord::Base
  belongs_to :user
  before_update :validate_picture
  after_update :validate_picture, :save_pic

  DIRECTORY_PROFILE = 'public/izishirtfiles/user_profile'

  def uploaded_picture=(pic)
    if pic.to_s != ''
      @picture_file = pic
	  write_attribute 'picture_ext', pic.original_filename.split('.').last.downcase
      write_attribute 'picture', new_pic_name
    end
  end

  def new_pic_name
    "#{user.id}_profile.#{extension}"
  end

	def avatar
		return "/izishirtfiles/user_profile/#{picture}"
	end

  def full_pic_name
    if extension.to_s != ''
      File.join(DIRECTORY_PROFILE, "#{user.id}_profile.#{extension}")
    end
  end

  def extension
    if @picture_file.to_s != ''
      @picture_file.original_filename.split('.').last.downcase
    end
  end

  def del_pic()
    if (picture != 'avatar.png')
      File.unlink(DIRECTORY_PROFILE+'/' + picture) rescue nil
      self.picture = nil
    end
  end

  #######
  private
  #######

  def save_pic
    if full_pic_name.to_s != ''
      File.open(full_pic_name,'wb') {|file| file.write(@picture_file.read) }
    end
  end
  
  def validate_picture
	  return true if (!@picture_file)
	  if (picture_ext == "jpg" || picture_ext == "png" || picture_ext == "gif" || picture_ext == "jpeg") 
		if (@picture_file.size <1000000)
			return true
		else
			errors.add_to_base('Image must be less than 100K')
		end
	  else
		errors.add_to_base('Image must be either jpg, gif or png')
	  end
	  
	  return false 
	end

end
