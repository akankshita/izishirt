module Myizishirt::CustomizeBoutiqueHelper
  def color_picker(name,value)
    #build the hexes
    hexes = []
    (0..15).step(3) do |one|
      (0..15).step(3) do |two|
        (0..15).step(3) do |three|
          hexes << one.to_s(16) + two.to_s(16) + three.to_s(16) + one.to_s(16) + two.to_s(16) + three.to_s(16)
        end
      end
    end
    #Not all colors are available cause it would be too much
    #Make sure default colors are included
    hexes << "1D91C7"
    hexes << "cfcfcf"
    hexes << "f4f4f4"
    hexes << "9E0221"
    hexes << "534C4C"

    arr = []
    on_change_function = "onChange=\"document.getElementById('color_div_#{name}').style.backgroundColor = '#'+this[this.selectedIndex].value\""
    10.times { arr << "&nbsp;" }
    returning html = '' do
      html << "<select name=#{name} id=#{name}_color #{on_change_function} style='width:80px'>"
      html << hexes.collect {|c|
        selected = c == value ? "selected='selected'" : '' 
        "<option value='#{c}' style='color:#ffffff;background-color: ##{c}' #{selected}>#{c}</option>" }.join("\n")
      html << "</select>"
    end
  end

  def theme_class(themes, theme)
    themes.last != theme && themes.index(theme) % 4 != 3 ? "customThemeWrapper" : "lastThemeWrapper"
  end

  def dashed_class(themes,theme)
    themes.index(theme) + 4 > themes.size-1 ? "lastDashed" : "dashed"
  end

  def get_active_edit_menu()
    
    if request.request_uri.index("myizishirt/customize_boutique/design")
      "design"
    elsif request.request_uri.index("myizishirt/customize_boutique/tshirt_app")
      "tshirt_app"
    elsif request.request_uri.index("myizishirt/customize_boutique/checkout")
      "checkout"
    elsif request.request_uri.index("myizishirt/customize_boutique/shop_info")
      "shop_info"
    elsif request.request_uri.index("myizishirt/customize_boutique/shop_seo")
      "shop_seo"
    elsif (request.request_uri.index("myizishirt/customize_boutique/themes") || request.request_uri.index("myizishirt/customize_boutique"))
      "themes"
    end
  end

  def get_class_edit_menu(menu, active_menu)
    if (menu == active_menu)
      "active_edit_menu"
    else
      "inactive_edit_menu"
    end

  end

  def get_state_edit_menu(menu, active_menu)
    if (menu == active_menu)
      "on"
    else
      "off"
    end

  end


end
