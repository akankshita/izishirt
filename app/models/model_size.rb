class ModelSize < ActiveRecord::Base
  belongs_to :model
  belongs_to :size_type
  has_many :localized_model_sizes, :dependent => :destroy
  has_many :out_of_stocks, :dependent => :destroy
  has_many :model_ext_specifications, :dependent => :destroy
  has_many :garment_stocks
  has_many :order_garment_listing_products
  has_many :ordered_products
  has_many :blank_prices, :dependent => :destroy

  def get_clone
    model_size = clone
    model_size.update_attribute("is_default",false)
    model_size.localized_model_size_ids = []
    localized_model_sizes.each do |localized_model_size|
      model_size.localized_model_sizes << localized_model_size.clone
    end
    return model_size
  end

  def local_id(locale="en-CA")
    find_localized_model_size(locale).id
  end
  def local_name(locale="en-CA")
    find_localized_model_size(locale).name
  end
  def local_width(locale="en-CA")
    find_localized_model_size(locale).width
  end
  def local_length(locale="en-CA")
    find_localized_model_size(locale).length
  end
  def local_unit(locale="en-CA")
    find_localized_model_size(locale).unit
  end
  
  private

  def find_locale(locale)
    locale = "fr-CA" if locale == "fr"
    if Locale.exists?(:locale => locale)
      return Locale.find_by_locale(locale)
    elsif locale.include?("fr") && Locale.exists?(:locale => "fr-CA")
      return Locale.find_by_locale("fr-CA")
    else
      return Locale.find_by_locale("en-CA")
    end
  end

  def find_localized_model_size(locale)
    locale=find_locale(locale.to_s)

    #first find by local passed in
    if LocalizedModelSize.exists?(:model_size_id => id, :locale_id => locale.id)
      return LocalizedModelSize.find_by_model_size_id_and_locale_id(id,locale.id)
    end
    
    #if not found check if locale is in europe and default to europe
    if locale.europe? 
      locale_eu_name = locale.locale.include?("fr") ? "fr-EU" : "en-EU"
      locale_eu = Locale.find_by_locale(locale_eu_name)

      if LocalizedModelSize.exists?(:model_size_id => id, :locale_id => locale_eu.id)
        return LocalizedModelSize.find_by_model_size_id_and_locale_id(id,locale_eu.id)
      end
    end

    #if still not found try fr-CA if language is french
    if locale.locale.include?("fr") || locale.locale.include?("es") 
      locale_fr=Locale.find_by_locale("fr-CA")
      if  LocalizedModelSize.exists?(:model_size_id => id, :locale_id => locale_fr.id)
        return LocalizedModelSize.find_by_model_size_id_and_locale_id(id,locale_fr.id)
      end
    end

    #final resort, grab en-CA if nothing else found
    locale_en=Locale.find_by_locale("en-CA")
    return LocalizedModelSize.find_by_model_size_id_and_locale_id(id,locale_en.id)
  end
end

