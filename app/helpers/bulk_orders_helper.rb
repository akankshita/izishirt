module BulkOrdersHelper

  def print_bulk_order_value(value, text, css_class, additional_text = "")
    str = ""
    unless value.nil? || value.to_s.length == 0
      str = "<div class='stdField #{css_class}'><span class='name'>#{t(text)}#{additional_text}:</span> <span class='value'>#{value}</span></div>"
    end
    return str
  end

  def print_check_garment_type(str_id)
    garment_type = BulkOrderGarmentType.find_by_str_id(str_id)

    begin
      name = garment_type.localized_bulk_order_garment_types.find_by_language_id(session[:language_id]).name
    rescue
      return ""
    end

    return "<input type=\"checkbox\" name=\"garment_type_#{garment_type.id}\" id=\"garment_type_#{garment_type.id}\" /> #{name}"
  end

end
