class Locale < ActiveRecord::Base
  validates_uniqueness_of :locale
  validates_presence_of :locale, :long_name
  has_many :localized_model_sizes
	has_many :website_banner_images

	def country
		parts = locale.split("-")
		
		return parts[1]
	end

	def language_id
		parts = locale.split("-")
		
		return parts[0] == "fr" ? "1" : "2"
	end

  def europe?
    ["en-EU",
     "fr-EU",
     "fr-FR",
     "fr-BE",
     "pt-PT",
     "en-GB",
     "fr-CH"].include?(locale)
  end
end
