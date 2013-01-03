module Admin::OrderedGarmentsHelper
  def display_quantity(list)
    list.inject(0){ |sum,x| sum + x.quantity}
  end
  def display_garment_change(list)
    list.each do |item|
      if item.garments_changed
        return t(:admin_garments_yes) 
      end
    end
    return t(:admin_garments_no)
  end
  def display_ids(list)
    ids = []
    list.each{ |item| ids << item.id }
    ids.join(",")
  end
  
  def display_from(history)
    
    begin
      if history.from_id <= 0
        return ""
      end
    rescue
      return ""
    end
    
    case history.attribute_changed
      when 'model': Model.find(history.from_id).local_name(session[:language_id])
      when 'color': Color.find(history.from_id).localized_colors.find_by_language_id(session[:language_id]).name
      when 'size': Size.find(history.from_id).name
      else history.from_id
    end
  end

  

  def display_to(history)
    
    begin
      if history.to_id <= 0
        return ""
      end
    rescue
      return ""
    end
    
    case history.attribute_changed
      when 'model': Model.find(history.to_id).local_name(session[:language_id])
      when 'color': Color.find(history.to_id).localized_colors.find_by_language_id(session[:language_id]).name
      when 'size': history.to_id > 0 ? Size.find(history.to_id).name : ""
      else history.to_id
    end
  end

  def business_days_future(num,start_date=nil)
    # takes the number of days in the past you are looking for
    # like 10 business days ago
    start_date ||= Date.today
    start_day_of_week = start_date.cwday #Date.today.cwday
    ans = 0
    # find the number of weeks
    weeks = num / 5.0
    #puts "yields #{weeks} weeks"
      
    temp_num = num > 5 ? 5 : num
    #puts "first temp num #{temp_num}"
    
    begin
      
      ans += days_to_adjust_f(start_day_of_week,temp_num)
      #puts "ans in loop #{ans}"
      
      weeks -= 1.0
      #puts "weeks in loop #{weeks}"
      
      temp_num = (weeks >= 1) ? 5 : num % 5
      #puts "temp_num after loop #{temp_num}"
    end while weeks > 0
    
    #puts "#{start_date} - #{num} - #{ans}"
    days_ago = start_date + num + ans
    
  end
  
  
  
  def days_to_adjust_f(start_day_of_week,num)
    ansr = 0
    case start_day_of_week
    when 1
      if 5 == num then ansr += 2 end
    when 2
      if (4..5).include?(num) then ansr += 2 end
    when 3
      if (3..5).include?(num) then ansr += 2 end
    when 4
      if (2..5).include?(num) then ansr += 2 end
    when 5
      if (1..5).include?(num) then ansr += 2 end
    when 6
      if (1..5).include?(num) then ansr += 1 end
    when 7
      #do nothing 
    end
    return ansr
  end


end
