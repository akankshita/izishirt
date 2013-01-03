class Homepage < ActiveRecord::Base
  belongs_to :category

  def self.find_top_product_categories(language)
    user_id = User.find_by_username("home"+language)
    
    home_store = Store.find_by_user_id(user_id)
    return home_store.categories
  end

  def self.find_landingpages_products_categories
    user_id = User.find_by_username("landingpages")
    home_store = Store.find_by_user_id(user_id)
    return home_store.categories
  end
end
