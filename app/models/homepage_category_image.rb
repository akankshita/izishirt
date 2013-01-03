class HomepageCategoryImage < ActiveRecord::Base
  belongs_to :homepage_category
  belongs_to :image
  belongs_to :model

	has_attached_file :orig_image, :whiny => false,
    :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
    :styles => {
      "100" => ['100x100>', :jpg],
    },
    :convert_options => {
      :all => "-strip -colorspace RGB",
      "100" => '-background white -flatten -quality 100',
    }

	def year_created_on
		return created_at.year
	end

	def month_created_on
		return created_at.month
	end

	def day_created_on
		return created_at.day
	end

	def name(lang_id)
		begin
			return image ? image.name : model.local_name(lang_id)
		rescue
		end

		return ""
	end

	def url(lang_id)
		begin

			if manual_url && manual_url != ""
				return manual_url
			end

			return image ? image.info_url("", lang_id) : model.store_url("", lang_id)
		rescue
		end

		return ""
	end

	def image_url
		begin
			if image
				return image.orig_image.url("200")
			else
				return orig_image.url("200")
			end
		rescue
		end
	end

end
