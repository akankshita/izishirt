#Method for Controller
class ActionController::Base
  def currency_rate(currency)
    begin
      if ["EUR","USD", "GBP", "CAD", "AUD"].include?(currency)
        #CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
        #People in Europe are going to pay more
        1.0
      elsif currency == "CHF"
        1.0
      elsif currency == "MXN"
        12
      else
        CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
      end
    rescue
      1.0
    end
  end

end

class ActiveRecord::Base
  def currency_rate(currency)
    begin
      if ["EUR","USD", "GBP", "CAD", "AUD"].include?(currency)
        #CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
        #People in Europe are going to pay more
        1.0
      elsif currency == "CHF"
        1.0
      elsif currency == "MXN"
        12
      else
        CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
      end
    rescue
      1.0
    end
  end

  def exact_currency_rate(from_currency, to_currency)
	begin
		return CurrencyExchange.currency_exchange(100, from_currency, to_currency)/100.00
	rescue
	end
	
	return 1.0
  end

  def main_currency_convert(from_currency, to_currency, amount)
	# TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
	# THERE IS A TO_I IN THE LIB, check it out before using it !
        return CurrencyExchange.currency_exchange(amount, from_currency, to_currency)
  end

end

#Method for Controller
class ActionView::Base
  def currency_rate(currency)
    begin
      if ["EUR","USD", "GBP", "CAD", "AUD"].include?(currency)
        #CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
        #People in Europe are going to pay more
        1.0
      elsif currency == "CHF"
        1.0
      elsif currency == "MXN"
        12
      else
        CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
      end
    rescue
      1.0
    end
  end


end

#Method for Helpers
module Rate
  def currency_rate(currency)
    begin
      if ["EUR","USD", "GBP", "CAD", "AUD"].include?(currency)
        #CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
        #People in Europe are going to pay more
        1.0
      elsif currency == "CHF"
        1.0
      elsif currency == "MXN"
        12
      else
        CurrencyExchange.currency_exchange(100,"CAD",currency)/100.00
      end
    rescue
      1.0
    end
  end
end
