module Checkout2Helper
  def is_guest?
    return true if session[:user_id].nil? && session[:guest_id]
    return false
  end


  def get_christmas_shipping_standard_delays(country,province,in_stock,is_pickup=false)
    if ["ON","QC"].include?(province) && country == "CA" && in_stock
      return t(:sh_christ_std_stk_qc)
    elsif ["ON","QC"].include?(province) && country == "CA"
      return t(:sh_christ_std_qc)
    elsif in_stock && country=="CA"
      return t(:sh_christ_std_stk_ca)
    elsif country == "CA"
      return t(:sh_christ_std_ca)
    elsif country == "US"
      return t(:shipping_basic_detail_us)
    else
      return t(:shipping_basic_detail_intl)
    end
  end

  def get_christmas_shipping_rush_delays(country,province,in_stock,is_pickup=false)
    if ["ON","QC"].include?(province) && country == "CA" && in_stock && is_pickup == false
      return t(:sh_christ_rush_stk_qc)
    elsif ["ON","QC"].include?(province) && country == "CA" && in_stock
      return t(:sh_christ_rush_stk_pickup_qc)
    elsif ["ON","QC"].include?(province) && country == "CA" && is_pickup == false
      return t(:sh_christ_rush_qc)
    elsif ["ON","QC"].include?(province) && country == "CA"
      return t(:sh_christ_rush_pickup_qc)
    elsif in_stock && country=="CA" && is_pickup == false
      return t(:sh_christ_rush_stk_ca)
    elsif in_stock && country=="CA"
      return t(:sh_christ_rush_stk_pickup_ca)
    elsif country == "CA"
      return t(:sh_christ_rush_ca)
    elsif country == "US"
      return t(:shipping_xpress_detail_ca)
    else
      return ""
    end
  end


  def get_shipping_text(shipping_id, country, locale = nil)
    locale = I18n.locale if locale == nil
    str = get_shipping_name(shipping_id, locale)
    str += ": "
    if country == "CA"
      if shipping_id == SHIPPING_BASIC
        str += t(:shipping_basic_detail_ca, :locale=>locale)
      elsif shipping_id == SHIPPING_EXPRESS
        str += t(:shipping_xpress_detail_ca, :locale=>locale)
      elsif shipping_id == SHIPPING_PICKUP
        str += t(:shipping_pickup_detail_ca, :locale=>locale)
      elsif shipping_id == SHIPPING_RUSH_PICKUP
        str += t(:shipping_rush_pickup_detail_ca, :locale=>locale)
      end
    elsif country == "US"
      if shipping_id == SHIPPING_BASIC
        str += t(:shipping_basic_detail_us, :locale=>locale)
      elsif shipping_id == SHIPPING_EXPRESS
        str += t(:shipping_xpress_detail_ca, :locale=>locale)
      elsif shipping_id == SHIPPING_PICKUP
        str += t(:shipping_pickup_detail_ca, :locale=>locale)
      elsif shipping_id == SHIPPING_RUSH_PICKUP
        str += t(:shipping_rush_pickup_detail_ca, :locale=>locale)
      end
    else
      str += t(:shipping_basic_detail_intl, :locale=>locale)
    end
  end





end
