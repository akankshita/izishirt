require 'uri'

class DateUtil
	# BEGIN Business days (should be in a util class)
	  def self.next_business_day(date)
	    self.skip_weekends(date, 1)
	  end

	  def self.previous_business_day(date)
	    self.skip_weekends(date, -1)
	  end

	  def self.previous_business_days(date, nb)
	    if nb == 0
	      return date
	    end

	    (1..nb).each do |i|
	      date = self.previous_business_day(date)
	    end

	    return date
	  end

	  def self.next_business_days(date, nb)
	    if nb == 0
	      return date
	    end

	    (1..nb).each do |i|
	      date = self.next_business_day(date)
	    end

	    return date
	  end

	  def self.skip_weekends(date, inc)
	    date += inc

	    while (date.wday % 7 == 0) or (date.wday % 7 == 6) do
	      date += inc
	    end

	    date
	  end
	  # END Business days
end
