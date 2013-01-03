module Admin::ShippingHelper
  def listing_row_class_shipping(order)
    css_class = ""

    if order.bulk_order?
        css_class = 'bulk'
    elsif (order.critical)
        css_class = 'critical'
    elsif (order.xmas)
        css_class = 'xmas'
    elsif (order.rush_order)
      css_class = 'rush_order'
    elsif (garments_reordered(order))
      css_class = 'reordered'
    else
      css_class = cycle('odd','')
    end

    return css_class
  end

  def display_order_client_name(order)
    if ! order.user
      return ""
    end

    return order.user.firstname + " " + order.user.lastname
  end

  # Displays a flag if flagged_date >= status_changed_on
  def display_shipping_flag(order)
    if order && order.flagged_date && order.status_changed_on && order.flagged_date >= order.status_changed_on
      return "<img style='padding-right:4px' src='/images/admin/flag_red.png' height='12'>"
    end

    return ""
  end            

  def display_compact_list_options(order)
    list_options = []

    if order.hide_address
      list_options << "Hide address from printers"
    else
      list_options << "<del>Hide address from printers</del>"
    end

    if order.rush_order
      list_options << "Is rush"
    else
      list_options << "<del>Is rush</del>"
    end

    if order.xmas
      list_options << "Is Xmas"
    else
      list_options << "<del>Is Xmas</del>"
    end

    if order.critical
      list_options << "Is Critical Order"
    else
      list_options << "<del>Is Critical Order</del>"
    end

    if order.artwork_sent
      list_options << "Artwork sent"
    else
      list_options << "<del>Artwork sent</del>"
    end

    if order.garments_changed()
      list_options << "Garments Changed"
    else
      list_options << "<del>Garments Changed</del>"
    end

    if order.garments_ordered()
      list_options << "All Garments Ordered"
    else
      list_options << "<del>All Garments Ordered</del>"
    end
    
    to_str = ""
    
    (0..(list_options.length - 1)).each do |i|
      to_str += list_options[i]

      if i != list_options.length - 1
        to_str += ", "
      end
    end

    return to_str
  end

  def display_eta(order, with_color = true)
    eta_str = "<font"

    if with_color && order.eta() < order.next_business_days(DateTime.now, order.mean_shipping_nb_days_delay())
      eta_str += " color=\"red\""
    end

    eta_str += ">"

    eta_str += order.eta().to_s

    eta_str += "</font>"

    return eta_str
  end

  def pagination_links_remote(paginator)
	  page_options = {:window_size => 1}
	  pagination_links_each(paginator, page_options) do |n|
		options = {
		  :url => {:action => 'search', :params => params.merge({:page => n, :i=>1})},
		  :update => 'listing'
		}
		html_options = {:href => url_for(:action => 'search', :params => params.merge({:page => n})), :class => 'blue bold'}
		link_to_remote(n.to_s, options, html_options)
	  end
	end 
  
end
