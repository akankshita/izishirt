module Admin::BulkOrdersHelper
  def link_to_with_sort(name, sort_field, options = {}, html_options = nil)
    current_sort = params[:sort]
    current_way = params[:way]

    if (sort_field == current_sort)
      way = (current_way == 'desc') ? 'asc' : 'desc';
      arrow = '&nbsp;' + image_tag('admin-arrow-th.gif')
    else
      way = 'asc'
      arrow = ''
    end

    options[:sort] = sort_field
    options[:way] = way
    link_to(name, options, html_options) + arrow
  end
  
  def escape_for_select_options(str)
    # remove ' and newlines
    return str.delete("'").delete("\n")
  end

	def show_text_page(id_page, id_page_to_test, label)
		txt = ""

		txt += "<b>[" if id_page == id_page_to_test

		txt += label

		txt += "]</b>" if id_page == id_page_to_test

		return txt
	end
  
  def display_printer(user)
    return (user) ? user.username : "N/A"
  end
  
  def display_print_color(print)
    begin
      return print.quote_product_color.name(session[:language_id])
    rescue
      return ""
    end
  end
  
 
  
  
  
  def display_print_size_name(print_size)
    begin
      return print_size.name
    rescue
      return "N/A (Problem !)"
    end
  end

  def display_contact_by(bulk_order)
    str = ""

    #:ADMIN_BULK_ORDER_CONTACT_BY_PHONE => ["phone", "phone"],
    #:ADMIN_BULK_ORDER_CONTACT_BY_EMAIL => ["mail", "mail"],

    if bulk_order.contact_by_phone
      str += t(:admin_bulk_order_contact_by_phone) + " "
    end

    if bulk_order.contact_by_email
      str += t(:admin_bulk_order_contact_by_email)
    end

    return str
  end
  
end
