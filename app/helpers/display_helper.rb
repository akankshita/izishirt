module DisplayHelper

  def get_back_to
    if session[:shop_page] == "category"
      t(:back_to_category)
    elsif session[:shop_page] == "result_tag"
      t(:back_to_tag)
    elsif session[:shop_page] == "result_search"
      t(:back_to_search)
    elsif session[:shop_page] == "shop"
      t(:back_to_top_25)
    elsif session[:shop_page] == "staff_pick"
      t(:back_to_staff_pick) 
    elsif session[:shop_page] == "new"
      t(:back_to_new)
    end
  end

	def pagination_links_remote(paginator)
	  page_options = {:window_size => 1}
	  pagination_links_each(paginator, page_options) do |n|
		options = {
		  :url => {:action => 'list', :params => params.merge({:page => n, :i=>1})},
		  :update => 'main_image_list',
		  :before => "Element.show('spinner')",
		  :success => "Element.hide('spinner')"
		}
		html_options = {:href => url_for(:action => 'list', :params => params.merge({:page => n})), :class => 'blue bold'}
		link_to_remote(n.to_s, options, html_options)
	  end
	end 
	
	def pagination_links_remote2(paginator)
	  page_options = {:window_size => 1}
	  pagination_links_each(paginator, page_options) do |n|
		options = {
		  :url => {:action => 'list', :params => params.merge({:page => n, :i=>2})},
		  :update => 'table2',
		  :before => "Element.show('spinner2')",
		  :success => "Element.hide('spinner2')"
		}
		html_options = {:href => url_for(:action => 'list', :params => params.merge({:page => n}))}
		link_to_remote(n.to_s, options, html_options)
	  end
	end 	

	def image_list_links(paginator)
	  page_options = {:window_size => 1}
	  pagination_links_each(paginator, page_options) do |n|
		options = {
		  :url => {:action => 'list', :params => params.merge({:page => n, :i=>2})},
		  :update => 'image_list',
		  :before => "Element.show('spinner2')",
		  :success => "Element.hide('spinner2')"
		}
		html_options = {:href => url_for(:action => 'list', :params => params.merge({:page => n})), :class=>'blue bold'}
		link_to_remote(n.to_s, options, html_options)
	  end
	end 	
	
	def get_path_filename(img)
 	  path = img.orig_image.url("100")
	end

  def get_category_main_title
    return (@local_title.nil? && @category) ? @category.local_title(session[:language_id], session[:country]) : @local_title
  end


    def display_category_for_left_menu(category,depth=0)
      #category = Category.find(category.category_id) if category.category_id 
      ret = category_link(category,depth) 
      if (category_list.index(category.id) != nil)
        category.sub_categories.each do |sub_category|
          ret += display_category_for_left_menu(sub_category, depth+1)
        end
      end
      ret
    end
    
    def category_link(category,depth=0)
      #ret = "<a href='/display/result/#{category.id}' title='#{category.localized_categories[session[:language_id]-1].name} T-shirts'>"
      #ret += "<span style='padding-left:#{15*depth}px'>#{category.localized_categories[session[:language_id]-1].name}</span></a>"
      ret = link_to "<span style='padding-left:#{15*depth}px'>#{category.local_name(session[:language_id])}</span>", {:controller=>"/display/result/#{category.id}"}, :title=>"#{category.local_name(session[:language_id])} T-shirts"
      ret
    end

    def category_list
      @current = @current_category
      return [] if @current == "none"
      list = [@current.id]
      while @current.parent_categories != []
        list << @current.parent_categories[0].id
        @current = @current.parent_categories[0]
      end
      list
    end


    

  def table_list_shipping_info(list_infos)
    html = ""
    i = 0

    for info in list_infos
      i += 1

      back_color = (i % 2 == 0) ? "#ebeaea" : "#FFFFFF"

      html += "<tr style=\"background-color:#{back_color}\"><td>#{info[0]}</td><td>#{info[1]}</td></tr>"
    end

    return html
  end

  def get_category_banners(category)
    category_images = []
    
    begin
      currency = (session[:currency] == "EUR") ? "EURO" : session[:currency]
      category_images = (category) ? category.banner(currency, session[:language_id]) : []
    rescue
    end

    height_banner = (category_images == []) ? "251px" : "213px"

    return category_images, height_banner
  end

  def active_category(cat,cats)
    cat == cats.first ? "active" : ""
  end

  def hide_category(cat,cats)
    cat != cats.first ? "none" : ""
  end

  def print_colors_with_fade(model)
    model.model_specifications.collect {|ms| ms.color}[0..15].map {|c|
      image_tag "/izishirtfiles/colors/#{c.preview_image}",
        {:id => "#{model.id}_#{c.id}", 
         :class => 'apparelColor', 
         :alt => '',
         :onmouseover => "document.body.style.cursor = 'pointer';",
         :onclick => "javascript:change_apparel_color(#{model.id},#{c.id})",
         :onmouseout => "document.body.style.cursor = 'default';"}
    }
  end

  def image_flash_layout_category(category_id)
    
    begin
      cat = Category.find(category_id)
    rescue
      cat = nil
    end
    
    if ! cat
      return nil
    end
    
    images_id = cat.active_images.map{|i|i.id}
    
    if images_id.size == 0
      return nil
    end
    
    max = LocalizedImage.maximum(:sorting_rate, :conditions=>"image_id IN (#{images_id.join(",")}) and country_id=#{@category_country_id} and language_id=#{session[:language_id].to_s}")
    first_image = LocalizedImage.find_by_sorting_rate(max, :conditions=>"image_id IN (#{images_id.join(",")}) and country_id=#{@category_country_id} and language_id=#{session[:language_id].to_s}")
    if first_image.nil?
      return nil
    end
    return Image.find(first_image.image_id)
  end

  def category_for_cloud_tag(category_id, cpt_class)
    array_ret = []
    begin
      cat = Category.find(category_id)
    rescue
      return array_ret
    end
    array_ret << link_to(cat.local_name(session[:language_id]), {:controller=>:display, :action=>:result, :id=>cat.id}, :class=>"tag#{cpt_class.to_s}")
    cpt_class = (cpt_class+1)%10
    if cat.sub_categories.size > 0
      array_ret << link_to(cat.sub_categories[0].local_name(session[:language_id]), {:controller=>:display, :action=>:result, :id=>cat.sub_categories[0].id}, :class=>"tag#{cpt_class.to_s}")
    end
    return array_ret
  end

  def get_tags_from_product_name(product)
    tags = product.name.split(',')
    tags.each do |t|
      t.strip!
    end
    return tags
  end

  

  
end
