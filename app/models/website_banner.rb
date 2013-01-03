class WebsiteBanner < ActiveRecord::Base
	has_many :website_banner_images

	def banner_images(locale)
		# begin
      Rails.logger.error("LOCALEEEEE" + locale)
			Rails.logger.error("locale = #{locale}")
			l = Locale.find_by_locale(locale)
			Rails.logger.error("LOCALE.. #{l.id}")
		
			return website_banner_images.find_all_by_locale_id(l.id, :order => "the_order ASC")
		# rescue
		# end

		return []
	end
end
