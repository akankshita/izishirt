module Admin::HomepageHelper
  def path_lang(lang_id, country)
    case country
      when "CA"
        lang_id == 1 ? lang_path = "fr" : lang_path = "en"
      when "US"
        lang_id == 2 ? lang_path = "us" : lang_path = "es"
      when "FR"
        lang_path = "france"
      when "GB"
        lang_path = "uk"
      when "BE"
        lang_path = "be"
      when "PT"
        lang_path = "pt"
      when "CH"
        lang_path = "ch"
      when "AU"
        lang_path = "australia"
      when "BR"
        lang_path = "br"
      when "ES"
        lang_path = "es"
      when "DE"
        lang_path = "de"
      when "AT"
        lang_path = "at"
      when "MX"
        lang_path = "mx"
      when "EU"
        lang_id == 1 ? lang_path = "fr-eu" : lang_path = "eu"
    end
    
    return lang_path
  end
end
