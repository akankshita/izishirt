class CartBase
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
