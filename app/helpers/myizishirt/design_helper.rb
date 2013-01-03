module Myizishirt::DesignHelper

  def effect_refresh_design_list()
    return "new Effect.Highlight('mydesigns', { startcolor: '#fbffbc', endcolor: '#ffffff' });"
  end

  def build_remote_pagination_link(page_number, label)
    options = {
        :url => {:controller=>'myizishirt/design', :action => 'list', :params => {:page => page_number}, :sort_by => params[:sort_by]},
        :update => 'mydesigns',
        :before => "Element.show('spinner'); ",
        :success => "Element.hide('spinner'); #{effect_refresh_design_list()}",
        :complete => ""
      }
      html_options = {:href => url_for(:controller=>'myizishirt/design', :action => 'list', :params => {:page => page_number})}
      return link_to_remote(label, options, html_options)
  end

  def pagination_links_remote(paginator)
    page_options = {:window_size => 1}

    pagination_links_each(paginator, page_options) do |n|
      build_remote_pagination_link(n, n)
    end
  end

	
	def pagination_links_remote2(paginator)
	  page_options = {:window_size => 1}
	  pagination_links_each(paginator, page_options) do |n|
		options = {
		  :url => {:action => 'list', :params => params.merge({:page => n, :i=>2})},
		  :update => 'images_pages_content',
		  :before => "Element.show('spinner2')",
		  :success => "Element.hide('spinner2')"
		}
		html_options = {:href => url_for(:action => 'list', :params => params.merge({:page => n}))}
		link_to_remote(n.to_s, options, html_options)
	  end
	end 	
	
	def get_path_filename(img)
 	  path = img.orig_image.url("100")
	end

end
