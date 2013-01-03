#Method for Models
class ActiveRecord::Base
  def get_text(string,lang=false)
    begin
      id = lang ? lang : session[:language_id]
      id = id ? id - 1 : 2
      LANG[string][id]
    rescue
      LANG[string][2]
    end
  end
end


#Method for Controller
class ActionController::Base
  def get_text(string,lang=false)
    begin
      id = lang ? lang : session[:language_id]
      id = id ? id - 1 : 2
      LANG[string][id]
    rescue
      LANG[string][2]
    end
  end
end

#Method for Controller
class ActionView::Base
  def get_text(string,lang=false)
    begin
      id = lang ? lang : session[:language_id]
      id = id ? id - 1 : 2
      LANG[string][id]
    rescue
      LANG[string][2]
    end
  end
end

#Method for Helpers
module GetText
  def get_text(string,lang=false)
    begin
      id = lang ? lang : session[:language_id]
      id = id ? id - 1 : 2
      LANG[string][id]
    rescue
      LANG[string][2]
    end
  end
end
