class Address < ActiveRecord::Base
  belongs_to :user
  belongs_to :province
  belongs_to :country
  has_many :pick_up_stores
  
  def to_s
    if (!country.nil? && !province.nil?)
      address1.to_s + ' ' + address2.to_s + ', ' + town.to_s + ', ' + province.name.to_s + ', ' + country.name.to_s + ", " + zip
    else
      address1.to_s + ' ' + address2.to_s + ', ' + town.to_s + ', ' + province_name.to_s + ', ' + country_name.to_s + ", " + zip
    end
  end



  def get_country
    country ? country.name : country_name 
  end

  def get_province
    province ? province.name : province_name
  end

  def get_province_code
    province ? province.code : province_name
  end


	def to_s_short
		begin
			return "#{get_country}, #{get_province}"
		rescue
		end

		return ""
	end

  def hide_or_show(shipping_type)
    #Don't hide if rush order and province is:
    #xpress-post, express, rush, xmas && Saskatchewan,Alberta,BC,Manitoba,Yukon
    !([1,2,3,4].include?(shipping_type) && [3,4,5,6,11].include?(province_id))
  end
end
