class PopupController < ApplicationController
  layout "popup"

  def terms
    @title=t(:terms_title_popup)
  end

  def pending_earnings
    render :layout=>false
  end

  def decline
    @title=t(:reasons_for_artwork_decline)
  end

  def terms_marketplace
    @title=t(:terms_marketplace_title_popup)
  end

  def apparel
    @model = Model.find(params[:id])
    @model_sizes = @model.active_model_sizes
    @title = @model.local_nickname(session[:language_id])
  end

  def copyright
    @title = t(:design_copyright_info)
  end
  
  def shop_2_add_to_cart_continue_shopping
    @product = Product.find(params[:product_id])

	@store = @product.store

    render :layout=>false
  end


  def add_blank_keep_shopping
    render :layout=>false
  end


  def boutique_add_to_cart_continue_shopping
    @product = Product.find(params[:product_id])
    render :layout=>false
  end

  def pp_request_payment
    render :layout=>false
  end

  def report_as_copyright

	@object_id = params[:object_id]
	@type = params[:type]

    render :layout=>false
  end

	def report_as_copyright_step_2

		render :layout => false
	end

  def please_choose_a_shirt_size
    render :layout=>false
  end

  def pp_request_payment_step_2
    render :layout=>false
  end
  
  def pp_delete_izishirt_account
    render :layout=>false
  end

  def pp_sell_designs_izishirt
    render :layout=>false
  end

  def pp_edit_avatar
    render :layout=>false
  end


end


