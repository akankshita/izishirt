# Filters added to this controller apply to all controllers in the admin section.
# Likewise, all the methods added will be available for all those controllers. (app/controllers/admin/...)

class Administration < ApplicationController
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_izishirt_session_id'
  
  layout 'admin/admin'
  before_filter :authorize_administrator
  before_filter :set_user

  
  def authorize_administrator
    session[:original_uri_login] = request.request_uri
    if !User.allowed_back_access(session[:user_id],request.remote_ip)
      redirect_to :controller => '/myizishirt/login'
    end
  end

  def paginate_with_sort(collection_id, options={})
    order = (params[:order].nil?) ? 'id': params[:order]
    options[:order] = order if options[:order].nil?
    paginate collection_id, options
  end


  def set_user
	  @user = User.find(session[:user_id])
	  @is_wordans = @user.username == "wordans"
    
  end


  def count_images_by_image_state(pending_approval, category_condition = "")
    
    complete_cond_category = (category_condition != "") ? " AND #{category_condition}" : ""
    
    nb = Image.count(:conditions => ["pending_approval = #{pending_approval} #{complete_cond_category} AND images.is_contest = 0"])

    return nb
  end


  def build_search_image_where(category_ids)
    where = []

    where_category = (category_ids.nil?) ? "" : "AND category_id IN (#{category_ids})"

    if params[:search]
      active = (params[:image]) ? params[:image][:active].to_i : 1
      
      active_conditions = (active == 1) ? " active = #{active} " : " active = #{active} "

      if params[:search] && params[:search] != '' || params[:search_field] == 'staff'
          if params[:search_field] == 'name'
            where = ["name LIKE '%%#{params[:search]}%%' and #{active_conditions} "]
          elsif params[:search_field] == 'tag_name'
            where = ["EXISTS (SELECT * from tags WHERE tags.name LIKE '%%#{params[:search]}%%' AND tags.image_id = images.id) AND #{active_conditions} "]
          elsif params[:search_field] == 'category'
            where = ["EXISTS (SELECT * from localized_categories AS loc WHERE loc.name LIKE '%%#{params[:search]}%%' AND loc.category_id = images.category_id) AND #{active_conditions} "]
          elsif params[:search_field] == 'id'
            where = ["id = #{params[:search]} "]
          elsif params[:search_field] == 'username'
            where = ["images.user_id IN (SELECT users.id FROM users WHERE users.username = '#{params[:search]}')  AND #{active_conditions}"]
          elsif params[:search_field] == 'created_on'
            where = ["created_on between '#{params[:search].to_date}' and '#{params[:search].to_date+1.days}' and #{active_conditions}  #{where_category}"]
          elsif params[:search_field] == 'staff'
            where = ["staff_pick = 1 #{where_category} AND #{active_conditions} "]
          end
      else
        where = [" #{active_conditions}  #{where_category}"]
      end
    else
      where = (params[:find_condition]) ? params[:find_condition] : [" active = 1 AND is_private = 0 AND always_private = 0 "]
    end

    return where
  end

  def check_ordered_product_active()
    order = Order.find(params[:id])

    if ! order
      return
    end

    products = order.ordered_products.paginate(:all, :page => params[:page].to_i, :per_page => 10)

    products.each do |prod|
      if prod.is_extra_garment
        next
      end

      if params["ordered_product_#{prod.id}_active"]
        prod.update_attributes(:active => params["ordered_product_#{prod.id}_active"])
      else
        prod.update_attributes(:active => false)
      end

      if params["ordered_product_#{prod.id}_printer"]
        prod.update_attributes(:printer => params["ordered_product_#{prod.id}_printer"])
      end
      
      if params["ordered_product_#{prod.id}_no_print"]
        prod.update_attributes(:no_print => params["ordered_product_#{prod.id}_no_print"])
      else
        prod.update_attributes(:no_print => false)
      end

      if params["ordered_product_#{prod.id}_do_not_order_automatically"]
        prod.update_attributes(:do_not_order_automatically => params["ordered_product_#{prod.id}_do_not_order_automatically"])
      else
        prod.update_attributes(:do_not_order_automatically => false)
      end
      
      if params["ordered_product_#{prod.id}_apparel_supplier_id"]
        prod.update_attributes(:apparel_supplier_id => params["ordered_product_#{prod.id}_apparel_supplier_id"].to_i)  
      end
      
      if params["ordered_product_#{prod.id}_quantity"]
        prod.update_attributes(:quantity => params["ordered_product_#{prod.id}_quantity"].to_i)  
      end
      
      if params["ordered_product_#{prod.id}_model_id"] && params["ordered_product_#{prod.id}_model_id"].to_i > 0
        prod.update_attributes(:model_id => params["ordered_product_#{prod.id}_model_id"].to_i)  
      end
      
      if params["ordered_product_#{prod.id}_color_id"] && params["ordered_product_#{prod.id}_color_id"].to_i > 0
        prod.update_attributes(:color_id => params["ordered_product_#{prod.id}_color_id"].to_i)  
      end
      
      if params["ordered_product_#{prod.id}_model_size_id"] && params["ordered_product_#{prod.id}_model_size_id"].to_i > 0
        prod.update_attributes(:model_size_id => params["ordered_product_#{prod.id}_model_size_id"].to_i)  
      end
      
      if params["ordered_product_#{prod.id}_model_other"]
        prod.update_attributes(:model_other => params["ordered_product_#{prod.id}_model_other"])  
      end
      
      if params["ordered_product_#{prod.id}_color_other"]
        prod.update_attributes(:color_other => params["ordered_product_#{prod.id}_color_other"])  
      end
    end
  end
  
  def order_condition_rejected_ordered_zones()
    return "SELECT * FROM ordered_products op, ordered_zones oz WHERE op.id = oz.ordered_product_id AND op.order_id = orders.id AND oz.pending_approval = #{DESIGN_VALIDATION_STATE_DECLINED_ID}"
  end
  
  def order_condition_without_artwork_problem()
    select_rejected_ordered_zones = order_condition_rejected_ordered_zones()
    
     return " AND NOT EXISTS (#{select_rejected_ordered_zones}) AND orders.artwork_required_problem = 0"
  end

  def contains_print_condition()
    # order -> ordered_products -> ordered_zones -> ordered_zone_artwork
    # 2 cas : 1- contient ARTWORK, 2- contient text
    return " AND (EXISTS (SELECT * FROM ordered_products op WHERE op.is_extra_garment = 0 AND op.coupon_id = 0 AND op.active = 1 AND op.order_id = orders.id AND NOT EXISTS (SELECT * FROM ordered_zones oz, ordered_zone_artworks art WHERE op.id = oz.ordered_product_id AND art.ordered_zone_id = oz.id) AND NOT EXISTS (SELECT * FROM ordered_zones oz, ordered_txt_lines WHERE op.id = oz.ordered_product_id AND ordered_txt_lines.ordered_zone_id = oz.id)))"
  end
  
  def default_artwork_order_list_order()
    return "(orders.shipping_type = #{SHIPPING_RUSH} OR orders.rush_order = 1) DESC, orders.created_at ASC"
  end
  
  def execute_order_list(id, force_order = "")
    where_printer = @printer ? "(orders.printer = #{@printer_id} OR EXISTS(SELECT * FROM ordered_products op WHERE op.order_id = orders.id AND op.printer = #{@printer_id})) and " : ""

    includes = [:user, :assigned_to, { :ordered_products => :ordered_zones }]
    where = ""
    confirmed = " and confirmed = true"
    params[:id] = params[:id] ? params[:id] : nil
    params[:id] = id ? id : params[:id]

	inactive_order_statuses = "(#{SHIPPING_TYPE_ON_HOLD}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_TO_CHECK})"

    if params[:id] == 'flagged' 
      where= "#{where_printer}comment_type > 0#{confirmed}"
      where_bulk= ["#{where_printer}comment_type > 0 and orders.coupon_code = 'bulk' and requested_production_on between :start and :end#{confirmed}", 
      {:start => Time.now, :end => Time.now+2.days}]
    elsif params[:id] == 'vip' 

	vip_condition = Order.vip_condition

      where= "#{where_printer} #{vip_condition} AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["#{where_printer} #{vip_condition}  AND orders.status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' #{confirmed}"]
    elsif params[:id] == 'checkout_errors' 

	checkout_err_cond = " orders.confirmed = 0 AND orders.nb_checkout_errors "

      where= " #{checkout_err_cond} "
      where_bulk= [" #{checkout_err_cond} AND orders.coupon_code = 'bulk'"]
    elsif params[:id] == 'rush' 
      where= "#{where_printer} orders.rush_order = 1 AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["#{where_printer} orders.rush_order = 1 AND orders.status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' #{confirmed}"]
    elsif params[:id] == 'single' 
	cond_single = " AND NOT EXISTS (SELECT * FROM ordered_products p1, ordered_products p2 WHERE p1.order_id = orders.id AND p2.order_id = orders.id AND p1.id <> p2.id AND p1.is_extra_garment = 0 AND p1.coupon_id = 0 AND p2.coupon_id = 0 AND p2.is_extra_garment = 0) "
      where= "#{where_printer} orders.status NOT IN #{inactive_order_statuses} #{confirmed} #{cond_single}"
      where_bulk= ["#{where_printer} orders.status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' #{confirmed} #{cond_single}"]
    elsif params[:id] == 'reproduction' 
	cond = " AND orders.is_reproduction "
      where= "#{where_printer} orders.status NOT IN #{inactive_order_statuses} #{confirmed} #{cond}"
      where_bulk= ["#{where_printer} orders.status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' #{confirmed} #{cond}"]
    elsif params[:id] == 'decal_orders' 

	cond = " AND EXISTS(SELECT * FROM models m2 WHERE m2.id = ordered_products.model_id AND m2.custom_store_type LIKE 'wall_%%') "

      where= "#{where_printer} orders.status NOT IN #{inactive_order_statuses} #{confirmed} #{cond}"
      where_bulk= ["#{where_printer} orders.status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' #{confirmed} #{cond}"]
    elsif params[:id] == 'gift_certificates'
      inactive_order_statuses = "(#{SHIPPING_TYPE_ON_HOLD}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_TO_CHECK})"
	cond = " AND EXISTS(SELECT * FROM ordered_products op WHERE op.order_id = orders.id AND op.coupon_id > 0)"
      where= "#{where_printer} orders.status NOT IN #{inactive_order_statuses} #{confirmed} #{cond}"
      where_bulk= ["#{where_printer} orders.status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' #{confirmed} #{cond}"]
    elsif params[:id] == '7_days' 
      where= "#{where_printer} DATEDIFF(CURDATE(), orders.created_on) > 7 AND DATEDIFF(CURDATE(), orders.created_on) <= 15 AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["1 = 0"]
    elsif params[:id] == '15_days' 
      where= "#{where_printer} (DATEDIFF(CURDATE(), orders.created_on) > 15) AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["1 = 0"]
    elsif params[:id] == '24h_shirt' 

	shirt_24_h_condition = Order.is_24_hours_order_condition

      where= "#{where_printer} #{shirt_24_h_condition} AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["1 = 0"]
    elsif params[:id] == '24h_non_white' 

	shirt_24_h_condition = Order.is_24_hours_non_white_order_condition

      where= "#{where_printer} #{shirt_24_h_condition} AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["1 = 0"]
    elsif params[:id] == '24h_true_black' 

	shirt_24_h_condition = Order.is_24_hours_true_black_order_condition

      where= "#{where_printer} #{shirt_24_h_condition} AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["1 = 0"]
    elsif params[:id] == 'non_canada_or_us' 

	condition = "NOT EXISTS(SELECT * FROM addresses a, countries c WHERE a.id = orders.shipping_address AND a.country_id = c.id AND c.name IN('Canada', 'United-States'))"

      where= "#{where_printer} #{condition} AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk= ["1 = 0"]
    elsif params[:id] == "without_print"
      where = "#{where_printer} orders.created_on BETWEEN '#{params[:start]}' AND '#{params[:end]}' #{confirmed} #{contains_print_condition} AND orders.status NOT IN #{inactive_order_statuses}"
      where_bulk = ["#{where_printer} orders.created_on BETWEEN '#{params[:start]}' AND '#{params[:end]}' AND orders.coupon_code = 'bulk' #{contains_print_condition} and requested_production_on between :prod_start and :prod_end#{confirmed} AND orders.status NOT IN #{inactive_order_statuses}",
        {:prod_start => Time.now, :prod_end => Time.now+2.days}]
    elsif params[:id] == 'artwork_required'
      where = "#{where_printer}artwork_sent = 0 #{order_condition_without_artwork_problem()} #{confirmed} AND orders.status NOT IN #{inactive_order_statuses}"
      where_bulk = ["#{where_printer}artwork_sent = 0 #{order_condition_without_artwork_problem()} and orders.coupon_code = 'bulk' and requested_production_on between :start and :end#{confirmed} AND orders.status NOT IN #{inactive_order_statuses}",
        {:start => Time.now, :end => Time.now+2.days}]
    elsif params[:id] == 'untreated_orders'
      where = "#{where_printer} status NOT IN #{inactive_order_statuses} #{confirmed} AND CAST(NOW() AS DATE) >= CAST(updated_at + INTERVAL 7 DAY AS DATE)"
      where_bulk = ["#{where_printer} orders.coupon_code = 'bulk' AND status NOT IN #{inactive_order_statuses} #{confirmed} AND CAST(NOW() AS DATE) >= CAST(updated_at + INTERVAL 7 DAY AS DATE)"]
    elsif params[:id] == 'artwork_required_problem'
      where = "#{where_printer}artwork_sent = 0 AND ((EXISTS (#{order_condition_rejected_ordered_zones()})) OR orders.artwork_required_problem = 1) #{confirmed} AND orders.status NOT IN #{inactive_order_statuses}"
      where_bulk = ["#{where_printer}artwork_sent = 0 AND ((EXISTS (#{order_condition_rejected_ordered_zones()})) OR orders.artwork_required_problem = 1) and orders.coupon_code = 'bulk' and requested_production_on between :start and :end#{confirmed} AND orders.status NOT IN #{inactive_order_statuses}",
        {:start => Time.now, :end => Time.now+2.days}]
    elsif params[:id] == 'bulk'
      where = "#{where_printer} orders.coupon_code = 'bulk' AND orders.status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk = ["1 = 0"]
    elsif params[:id] == 'bulk_unpaid'
      where = "#{where_printer}(bulk_amount_paid is null or sales_price is null or bulk_amount_paid < sales_price) and orders.coupon_code = 'bulk'#{confirmed}"
      where_bulk = ["#{where_printer}bulk_amount_paid < sales_price and orders.coupon_code = 'bulk' and orders.coupon_code = 'bulk' and requested_production_on between :start and :end#{confirmed}",
        {:start => Time.now, :end => Time.now+2.days}]
    elsif params[:id]
      where = "#{where_printer}status  = #{params[:id]} #{confirmed}"
      where_bulk = ["#{where_printer}status  = :status and orders.coupon_code = 'bulk' and requested_production_on between :start and :end#{confirmed}", 
        {:status => params[:id], :start => Time.now, :end => Time.now+2.days}]
    else
      where = "#{where_printer}status NOT IN #{inactive_order_statuses} #{confirmed}"
      where_bulk = ["#{where_printer}status NOT IN #{inactive_order_statuses} and orders.coupon_code = 'bulk' and requested_production_on between :start and :end#{confirmed}",
        {:start => Time.now, :end => Time.now+2.days}]
    end

    if force_order != "" && ! params[:search_order]
      order = force_order
    elsif params[:search_order]
      order = params[:search_order]
    else
      order = '(orders.critical = 1 OR orders.xmas = 1 OR orders.rush_order = 1) DESC, orders.created_at DESC'
      
      if params[:id] == 'artwork_required' || params[:id] == 'artwork_required_problem'
        order = default_artwork_order_list_order()
      end
    end

    @flagged_bulk = Order.find(:all, :include => includes, :conditions => where_bulk, :order => order)
    
    session[:search_where_criteria] = where
    
    @orders = Order.paginate :per_page => 100-@flagged_bulk.size, :include=>includes, :conditions => where, :order => order, :page => params[:page]

    @flagged_bulk.each {|bulk|@orders.delete(bulk)}

    session[:current_order_listing] = params[:id]
  end
  
  def execute_search_order()
    
    extra_search = "AND (#{session[:search_where_criteria]})" if session[:search_where_criteria]
    
    if self.class.name == "Admin::OrderController" || self.class.name == "Admin::ArtworkController"
      extra_search = ""
    end
    
    includes = [:user]
    
    if params[:search] && params[:search] != ''
      
      # remove accents:
      params[:search] = remove_accents(params[:search].to_s)
      
      #Search by status
      if params[:search_status] && params[:search_status] != 'all'
        status = "confirmed = true and orders.status = #{params[:search_status]} and "
      else
        status = "confirmed = true and "
      end

      #Search by ID
      if params[:search_field] == 'id'
        where = ["#{status}orders.id = :search_term #{extra_search}", {:search_term => params[:search] }]
      
      #Search by name
      elsif params[:search_field] == 'name'
        where = ["#{status}(users.username like :search_term OR users.firstname like :search_term OR users.lastname like :search_term OR CONCAT_WS(' ',users.firstname, users.lastname) like :search_term OR EXISTS (SELECT * FROM addresses ad WHERE ad.id = orders.billing_address AND ad.name LIKE :search_term) OR EXISTS (SELECT * FROM addresses ad WHERE ad.id = orders.shipping_address AND ad.name LIKE :search_term) ) #{extra_search}", 
          {:search_term => '%' + params[:search] + '%'}]
      
      #Search by Email
      elsif params[:search_field] == 'email'
        where = ["#{status} (users.email like :search_term OR orders.guest_email LIKE :search_term) #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]

      #Search by payment trans
      elsif params[:search_field] == 'payment_transaction'
        where = ["#{status} (payment_transaction LIKE '%%#{params[:search]}%%' OR paypal_transaction LIKE '%%#{params[:search]}%%') #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
      
      #Search by Shipping Name
      elsif params[:search_field] == 'shipping'
        where = ["#{status}addresses.name like :search_term #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
        includes << :shipping
        
      #Search by Shipping Province        
      elsif params[:search_field] == 'province'        
        where = ["#{status}(addresses.province_name like :search_term or provinces.name like :search_term) #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
          includes << {:shipping => :province}
      
      #Search by Shipping Country
      elsif params[:search_field] == 'country'
        where = ["#{status}(addresses.country_name like :search_term or countries.name like :search_term) #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
          includes << {:shipping => :country}

      #Search by Billing Name
      elsif params[:search_field] == 'billing'
        where = ["#{status}addresses.name like :search_term #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
        includes << :billing
      
      #Search by created date
      elsif params[:search_field] == 'created'
        where = ["#{status}created_on between :start and :end #{extra_search}", 
          {:start => params[:search].to_date, :end => params[:search].to_date}]
        
      #Search by shipped date
      elsif params[:search_field] == 'shipped'
        where = ["#{status}shipped_on between :start and :end #{extra_search}", 
          {:start => params[:search].to_date, :end => params[:search].to_date}]
        
      #Search by assigned on date
      elsif params[:search_field] == 'assigned'
        where = ["#{status}assigned_on between :start and :end #{extra_search}", 
          {:start => params[:search].to_date, :end => params[:search].to_date+1.days}]

      #Search by printer
      elsif params[:search_field] == 'printer'
        where = ["#{status}users.username like :search_term #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
        includes = [:assigned_to]
        
      #Search by comment
      elsif params[:search_field] == 'comment'
        where = ["#{status}comments.comment like :search_term #{extra_search}",
          {:search_term => '%' + params[:search] + '%'}]
        includes << :comments
      end
    end
    
    order = (params[:search_order]) ? params[:search_order] : 'orders.id DESC' 

    @orders = Order.paginate :per_page => 100, :include=>includes, :conditions => where, :page => params[:page], :order => order
  end
  
  def prepare_order_show

    params[:page] = (params[:page] && params[:page] != "") ? params[:page].to_i : 1

    if params[:page] < 1
	params[:page] = 1
    end

    @order = Order.find(params[:id], :conditions => ["(confirmed = true) OR (nb_checkout_errors > 0 AND confirmed = false)"])

    page = params[:page] ? params[:page].to_i : 1

    @ordered_products = @order.ordered_products.paginate(:page => page, :per_page => 10)
    
    @printers = [["No printer", 0]]
    @printers += User.find_all_by_user_level_id(5, :select => "id, username", :order => "username LIKE 'izishirt%%' DESC").map{|p| [p.username, p.id]}
    @Comments = Comment.find_all_by_order_id(params[:id], :order => "date_time DESC")
    @shipping_type = get_shipping_type_string(@order.shipping_type)
    @shipping_types = []


    SHIPPING_FULL_NAMES.each_index { |i| @shipping_types << [SHIPPING_FULL_NAMES[i],i] }
    
    begin
      assignment = ArtworkOrderAssignment.find_by_order_id(@order.id)
    rescue
      assignment = nil
    end

    @nb_tshirts, @nb_artworks = Admin::OrderController.calculate_order_statistics(@order)
    
    @nb_max_comments = 10
    @select_nb_comments = (1..@nb_max_comments).map { |n| [n, n] }
        
    
  end
  

  def get_shipping_type_string(shipping_type_num)
    begin
      ret = SHIPPING_FULL_NAMES[shipping_type_num]
    rescue
      ret=t(:admin_na)
    end
  end
  
  def prepare_for_order_print
    @order = Order.find(params[:id], :conditions => ["confirmed = true"])

    page = params[:page] ? params[:page].to_i : 1

    @ordered_products = @order.ordered_products.paginate(:page => page, :per_page => 10)

    @adr = Address.find(@order.shipping_address)
    @bill_adr = Address.find(@order.billing_address)
    @Comments = Comment.find_all_by_order_id(params[:id], :order => "date_time DESC")
    @shipping_type = get_shipping_type_string(@order.shipping_type)

   
    
    @nb_tshirts, @nb_artworks = Admin::OrderController.calculate_order_statistics(@order)
  end
  
  def condition_orders_in_printer_assignment_process
    
    return "orders.status = #{SHIPPING_TYPE_PENDING} AND orders.printer = 0 AND orders.confirmed = 1 " +
    
      # NO BACK ORDERS:
      "AND NOT EXISTS (SELECT * FROM ordered_products p2 WHERE orders.id = p2.order_id AND p2.in_back_order = 1) " +
      
      # NO ARTWORK PROBLEM:
      "#{order_condition_without_artwork_problem()}"
  end
  
  def prepare_new_order_show(init, model_id = nil, model_other = nil, order = nil, color_id = nil, model_size_id = nil)
    
    cond_models = "localized_models.language_id = #{session[:language_id]} and active = 1"
    
#    if order
#      order.ordered_products.each do |product|
#
#	      if product.coupon
#		      next
#	      end
#
#        cond_models += " OR models.id = #{product.model_id}"
#      end
#    end
    
    # @models = Model.find(:all, 
     #                    :include => :localized_models,
     #                    :order => 'localized_models.name',
     #                    :conditions => [cond_models]).map { |model| [model.name(session[:language_id]), model.id] }
    
    if model_other != nil && model_other != "" && model_other != "Other"
      
      #tmp_colors = Color.find_all_by_color_type_id(3).select { |color| color.active }
      
   #   @colors = tmp_colors.map{|color| [color.local_name(session[:language_id]), color.id]}
      
    #  @sizes = []
    else
      
      model_specs = ModelSpecification.find_all_by_model_id(model_id)
      
     # tmp_colors = model_specs.select { |spec|  ((spec.color.active && spec.color.color_type_id == 3)) }
    #  @colors = tmp_colors.map { |spec| [spec.color.local_name(session[:language_id]), spec.color.id] }
      
      model_sizes = ModelSizeSpec.find_all_by_model_id(model_id)
      @sizes = [] 
      if model_id
        @sizes |= Model.find(model_id).model_sizes.map{|model_size|
          [model_size.local_name(I18n.locale), model_size.id]
        }
      end
    end
    
    if init == "true"
    
      if color_id
        color_found = false
        
        @colors.each do |cur_color|
          if cur_color[1] == color_id
            color_found = true
            break
          end
        end
        
        if ! color_found
          begin
            color = Color.find(color_id)
            
            @colors << [color.local_name(session[:language_id]), color.id]
          rescue
          end
        end
      end
      
      if model_size_id
        size_found = false
        
        @sizes.each do |cur_size|
          if cur_size[1] == model_size_id
            size_found = true
            break
          end
        end
        
        if ! size_found
          size = ModelSize.find(model_size_id)
          
          @sizes << [size.local_name(I18n.locale), size.id]
        end
      end
    end
    
    @comment_types = [["Choose comment type", "no_type"], ["Admin", "administrator"], ["Admin (internal)", "administrator_internal"]]
    
    if @connected_staff
      @comment_types << ["Artwork members", "artwork"]
    end
    
    
  end
  

	# INVOICES

	def prepare_generate_quote_pdf(calculation_id = params[:id], shipping_cost = params["generate_pdf_#{calculation_id}"][:shipping_cost], shipping_comment = params["generate_pdf_#{calculation_id}"][:shipping_comment], payment_comment = params["generate_pdf_#{calculation_id}"][:payment_comment], mock_up_cost = params["generate_pdf_#{calculation_id}"][:mock_up_cost], pdf_type = params["generate_pdf_#{calculation_id}"][:type_pdf_generation], province_id = params["generate_pdf_#{calculation_id}"][:province], international = params["generate_pdf_#{calculation_id}"][:international], terms = params["generate_pdf_#{calculation_id}"][:terms], unknown_sizes = params["generate_pdf_#{calculation_id}"][:unknown_size])

		@pdf_type = pdf_type

		if @pdf_type == "order_now"
			return
		end

		if unknown_sizes == "1"
			unknown_sizes = true
		end

		if ! unknown_sizes
			unknown_sizes = false
		end

		prepare_invoice(calculation_id.to_i, shipping_cost.to_f, mock_up_cost.to_f, @pdf_type, province_id, international, terms, shipping_comment, payment_comment, unknown_sizes)


	    quote_to_string = render_to_string :template => "/admin/bulk_orders/generate_quote_html", :layout => false
	    
	    @invoice = nil 
	    
	    if @invoice.nil?
	      @invoice = QuoteCalculationInvoice.create(:quote_calculation_id => calculation_id)  
	    end
	    
	    # Generate HTML
	    f = File.open(@invoice.tmp_file(@pdf_type, "html"), 'w')
	    f.write(quote_to_string)
	    f.close
	    
	    if @pdf_type == "quote" || @pdf_type == "send_quote"
	      @invoice.quote_html = File.new(@invoice.tmp_file(@pdf_type, "html"))
	    elsif @pdf_type == "invoice" || @pdf_type == "send_invoice"
	      @invoice.invoice_html = File.new(@invoice.tmp_file(@pdf_type, "html"))
	    elsif @pdf_type == "invoice_comptability"
	      @invoice.invoice_comptability_html = File.new(@invoice.tmp_file(@pdf_type, "html"))
	    end
	    
	    @invoice.save
	    
	    system("wkhtmltopdf #{@invoice.tmp_file(@pdf_type, "html")} #{@invoice.tmp_file(@pdf_type, "pdf")}")
	    
	    @pdf_to_load = nil
	    
	    if @pdf_type == "quote" || @pdf_type == "send_quote"
	      @invoice.quote_pdf = File.new(@invoice.tmp_file(@pdf_type, "pdf"))
	      @pdf_to_load = @invoice.quote_pdf
	    elsif @pdf_type == "invoice" || @pdf_type == "send_invoice"
	      @invoice.invoice_pdf = File.new(@invoice.tmp_file(@pdf_type, "pdf"))
	      @pdf_to_load = @invoice.invoice_pdf
	    elsif @pdf_type == "invoice_comptability" || @pdf_type == "send_invoice_comptability"
	      @invoice.invoice_comptability_pdf = File.new(@invoice.tmp_file(@pdf_type, "pdf"))
	      @pdf_to_load = @invoice.invoice_comptability_pdf
	    end
	    
	    @invoice.save
		
	end

	def prepare_invoice(id = nil, shipping_cost = nil, mock_up_cost = nil, pdf_type = nil, province_id = nil, international = nil, 
		terms = nil, shipping_comment = nil, payment_comment = nil, unknown_sizes = false)
	    calculation_id = id ? id : params[:id]
	    @shipping_cost = shipping_cost ? shipping_cost : params[:shipping_cost].to_f
	    @mock_up_cost = mock_up_cost ? mock_up_cost : params[:mock_up_cost].to_f
	    @pdf_type = pdf_type ? pdf_type : params[:type_pdf_generation]
	    @province_id = province_id ? province_id : params[:province]
	    @international = international ? international : params[:international]
	    @shipping_comment = shipping_comment
	    @payment_comment = payment_comment
	    @terms = terms
	    @unknown_sizes = unknown_sizes
	    
	    @calculation = QuoteCalculation.find(calculation_id)

		@calculation.quote_products.each do |quote_product|

			quote_sizes_to_remove = []

			quote_product.quote_product_sizes.each do |quote_size|

				id_select = "calculation_#{@calculation.id}_product_#{quote_product.id}_quote_color_#{quote_size.quote_product_color.id}"

				if params[id_select] && params[id_select]["selected"].to_s != "true"
					quote_sizes_to_remove << quote_size
				end
			end

			quote_sizes_to_remove.each do |q_size|
				quote_product.quote_product_sizes.delete(q_size)
			end
		end

	    @bulk_order = @calculation.bulk_order
	    
	    begin
	      @order_id = @bulk_order.order.id
	    rescue
	      @order_id = "N/A"
	    end
	    
	    @title = (@pdf_type == "quote" || @pdf_type == "send_quote") ? I18n.t(:admin_bulk_order_generate_pdf_quotation, :locale => Language.find(@bulk_order.language_id).shortname) : I18n.t(:admin_bulk_order_generate_pdf_invoice, :locale => Language.find(@bulk_order.language_id).shortname) 
	    
	    begin
	      @billing_address = Address.find(@bulk_order.order.billing_address)
	    rescue
	      @billing_address = nil
	    end
	    
	    begin
	      @shipping_address = Address.find(@bulk_order.order.shipping_address)
	    rescue
	      @shipping_address = nil
	    end
	    
	    if @pdf_type == "quote"
	      # No shipping address
	      @shipping_address = nil
	      
	      # No shipping:
	      @shipping_cost = 0.0
	      
	      # No taxes
	      @province_id = -1 
	    end
	    
	    @sub_total = @calculation.final_sub_total(@shipping_cost)
	    
	    @taxes = @calculation.final_taxes(@shipping_cost)
	    
	    @total = @sub_total + @taxes
	end
	
	# END INVOICES
  def get_param_lang(country, language_id)
    if country == "CA" and language_id==2
      return ''
    elsif country == "CA" and language_id==1
      return 'fr'
    elsif country == "US"
    return 'us'
    end
  end

end
