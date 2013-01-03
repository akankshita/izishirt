class ModelPreview < ActiveRecord::Base
	belongs_to :model

	has_attached_file :image, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :styles => {
      "50" => ['50x50', :jpg],
      "300" => ['300x300', :jpg],
      "500" => ['500x500', :jpg],
    },
    :convert_options => {
      :all => "-strip -colorspace RGB",
      "50" => '-background white -flatten -quality 100',
      "300" => '-background white -flatten -quality 100',
      "500" => '-background white -flatten -quality 100',
    }

	def year_created_on
		return model.created_at.year
	end

	def month_created_on
		return model.created_at.month
	end

	def day_created_on
		return model.created_at.day
	end

	def validate
		dimensions = Paperclip::Geometry.from_file(self.image.queued_for_write[:original])

		if dimensions.width < 300 && dimensions.height < 300
			self.errors.add(:image, "Invalid image dimension")
		end
	end
end
