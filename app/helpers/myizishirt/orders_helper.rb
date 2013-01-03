module Myizishirt::OrdersHelper

  def print_shipped_on (order)
    if order.shipped_on.nil? 
      ""
    else
      order.shipped_on.strftime('%m/%d/%y')
    end
  end

  def print_eta (order)

    if order.pick_up.to_i == 1
      date1 = calculate_eta(order.created_on, 3)
      date2 = calculate_eta(order.created_on, 6)
    elsif order.shipping_type && (order.shipping_type == SHIPPING_XPRESS_POST || order.shipping_type == SHIPPING_EXPRESS)
      date1 = calculate_eta(order.created_on, 5)
      date2 = calculate_eta(order.created_on, 7)
    elsif order.shipping && order.shipping.get_country.upcase == "CANADA"
      date1 = calculate_eta(order.created_on, 6)
      date2 = calculate_eta(order.created_on, 12)
    else
      date1 = calculate_eta(order.created_on, 8)
      date2 = calculate_eta(order.created_on, 14)
    end

    return date1.strftime('%m/%d/%y') + " - " + date2.strftime('%m/%d/%y')


  end
  
  def print_tracking(order)
    if order.tracking_number.nil? || order.tracking_number.empty?
      "N/A"
    else
      order.tracking_number
    end
  end


  def calculate_eta(date, days)

    i = 0
    while i < days || date.wday == 0 || date.wday == 6
      if date.wday > 0 && date.wday < 6
        i += 1
      end
      date += 1.day
    end
    return date
  end
end
