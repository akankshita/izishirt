class Technology < ActiveRecord::Base
  has_many :colors
  has_many :prices
  
  def get_text_price_list(currency)
    priceList = ''
    prices.each { |priceRow| 
      priceRow.name == 'text' ? priceList+=(priceRow.price*currency_rate(currency)).to_s+'|' : nil
    }
    priceList.chop!
  end
  
end
