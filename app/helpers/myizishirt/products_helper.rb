module Myizishirt::ProductsHelper

  def effect_saved(obj_id)
    return "new Effect.Highlight('#{obj_id}', { startcolor: '#fbffbc', endcolor: '#ffffff' });"
  end

 def build_remote_pagination_link(page_number, label)
   options = {
      :url => {:action => 'index', :params => params.merge({:page => page_number})},
      :update => 'products_list',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner'); #{effect_saved('products_list')}",
      :complete => "reInitialize();"
    }
    html_options = {:href => url_for(:action => 'refresh_products_index', :params => params.merge({:page => page_number})), :class => 'blue bold'}
    link_to_remote(label, options, html_options)
 end

def pagination_links_remote(paginator)
  page_options = {:window_size => 1}
  pagination_links_each(paginator, page_options) do |n|
    build_remote_pagination_link(n, n.to_s)
  end
end

  def editable_content(options)
    options[:content] = { :element => 'span' }.merge(options[:content])
    options[:url] = {}.merge(options[:url])
    options[:ajax] = { :okText => "ok", :cancelText => "Cancel"}.merge(options[:ajax] || {})
    script = Array.new
    script << "new Ajax.InPlaceEditor("
    script << "  '#{options[:content][:options][:id]}',"
    script << "  '#{url_for(options[:url])}',"
    script << "  {"
    script << options[:ajax].map{ |key, value| "#{key.to_s}: #{value}" }.join(", ")
    script << "  }"
    script << ")"

    content_tag(
      options[:content][:element],
      options[:content][:text],
      options[:content][:options]
    ) + javascript_tag( script.join("\n") )
  end
end
