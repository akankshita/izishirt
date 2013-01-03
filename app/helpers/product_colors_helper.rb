module ProductColorsHelper

  def product_colors(product,type)


    case type
      when "market"
        link_color = "#{marketplace_product_url(product.id)}"
      when "iframe"
        link_color = "iframe_product/#{product.id}"
      else
        link_color = "#{boutique_product_url(product.id)}"
    end
    
    res = product.available_colors(8).map{|c|
      #link_to image_tag ("/izishirtfiles/colors/#{c.color.preview_image}",
      #  :height=>10,
      #  :width=>10,
      #  :alt => "",
      #  :onmouseover => "change_color_img(#{product.id}, #{c.color.id});",
      #  :onmouseout => "document.body.style.cursor = 'default';",
      #  :style => "cursor: pointer;"),
      #  "#{link_color}?color_id=#{c.color.id}"
	"<a href='#{link_color}?color_id=#{c.color.id}'><img src='/izishirtfiles/colors/#{c.color.preview_image}' style='width: 10px; height: 10px;' onmouseout=\"document.body.style.cursor = 'default';\" onmouseover='change_color_img(#{product.id}, #{c.color.id});' /></a>"
    }

	return res
  end
end
