class Admin::CurrencyController < Administration
  def index
    @currency = Currency.find(:all)
  end
  
  def update_currency
		 @currency = Currency.find(:all)
		 for i in 1...@currency.size do 
		    temp_ratio = params[:currency]["label_#{@currency[i].id}"].to_f
			break if temp_ratio < 0
			Currency.update(@currency[i].id.to_i, {:ratio => temp_ratio})
		 end
		 if temp_ratio < 0
			flash[:notice] = "Invalid input values"
		 else
			flash[:notice] = t(:admin_flash_updated)   
		end
		 redirect_to :action => "index"
  end  
end
