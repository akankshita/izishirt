class HomepageBanner < ActiveRecord::Base

  def get_text(language, country, param_lang)
    if country == "CA" && language == "en"
      return text_en
    elsif country == "CA" && language == "fr"
      return text_fr
    elsif country == "US"
      return text_us
    else
      return text_en
    end
  end

  def get_link(language, country, param_lang)
    if country == "CA" && language == "en"
      return link_en
    elsif country == "CA" && language == "fr"
      return link_fr
    elsif country == "US"
      return link_us
    else
      return link_en
    end
  end

end
