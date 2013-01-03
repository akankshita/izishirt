class LocalizedCategory < ActiveRecord::Base
  belongs_to :language
  belongs_to :category
  has_one :localized_image_category, :dependent => :destroy
  
  validates_presence_of :name

  def images_currency(currency_label)
    if ! localized_image_category
      return []
    end

    currency_id = Currency.find_by_label(currency_label)

    images = LocalizedCurrencyImageCategory.find_all_by_localized_image_category_id_and_active_and_currency_id(localized_image_category.id, 1, currency_id)

    return images
  end
end
