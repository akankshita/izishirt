module ApparelHelper

  def print_colors(section,model)
    model.colors[0.. [model.colors.length, 7].min ].map {|c|
      link_to image_tag("/izishirtfiles/colors/#{c.preview_image}",
        {:id => "#{model.id}_#{c.id}", 
         :class => 'aparelColor',
         :height=> 10,
         :width=> 10,
         :alt => c.localized_name(session[:language_id]),
         :onmouseover => "javascript:change_color('#{section}',#{model.id},#{c.id})",
         :onmouseout => "document.body.style.cursor = 'default';" })
    }
  end

 

  def print_colors_with_fade(model)
    model.colors.map {|c|
      image_tag "/izishirtfiles/colors/#{c.preview_image}",
        {:id => "#{model.id}_#{c.id}", 
         :class => 'aparelColor', 
         :alt => c.localized_name(session[:language_id]),
         :onmouseover => "document.body.style.cursor = 'pointer';",
         :onclick => "javascript:change_apparel_color(#{model.id},#{c.id})",
         :onmouseout => "document.body.style.cursor = 'default';" }
    }
  end
end
