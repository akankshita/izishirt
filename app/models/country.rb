class Country < ActiveRecord::Base
  belongs_to :region
  belongs_to :language
  validates_presence_of :name, :shortname
  validates_uniqueness_of :name, :shortname
  has_many :provinces
  has_many :address
  has_many :images
  has_many :localized_images, :dependent => :destroy
  has_many :localized_countries, :dependent => :destroy



  def add_tax(price)
    price + price * tax
  end

	def self.configurations
		return {
			"CA" => [1, 2],
      "ES" => [3],
      "DE" => [4],
      "BR" => [5],
      "PT" => [5],
      "AT" => [4],
      "MX" => [3],
			"US" => [2],
			"FR" => [1],
			"GB" => [2],
			"AU" => [2],
			"CH" => [1],
			"EU" => [1, 2],
      "BE" => [1]
			}
	end
  
  def local_tax_abreviation(lang)
    begin
      localized_countries.find_by_language_id(lang).tax_abreviation
    rescue
      ""
    end
  end
  
  #returns true if country is in the european union
  def is_europe
    ["Austria",                                                                                                       
    "Belgium",                                                                                                        
    "Bulgaria",                                                                                                       
    "Cyprus",                                                                                                         
    "Czech Republic",                                                                                                 
    "Denmark",                                                                                                        
    "Estonia",                                                                                                        
    "Finland",                                                                                                        
    "France",                                                                                                         
    "Germany",                                                                                                        
    "Greece",                                                                                                         
    "Hungary",                                                                                                        
    "Ireland",                                                                                                        
    "Italy",                                                                                                          
    "Latvia",                                                                                                         
    "Lithuania",                                                                                                      
    "Luxembourg",                                                                                                     
    "Malta",                                                                                                          
    "Netherlands",                                                                                                    
    "Poland",                                                                                                         
    "Portugal",                                                                                                       
    "Romania",                                                                                                        
    "Slovakia",                                                                                                       
    "Slovenia",                                                                                                       
    "Spain",                                                                                                          
    "Sweden",                                                                                                         
	"Guadeloupe",
	"Martinique",
	"Guyana",
	"Reunion",
    "United Kingdom"].include?(name)
  end

	def self.country_can_access_to(from_country, to_country)
		Currency.all.each do |currency|
			i = currency_available_to(currency.label)

			if i.include?(from_country) && i.include?(to_country)
				return true
			end
		end

		return false
	end

	def self.countries_from_country(from_country)
		Currency.all.each do |currency|
			i = currency_available_to(currency.label)

			if i.include?(from_country)
				return i
			end
		end

		return []
	end

	def self.currency_of(country)
		Currency.all.each do |currency|
			i = currency_available_to(currency.label)

			if i.include?(country)
				return currency
			end
		end

		return Currency.find_by_label("CAD")
	end

	def self.currency_available_to(label)
		return {
			"AUD" => ["AU"],
			"CAD" => ["CA"],
			"EUR" => ["PT", "FR", "EU", "BE", "ES", "DE", "AT"],
      "MXN" => ["MX"],
      "GBP" => ["GB"],
      "BRL" => ["BR"],
			"USD" => ["US"],
      "CHF" => ["CH"]
		}[label]
	end

	def self.only_langs_of(country)
		return {
			"CA" => [nil, "fr"],
			"GB" => ["uk"],
			"FR" => ["france"],
      "ES" => ["es"],
      "MX" => ["mx"],
      "BR" => ["br"],
      "DE" => ["de"],
      "PT" => ["pt"],
      "AT" => ["at"],
			"EU" => ["fr-eu", "eu"],
			"AU" => ["australia"],
			"US" => ["us", "es-us"],
      "CH" => ["ch"],
      "BE" => ["be"]
		}[country]
	end

	def self.can_access_to_langs(country, logged_in_user)
		if logged_in_user
			cs = countries_from_country(country)
		else
			cs = []
			Currency.all.each do |currency|
				i = currency_available_to(currency.label)

				if i && cs
					cs = cs | i
				end
			end
		end

		l = []

		cs.each do |c|
			l = l | only_langs_of(c)
		end

		return l
	end
	
	def self.can_access_to_lang?(country, lang)
		ls = can_access_to_langs(country)

		return ls.include?(lang)
	end

	def self.layout_infos(country)
		return {"fr" => {:order => 1, :country => "CA", :alt_name => "Canada", :label_name => "Canada Français", :flag_file => "ca.png"},
				"frch" => {:order => (country == "FR" ? -4 : 4), :country => "FR", :alt_name => "France", :label_name => "France", :flag_file => "fr.png"},
				nil => {:order => 2, :country => "CA", :alt_name => "Canada", :label_name => "Canada English", :flag_file => "ca.png"},
				"us" => {:order => (country == "US" ? -3 : 3), :country => "US", :alt_name => "USA English", :label_name => "USA English", :flag_file => "us.png"}
			}
	end

end
