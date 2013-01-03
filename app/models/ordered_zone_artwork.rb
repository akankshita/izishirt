class OrderedZoneArtwork < ActiveRecord::Base
  belongs_to :image
 # belongs_to :uploaded_image
  belongs_to :ordered_zone

  def uploaded_image
    return ! uploaded_image_id.nil? && UploadedImage.find_by_timestamp(uploaded_image_id)
  end

	def name()
		if uploaded_image
			return "Uploaded image"
		end

		return image.name
	end
end
