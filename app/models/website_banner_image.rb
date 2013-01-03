class WebsiteBannerImage < ActiveRecord::Base
	belongs_to :website_banner
	belongs_to :locale
	belongs_to :city
	
	has_attached_file :image, :whiny => false,
		:path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
		:url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id_:style.:extension",
		:styles => {
		},
		:convert_options => {
			:all => "-strip -colorspace RGB",
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
end
