#Method for Models
class ActiveRecord::Base
  def add_country_tax(price,shortname)
    begin
      shortname = "fr" if shortname == "EU"
      if country = Country.find_by_shortname(shortname)
        country.add_tax(price)
      else
        price
      end
    rescue
      price
    end
  end
end

#MOVED TO ITS OWN CLASS FILE IN /models
#Method for Models
#class CartBase
#  def add_country_tax(price,shortname)
#    begin
#      shortname = "fr" if shortname == "EU"
#      if country = Country.find_by_shortname(shortname)
#        country.add_tax(price)
#      else
#        price
#      end
#    rescue
#      price
#    end
#  end
#end

#Method for Controller
class ActionController::Base
  def add_country_tax(price)
    begin
      shortname = session[:country] == "EU" ? "fr" : session[:country]
      if country = Country.find_by_shortname(shortname)
        country.add_tax(price)
      else
        price
      end
    rescue
      price
    end
  end
end

#Method for Controller
class ActionView::Base
  def add_country_tax(price)
    begin
      shortname = session[:country] == "EU" ? "fr" : session[:country]
      if country = Country.find_by_shortname(shortname)
        country.add_tax(price)
      else
        price
      end
    rescue
      price
    end
  end
end

#Method for Helpers
module GetText
  def add_country_tax(price)
    begin
      shortname = session[:country] == "EU" ? "fr" : session[:country]
      if country = Country.find_by_shortname(shortname)
        country.add_tax(price)
      else
        price
      end
    rescue
      price
    end
  end
end
