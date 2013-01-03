class OrderController < ApplicationController

  helper "myizishirt/orders"


  def index

    if params[:order_id] && params[:email]#the form has been submitted
      if params[:email].length < 1
        flash[:tracking_error] = t(:error_order_status_form)
        return
      end

      order = Order.find_by_id_and_guest_email_and_confirmed(params[:order_id],params[:email],1)
      type="guest"
      if order.nil?
        type = "user"
        user = User.find_by_email(params[:email])
        if user.nil?
          flash[:tracking_error] = t(:error_order_status_form)
          return
        end
        order = Order.find_by_id_and_user_id_and_confirmed(params[:order_id], user.id,1)
        if order.nil?
          flash[:tracking_error] = t(:error_order_status_form)
          return
        end
      end

      redirect_to :action=>:list, :id=>params[:order_id], :email=>params[:email], :type=>type
      return

    end

  end

  def list
    if !params[:id] || !params[:email] || !params[:type]
      redirect_to :action=>:index
      return
    end
    
    if params[:type] == "guest"
      @order = Order.find_by_id_and_guest_email_and_confirmed(params[:id],params[:email],1)
    else
      user = User.find_by_email(params[:email])
      if user.nil?
        redirect_to :action=>:index
        return
      end
      @order = Order.find_by_id_and_user_id_and_confirmed(params[:id], user.id,1)
    end

    if @order.nil?
      redirect_to :action=>:index
      return
    end

  end

  def lost_id
    if params[:email] && params[:email] != ''
      orders = Order.find_all_by_guest_email_and_confirmed(params[:email],1)
      if orders.length == 0
        user = User.find_by_email(params[:email])
        if user.nil?
          render :text => "<div class='errorMessage'>#{t(:retrieve_orders_id_error_message)}</div>"
          return
        end
        orders = Order.find_all_by_user_id_and_confirmed(user.id, 1,:order=>"created_on DESC")
      end

      if orders.length == 0
        render :text => "<div class='errorMessage'>#{t(:retrieve_orders_id_error_message)}</div>"
        return
      end
      if SendMail.deliver_lost_orders_id(params[:email], orders, session[:language])
        render :text => "<div class='successMessage'>#{t(:retrieve_orders_id_success_message)}</div>"
        return
      else
        render :text => "<div class='errorMessage'>#{t(:myizishirt_login_ctl_mail_faillure)}</div>"
        return
      end
    else
      render :nothing=>true
    end
  end

  def show_product

    if params[:order]
      order = Order.find(params[:order])
      @product = order.ordered_products.first
      @show_product = false

    else
      @product = OrderedProduct.find(params[:id])
      @show_product = true
      order = @product.order
    end
    if !@product.product_id.nil?
      @product_name = Product.find(@product.product_id).name
    else
      @product_name = t(:user_created)
    end

    @order_status = order.status
    if @order_status == SHIPPING_TYPE_AWAITING_STOCK
      @order_status = SHIPPING_TYPE_BATCHING
    end

    @order_status_text = get_order_status_label(@order_status.to_i)

    if @order_status != SHIPPING_TYPE_SHIPPED
      @order_status_explanation = Order.order_status_explanations(session[:language])[@order_status.to_i]
    else
      @order_status_explanation = get_explanation_shipped(order)
    end
    @status_color = SHIPPING_TYPE_COLOR[@order_status]

    render :layout => false
  end

  private

  def get_explanation_shipped(order)
    if order.pick_up && order.pick_up.to_i == 1
      @order_status_text += " (#{t(:pick_up)})"
      return t(:order_status_explanation_pick_up)
    elsif order.shipping_type && (order.shipping_type == SHIPPING_XPRESS_POST || order.shipping_type == SHIPPING_EXPRESS)
      @order_status_text += " (#{t(:xpress)})"
      return t(:order_status_explanation_xpress)
    elsif order.shipping && order.shipping.get_country.upcase == "CANADA"
      @order_status_text += " (#{t(:basic)})"
      return t(:order_status_explanation_basic)
    else
      @order_status_text += " (#{t(:basic)})"
      return t(:order_status_explanation_international)
    end
  end

end
