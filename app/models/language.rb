class Language < ActiveRecord::Base
  has_many :localized_contents
  has_many :localized_colors
  has_many :localized_models
  has_many :localized_categories
  has_many :users
  has_many :countries
  has_many :localized_images, :dependent => :destroy

	has_many :localized_city_pages
  
  validates_length_of :name, :within => 3..20

  def self.print_force_lang(lang)
    if lang == "en" || ! lang || lang == ""
      return "/"
    end

    return "/#{lang}/"
  end
end
