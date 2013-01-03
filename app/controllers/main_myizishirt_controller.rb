class MainMyizishirtController < ApplicationController
  before_filter :prepare_my_izishirt
  layout 'myizishirt_2011'

  def prepare_my_izishirt

    if !session[:user_id]
      return
    end

    @in_my_izishirt = true

	  @currency_symbol = get_currency_symbol
  end

end
