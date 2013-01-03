class Order < ActiveRecord::Base
  after_save :insert_earnings
  before_save :set_packaged_date

	has_attached_file :invoice_html, :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id.:extension",
		:url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id.:extension"
  
	has_attached_file :invoice_pdf, :path => ":rails_root/public/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id.:extension",
		:url => "/izishirtfiles/:class/:year_created_on/:month_created_on/:day_created_on/:id/:id.:extension"


  belongs_to :product
  belongs_to :billing, :class_name => 'Address', :foreign_key => 'billing_address'
  belongs_to :shipping, :class_name => 'Address', :foreign_key => 'shipping_address'
  belongs_to :user
  belongs_to :refering_user, :class_name => 'User'
  belongs_to :referer
  belongs_to :currency, :foreign_key => 'curency_id'
  belongs_to :language
  has_many :order_shipping_histories

  has_one :refering_user_credit
  
  named_scope :flagged, :conditions=>"comment_type > 0"
  named_scope :upcoming, :conditions=>"artwork_sent = 0 and status = 0"
  named_scope :status
  named_scope :printer_id, lambda {|printer_id|
      {
          :include=>[:user],
          :conditions => "printer = #{printer_id}",
          :order => 'orders.critical DESC, orders.xmas DESC, orders.id DESC'
      }
  }
  named_scope :nextshirt, 
              :include=>[:user],
              :conditions => "printer = 2610 AND orders.assigned_on is not null",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.id DESC'

  named_scope :pending,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 0 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :awaiting_stock,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 4 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :batching,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 3 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :processing,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 1 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :packaging,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 6 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :shipped,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_SHIPPED} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :canceled,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_CANCELED} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :canceled_coupon,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_CANCELED_COUPON} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :partially_shipped,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_PARTIALLY_SHIPPED} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :mock_up,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_MOCK_UP} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :to_check,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_TO_CHECK} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :back_order,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_BACK_ORDER} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :on_hold,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 7 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :art_on_hold,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 9 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :checkout_errors,
              :include => [:user],
              :conditions => 'confirmed = 0 AND nb_checkout_errors > 0',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :printed,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => 'status = 8 and confirmed = 1',
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :artwork_required,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "artwork_sent = 0 AND NOT EXISTS (SELECT * FROM ordered_products op, ordered_zones oz WHERE op.id = oz.ordered_product_id AND op.order_id = orders.id AND oz.pending_approval = #{DESIGN_VALIDATION_STATE_DECLINED_ID}) AND orders.artwork_required_problem = 0 AND confirmed = 1 AND orders.status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_TO_CHECK})",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :artwork_required_problem,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "artwork_sent = 0 AND (EXISTS (SELECT * FROM ordered_products op, ordered_zones oz WHERE op.id = oz.ordered_product_id AND op.order_id = orders.id AND oz.pending_approval = #{DESIGN_VALIDATION_STATE_DECLINED_ID}) OR orders.artwork_required_problem = 1) AND confirmed = 1 AND orders.status NOT IN (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_TO_CHECK})",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
named_scope :awaiting_payment,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = 10 and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
named_scope :awaiting_artwork,
              :include => [:user, {:ordered_products=>:ordered_zones}],
              :conditions => "status = #{SHIPPING_TYPE_AWAITING_ARTWORKS} and confirmed = 1",
              :order => 'orders.critical DESC, orders.xmas DESC, orders.rush_order DESC, orders.id DESC'
  named_scope :untreated_orders,
    :conditions => "status NOT IN(#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_TO_CHECK}) and confirmed = 1 AND CAST(NOW() AS DATE) >= CAST(updated_at + INTERVAL 7 DAY AS DATE)"

  has_many :ordered_products
  has_many :order_histories
  has_many :comments
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'printer'
  belongs_to :shipping_company
  has_many :artwork_order_assignments

  # not used anymore, all in comments with comment type
  #has_many :order_artwork_department_comments

  belongs_to :bulk_order
  has_many :order_garment_listing_products
  has_many :order_user_read_all_comments
  has_many :order_email_histories
  has_many :order_payments, :order => "created_at DESC"

  has_attached_file :prints,
                    :url  => "/izishirtfiles/order_prints/:id/:basename.:extension",
                    :path => ":rails_root/public/izishirtfiles/order_prints/:id/:basename.:extension"

  validate do |order|
    order.validate_order
  end

	def contains_fast_shipping_models
		ordered_products.each do |op|
			if op.coupon_id > 0 || op.is_extra_garment
				next
			end

			begin
				if op.model.fast_shipping
					return true
				end
			rescue
			end
		end

		return false
	end

	def order_to_check_because_supplier
		ordered_products.each do |op|

			if op.coupon_id > 0 || op.is_extra_garment
				next
			end

			begin
				if op.real_apparel_supplier.name != "Technosport"
					return false
				end
			rescue
			end
		end

		return nb_tshirts_with_prints == 0
	end

	def calc_real_shipping_cost

		c = 0.0

		order_shipping_histories.each do |sh|
			c += sh.total_cost
		end

		return c
	end

	def already_paid?
		if true_amount_paid && true_amount_paid > 0.0 && (total_price >= true_amount_paid - 0.5 && total_price <= true_amount_paid + 0.5)
			return true
		end

		return false
	end

	def coupon_order?

				return false


	end

	def amount_to_affiliates
		total = 0.0

		ordered_products.each do |prod|

			if prod.coupon
				next
			end
	
			begin
				total += prod.commission * prod.quantity

				prod.ordered_zones.each do |oz|
					oz.ordered_zone_artworks.each do |artwork|
						if artwork.image && artwork.image.user && prod.purchase_source_id != 5 && artwork.image.user.earnings_per_image > 0
							total += oz.ordered_product.quantity * artwork.image.user.earnings_per_image
						end
					end
				end
			rescue
			end
		end

		return total
	end

	def affiliates

		l = []

		ordered_products.each do |product|

			if product.coupon
				next
			end

			begin
				product.earnings.find(:all, :conditions => ["earning_type IN ('Image', 'Commission')"]).each do |earning|
					l << earning.user
				end

				product.ordered_zones.each do |zone|
					zone.earnings.find(:all, :conditions => ["earning_type IN ('Image', 'Commission')"]).each do |earning|
						l << earning.user
					end
				end
			rescue
			end
		end
		
		return l.uniq
	end

	def garments_cost_price
		total = 0.0

		begin
			ordered_products.each do |prod|
				if prod.is_extra_garment || prod.coupon
					next
				end

				total += (prod.cost_price.to_f * prod.quantity.to_f)
			end
		rescue Exception => e
		end

		return total
	end

	def detailed_garments_cost_price
		# detailed_cost_price_with_color_id(model_size_id, color_id)
		total = 0.0

		begin
			ordered_products.each do |prod|
				if prod.is_extra_garment || prod.coupon
					next
				end

				total += (prod.model.detailed_cost_price_with_color_id(prod.model_size_id, prod.color_id).to_f * prod.quantity.to_f)
			end
		rescue Exception => e
		end

		return total
	end

	def self.nb_orders_closed_of(seller_id, date_begin, date_end)
		return Order.count(:conditions => ["((user_id = #{seller_id} AND orders.total_price > 70) OR EXISTS (SELECT * FROM bulk_orders WHERE orders.bulk_order_id = bulk_orders.id AND bulk_orders.seller = #{seller_id})) AND created_on BETWEEN '#{date_begin}' AND '#{date_end}'"])
	end


	def year_created_on
		return created_on.year
	end

	def month_created_on
		return created_on.month
	end

	def day_created_on
		return created_on.day
	end

	def mail_country

		c = nil

		begin
			if user.username != "guest"
				c = Country.find_by_shortname(user.country)
			else
				c = billing.country
			end
		rescue
		end

		if ! c
			c = Country.find_by_shortname("CA")
		end

		return c
	end

	def name
		begin
			return billing.name
		rescue
		end

		begin
			if user.username != "guest"
				return "#{firstname} #{lastname}"
			end
		rescue
		end

		return "Izishirt client"
	end

  def self.order_statuses(lang)
    [I18n.t(:order_status_0, :locale => lang),
     I18n.t(:order_status_1, :locale => lang),
     I18n.t(:order_status_2, :locale => lang),
     I18n.t(:order_status_3, :locale => lang),
     I18n.t(:order_status_4, :locale => lang),
     I18n.t(:order_status_5, :locale => lang),
     I18n.t(:order_status_6, :locale => lang),
     I18n.t(:order_status_7, :locale => lang),
     I18n.t(:order_status_8, :locale => lang),
     I18n.t(:order_status_9, :locale => lang),
     I18n.t(:order_status_10, :locale => lang),
     I18n.t(:order_status_11, :locale => lang),
     I18n.t(:order_status_12, :locale => lang),
     I18n.t(:order_status_13, :locale => lang),
     I18n.t(:order_status_14, :locale => lang),
     I18n.t(:order_status_15, :locale => lang),
     I18n.t(:order_status_16, :locale => lang)]
  end

  def self.order_statuses_for_select(lang)
    Order.order_statuses(lang).map{|status|[status,Order.order_statuses(lang).index(status)]}
  end

  def self.order_status_explanations(lang)
    [I18n.t(:order_status_explanation_0, :locale => lang),
     I18n.t(:order_status_explanation_1, :locale => lang),
     I18n.t(:order_status_explanation_2, :locale => lang),
     I18n.t(:order_status_explanation_3, :locale => lang),
     I18n.t(:order_status_explanation_4, :locale => lang),
     I18n.t(:order_status_explanation_5, :locale => lang),
     I18n.t(:order_status_explanation_6, :locale => lang),
     I18n.t(:order_status_explanation_7, :locale => lang),
     I18n.t(:order_status_explanation_8, :locale => lang),
     I18n.t(:order_status_explanation_9, :locale => lang),
     I18n.t(:order_status_explanation_10, :locale => lang),
     I18n.t(:order_status_explanation_11, :locale => lang),
     I18n.t(:order_status_explanation_12, :locale => lang),
     I18n.t(:order_status_explanation_13, :locale => lang),
     I18n.t(:order_status_explanation_14, :locale => lang),
     I18n.t(:order_status_explanation_15, :locale => lang),
     I18n.t(:order_status_explanation_16, :locale => lang)]
  end

	def shipping_histories
		return order_histories.find(:all, :conditions => ["order_histories.attribute = 'status' AND order_histories.to_value IN (#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_PARTIALLY_SHIPPED})"])
	end

	def has_artwork_problem

		if artwork_required_problem
			return true
		end

		ordered_products.each do |op|
			op.ordered_zones.each do |zone|
				if zone.pending_approval == DESIGN_VALIDATION_STATE_DECLINED_ID
					return true
				end
			end
		end

		return false
	end

	def tmp_invoice(format)
		return "/tmp/order_#{id}_invoice.#{format}"
	end


  def self.daily_offline_sales(date)
    where = ["confirmed=? and (users.id = ? OR users.user_level_id = ?) and status NOT IN (?)  and created_on=?", 
      true, 
      70,
      UserLevel.find_by_name("Izishirt Seller").id,
      [SHIPPING_TYPE_CANCELED,SHIPPING_TYPE_CANCELED_COUPON,SHIPPING_TYPE_TO_CHECK,SHIPPING_TYPE_AWAITING_PAYMENT],
      date.beginning_of_day]     

    @orders = Order.sum(:total_price, :conditions => where, :include => [:user])
  end

  def self.monthly_offline_sales(date)
    where = ["confirmed=? and (users.id = ? OR users.user_level_id = ?) and status NOT IN (?)  and created_on between ? and ?", 
      true, 
      70,
      UserLevel.find_by_name("Izishirt Seller").id,
      [SHIPPING_TYPE_CANCELED,SHIPPING_TYPE_CANCELED_COUPON,SHIPPING_TYPE_TO_CHECK,SHIPPING_TYPE_AWAITING_PAYMENT],
      date.beginning_of_month, date.end_of_month]     

    @orders = Order.sum(:total_price, :conditions => where, :include => [:user])
  end

  def self.daily_online_sales(date)
    where = ["confirmed=? and users.id <> ? AND users.user_level_id <> ? and status NOT IN (?)  and created_on=?", 
      true, 
      70,
      UserLevel.find_by_name("Izishirt Seller").id,
      [SHIPPING_TYPE_CANCELED,SHIPPING_TYPE_CANCELED_COUPON,SHIPPING_TYPE_TO_CHECK,SHIPPING_TYPE_AWAITING_PAYMENT],
      date.beginning_of_day]     

    @orders = Order.sum(:total_price, :conditions => where, :include => [:user])
  end

  def self.monthly_online_sales(date)
    where = ["confirmed=? and users.id <> ? AND users.user_level_id <> ? and status NOT IN (?)  and created_on between ? and ?", 
      true, 
      70,
      UserLevel.find_by_name("Izishirt Seller").id,
      [SHIPPING_TYPE_CANCELED,SHIPPING_TYPE_CANCELED_COUPON,SHIPPING_TYPE_TO_CHECK,SHIPPING_TYPE_AWAITING_PAYMENT],
      date.beginning_of_month, date.end_of_month]     

    @orders = Order.sum(:total_price, :conditions => where, :include => [:user])
  end

  def self.all_daily_sales(date)
    where = ["confirmed=? and status NOT IN (?)  and created_on=?", 
      true, 
      [SHIPPING_TYPE_CANCELED,SHIPPING_TYPE_CANCELED_COUPON,SHIPPING_TYPE_TO_CHECK,SHIPPING_TYPE_AWAITING_PAYMENT],
      date.beginning_of_day]     

    @orders = Order.sum(:total_price, :conditions => where, :include => [:user])
  end

  def self.all_monthly_sales(date)
    where = ["confirmed=? and status NOT IN (?)  and created_on between ? and ?", 
      true, 
      [SHIPPING_TYPE_CANCELED,SHIPPING_TYPE_CANCELED_COUPON,SHIPPING_TYPE_TO_CHECK,SHIPPING_TYPE_AWAITING_PAYMENT],
      date.beginning_of_month, date.end_of_month]     

    @orders = Order.sum(:total_price, :conditions => where, :include => [:user])
  end

	def margin
		tmp_garment_cost = 0.0
		tmp_shipping_cost = 0.0

		if shipping_cost && shipping_cost > 0
			tmp_shipping_cost = shipping_cost
		else
			# ok recalculate it... ERF, why O why
			tmp_shipping_cost = Order.estimate_shipping(self)
		end

		if garment_cost && garment_cost > 0
			tmp_garment_cost = garment_cost
		else
			ordered_products.each do |prod|
				if prod.is_extra_garment || prod.coupon
					next
				end

				tmp_garment_cost = prod.model.detailed_cost_price_with_color_id(prod.model_size_id, prod.color_id) * prod.quantity
			end
		end

		if printer == User.find_by_username("izishirtscreen").id
			# ((total / 2) - ship) * 0.15
			return ((total_price / 2.0) - tmp_shipping_cost)
		elsif printer == User.find_by_username("izishirtkornit").id
			# total - (2.5 par print + garment + shipping)
			return total_price - (nb_prints.to_f * 3.5 + tmp_garment_cost + tmp_shipping_cost)
		elsif printer == User.find_by_username("izishirtbrother").id
			# total - (3.5 par print + garment + shipping)
			return total_price - (nb_prints.to_f * 2.5 + tmp_garment_cost + tmp_shipping_cost)
		else
			return total_price - (print_cost + garment_cost + shipping_cost)
		end

		return 0.0
	end

	def self.is_24_hours_order_condition()
		return "NOT EXISTS (SELECT * FROM ordered_products op, models WHERE orders.id = op.order_id AND models.id = op.model_id AND (models.is_express_shipping = 0 OR (models.express_shipping_active_since IS NULL OR orders.created_at < models.express_shipping_active_since))) AND " +
			"NOT EXISTS (SELECT * FROM ordered_products op, colors, localized_colors WHERE orders.id = op.order_id AND op.color_id = colors.id AND localized_colors.color_id = colors.id AND localized_colors.language_id = 2 AND (localized_colors.name NOT IN ('white', 'White')))"
	end

	def self.is_24_hours_non_white_order_condition()
		return "NOT EXISTS (SELECT * FROM ordered_products op, models WHERE orders.id = op.order_id AND models.id = op.model_id AND (models.is_express_shipping = 0 OR (models.express_shipping_active_since IS NULL OR orders.created_at < models.express_shipping_active_since))) AND " +
			"EXISTS (SELECT * FROM ordered_products op, colors, localized_colors WHERE orders.id = op.order_id AND op.color_id = colors.id AND localized_colors.color_id = colors.id AND localized_colors.language_id = 2 AND (localized_colors.name NOT IN ('white', 'White')))"
	end

	def self.is_24_hours_true_black_order_condition()
		return "NOT EXISTS (SELECT * FROM ordered_products op, models WHERE orders.id = op.order_id AND models.id = op.model_id AND (models.id NOT IN (155, 156, 69) OR models.is_express_shipping = 0 OR (models.express_shipping_active_since IS NULL OR orders.created_at < models.express_shipping_active_since))) AND " +
			"EXISTS (SELECT * FROM ordered_products op, colors, localized_colors, models WHERE op.model_id = models.id AND models.id IN (155, 156, 69) AND orders.id = op.order_id AND op.color_id = colors.id AND localized_colors.color_id = colors.id AND localized_colors.language_id = 2 AND (localized_colors.name IN ('black', 'Black')))"
	end


	def self.is_24_hours_order(products)
		products.each do |op|

			if ! op.model
				next
			end

			begin
				if ! op.model.is_express_shipping || ! (op.model.express_shipping_active_since && op.order.created_at >= op.model.express_shipping_active_since)
					return false
				end
			rescue
			end
		end

		return true
	end

	def self.all_white(products)
		products.each do |op|

			if op.coupon
				next
			end

			if ! op.color
				next
			end

			if op.color.local_name(2).downcase != "white"
				return false
			end
		end

		return true
	end

	def is_pick_up_order?
		return [SHIPPING_PICKUP, SHIPPING_RUSH_PICKUP].include?(shipping_type)
	end

  def validate_order

  end


	def total_oz_weight
		total = 0.0

		ordered_products.each do |prod|

			if prod.coupon
				next
			end

			total += prod.oz_weight
		end

		return total
	end	

	def total_lbs_weight
		return (total_oz_weight.to_f / 16.0).round(2)
	end


	def amount_paid
		ap = 0.0

		begin

			order_payments.each do |payment|
				ap += payment.amount
			end
		rescue
			ap = 0.0
		end

		if ! ap || ap < 0.0
			return 0.0
		end

		return ap
	end

	def main_quote_calculator
		if ! bulk_order
			return nil
		end

		begin
			return QuoteCalculation.find(:first, :order => "id DESC", :conditions => ["bulk_order_id = #{bulk_order.id} AND user_id = #{printer}"])
		rescue => ex
			
		end

		return nil
	end
  
  def quote_calculator_margin
    begin
      calculus = main_quote_calculator
      
      return calculus.global_margin
    rescue
      
    end
    
    return -1
  end
  
  def has_follow_up
    if ! bulk_order?
      return false
    end
    
    begin
      return bulk_order.has_follow_up
    rescue
      
    end
    
    return true
  end
  
  def comment_type_str(a_comment_type)
    if a_comment_type == 1
      return "read"
    elsif a_comment_type == 2
      return "unread"
    end
    
    return ""
  end
  
  # returns read or unread
  def user_comments_state(current_user_id, is_printer = false)
    return "read"
    begin
      last_comment = Comment.find_by_order_id(id, :order => "date_time DESC")
      comments = Comment.find_all_by_order_id(id, :order => "date_time DESC")
      
      if is_printer && last_comment.internal && comments.length == 1
        return comment_type_str(1)
      end
    rescue
    end
    
    # First let's check order_user_read_all_comments
    comment_states = OrderUserReadAllComment.find_all_by_user_id_and_order_id(current_user_id, id)
    
    if comment_states.length == 0
      return comment_type_str(comment_type)
    end
    
    comment_state = comment_states[0]
    
    return comment_type_str(comment_state.comment_type)
  end
  
  def user_change_comments_state(current_user_id, new_comment_type)
    comment_states = OrderUserReadAllComment.find_all_by_user_id_and_order_id(current_user_id, id)
    
    if comment_states.length == 0
      OrderUserReadAllComment.create(:order_id => id, :user_id => current_user_id, :comment_type => new_comment_type)
    else
      comment_state = comment_states[0]
      
      comment_state.update_attributes(:comment_type => new_comment_type)
    end
  end
  
  def comment_type=(new_comment_type)
    

    
    super
  end

  def set_packaged_date
    packaged_on = Time.now if status.to_i == SHIPPING_TYPE_PACKAGING && packaged_on.nil?
  end
  
  def check_should_be_rush()
      rush_order = shipping_type == SHIPPING_EXPRESS || shipping_type == SHIPPING_RUSH || shipping_type == SHIPPING_RUSH_PICKUP
      
      if id
        order = Order.find(id)
        
        order.update_attributes(:rush_order => rush_order)
      end
  end
  
  def artwork_sent=(new_artwork_sent)
    
    new_artwork_sent = new_artwork_sent == "true" || new_artwork_sent == 1 || new_artwork_sent == true
    
    if id
      order = Order.find(id)
      
      # artwork sent changed !
      if new_artwork_sent != order.artwork_sent
        new_artwork_sent_on = (new_artwork_sent) ? DateTime.now : nil
        
        order.update_attributes(:artwork_sent_on => new_artwork_sent_on, :artwork_not_received => false)
        
        if new_artwork_sent
          

          # put status to BATCHING.
          if status != SHIPPING_TYPE_CANCELED && status != SHIPPING_TYPE_SHIPPED
            order.update_attributes(:status => SHIPPING_TYPE_BATCHING)
          end
        else
          # FROM artwork_sent TO artwork_sent = false
          order.update_attributes(:artwork_not_received => true)
          
          # Need to change related assignments from artworks_sent to artworks_ready


          # put status to AWAITING ARTWORKS
          if status != SHIPPING_TYPE_CANCELED && status != SHIPPING_TYPE_SHIPPED
            order.update_attributes(:status => SHIPPING_TYPE_AWAITING_ARTWORKS)
          end
        end
      end
    end
    
    super
  end

  def artwork_required_problem=(new_value)
    new_value = new_value == "true" || new_value == 1 || new_value == true

    if new_value && id
      order = Order.find(id)
      order.update_attributes(:status => SHIPPING_TYPE_ARTWORK_ON_HOLD)
    end

    super
  end

	def status=(new_status)
		begin
		if new_status && id
			order = Order.find(id)
			
			if [SHIPPING_TYPE_TO_CHECK, SHIPPING_TYPE_AWAITING_PAYMENT].include?(order.status) && new_status.to_i == SHIPPING_TYPE_PENDING
				order.update_attributes(:created_on => Date.today, :created_at => Time.current)
			end

			order.order_histories << OrderHistory.create({:order_id => order.id,
			    :attribute => "status",
			    :from_value => order.status.to_i.to_s,
			    :to_value => new_status.to_i.to_s, :user_id => 70})

			# remove reproduction if shipped
			order.update_attributes(:is_reproduction => false)
		end
		rescue
		end
		super
	end

	# we must change the company name for UPS.
	def pick_up=(new_pick_up_value)
		begin

			if (new_pick_up_value || new_pick_up_value == "1" || new_pick_up_value == "true") && !shipping.address1.match("Regus")
				shipping.update_attributes(:company_name => "HOLD FOR PICK UP AT UPS CENTER")
			elsif shipping.address1.match("Regus")# && (new_pick_up_value || new_pick_up_value == "1" || new_pick_up_value == "true")
				shipping.update_attributes(:company_name => "Izishirt")
      else
        shipping.update_attributes(:company_name => shipping.name)
      end

		rescue
		end

		super
	end

	def bulk_order_id=(new_bulk_order_id)

		begin
			new_bulk_order_id = new_bulk_order_id.to_i
		rescue
			new_bulk_order_id = 0
		end

		# make sure there not bunch of orders associated to this bulk order !!
		if new_bulk_order_id && new_bulk_order_id > 0
			begin
				orders_with_b = Order.find_all_by_bulk_order_id(new_bulk_order_id)

				orders_with_b.each do |order|
					begin
						order.update_attributes(:bulk_order_id => nil)
					rescue
					end
				end
			rescue
			end
		end

		super
	end

  def color_used(color_id)
    ordered_products.each do |product|

	if product.coupon
		next
	end

      if product.color_id == color_id
        return true
      end
    end
    
    return false
  end

  def subtotal
    
    if total_price.nil?
      update_attributes(:total_price => 0)
    end
    
    total_price - total_shipping - total_taxes
  end

  def original_price
    subtotal + coupon_discount
  end

	def is_vip_from_boutique_affiliate
		begin
			ordered_products.each do |o_product|

				if o_product.coupon
					next
				end

				if ! o_product.product_id
					return false
				end

				begin
					p = Product.find(o_product.product_id)
				rescue
					return false
				end

				if p && ! p.store.user.is_vip
					return false
				end
			end
		rescue
			return false
		end

		return true
	end

	def is_vip_from_coupon
		begin
			coupon = Coupon.find_by_code(coupon_code)

			return coupon.is_vip
		rescue
			return false
		end
	end

	def self.vip_condition(order = nil)
		cond = "1=0"

#		if order
#			cond_order += "orders.id = #{order.id} AND "
#		end
#
#		coupon_cond = " EXISTS (SELECT * FROM coupons WHERE code = orders.coupon_code AND is_vip = 1)"
#
#		boutique_cond = " ((SELECT COUNT(*) FROM ordered_products op, products p, stores, users u WHERE op.order_id = orders.id AND op.product_id = p.id AND p.store_id = stores.id AND stores.user_id = u.id AND u.is_vip = 1) > 0) OR (((SELECT COUNT(*) FROM ordered_products op, ordered_zones oz, ordered_zone_artworks art, images, users WHERE op.order_id = orders.id AND op.id = oz.ordered_product_id AND oz.id = art.ordered_zone_id AND art.image_id = images.id AND users.id = images.user_id AND users.is_vip = 1) > 0)) OR ((SELECT COUNT(*) FROM ordered_products op, users WHERE op.order_id = orders.id AND users.id = op.affiliate_user_id AND users.is_vip = 1) > 0) "
#
#		cond = "#{cond_order} (#{coupon_cond} OR #{boutique_cond})"

		return cond
	end

	def affiliate_username
		begin
			# in products
			ordered_products.each do |op|
				if op.affiliate_user_id && op.affiliate_user_id > 0
					return User.find(op.affiliate_user_id).username
				end
			end

			# affiliate
			ordered_products.each do |op|
				if op.product && op.product.store && op.product.store.user && op.product.store.user.is_vip
					return op.product.store.user.username
				end
			end

			# design
			ordered_products.each do |op|
				op.ordered_zones.each do |oz|
					oz.ordered_zone_artworks.each do |artwork|
						if artwork.image && artwork.image.user && artwork.image.user.is_vip
							return artwork.image.user.username
						end
					end
				end
			end
		rescue
		end

		return ""
	end

	def affiliate_artwork_comment
		username = affiliate_username

		if username && username != ""
			begin
				return User.find_by_username(username).custom_artwork_comment
			rescue
				return ""
			end
		end

		return ""
	end

	def affiliate_printer_comment
		username = affiliate_username

		if username && username != ""
			begin
				return User.find_by_username(username).custom_printer_comment
			rescue
				return ""
			end
		end

		return ""
	end

	def is_vip
		#return is_vip_from_coupon || is_vip_from_boutique_affiliate
		return Order.find(:all, :conditions => [Order.vip_condition(self)]).length > 0
	end

  def coupon_discount
    if coupon_code.nil? || coupon_code == "bulk"
      0
    else
      coupon = Coupon.find_by_code(coupon_code)
      
      # TODO IS THIS GOOD ?
      if ! coupon
        return 0
      end
      # END MODIFICATIONS
      
      if coupon.currency_off.to_f != 0
        coupon.currency_off
      else
        subtotal / (1 - (coupon.percent_off.to_f/100.0)) - subtotal
      end
    end
  end
  
  def nb_prints
    tmp_nb_prints = 0
    
    ordered_products.each do |ordered_product|
      if ! ordered_product.active || ordered_product.coupon
        next
      end
      
      product = (ordered_product.is_extra_garment) ? OrderedProduct.find(ordered_product.ordered_product_id) : ordered_product
      
      nb_artworks = 0

      product.ordered_zones.each do |ordered_zone|
        if ordered_zone.contains_artwork_or_text()
          nb_artworks += 1
        end
      end
      
      tmp_nb_prints += product.quantity * nb_artworks
    end
    
    return tmp_nb_prints
  end

	def contains_custom_and_blanks?
		return nb_tshirts_with_prints > 0 && nb_tshirts_without_prints > 0
	end
	
	def self.nb_tshirts_with_prints_orders(orders)
		return OrderedProduct.sum(:quantity, :conditions => ["ordered_products.order_id IN (#{orders.map{ |order| order.id }.join(",")}) AND ordered_products.active = 1 AND ordered_products.is_extra_garment = 0 AND ordered_products.coupon_id = 0 AND (EXISTS(SELECT * FROM ordered_txt_lines l, ordered_zones WHERE ordered_zones.ordered_product_id = ordered_products.id and l.ordered_zone_id = ordered_zones.id) OR EXISTS(SELECT * FROM ordered_zone_artworks art, ordered_zones WHERE ordered_zones.ordered_product_id = ordered_products.id and art.ordered_zone_id = ordered_zones.id))"])
	end

	def nb_tshirts_with_prints
		if self.nb_shirts_with_prints.nil?
			self.nb_shirts_with_prints = Order.nb_tshirts_with_prints_orders([self])

			update_attributes(:nb_shirts_with_prints => self.nb_shirts_with_prints)
		end
 
                       
		return self.nb_shirts_with_prints
	end

	def self.nb_tshirts_without_prints_orders(orders)
		return OrderedProduct.sum(:quantity, :conditions => ["ordered_products.order_id IN (#{orders.map{ |order| order.id }.join(",")}) AND ordered_products.active = 1 AND ordered_products.is_extra_garment = 0 AND ordered_products.coupon_id = 0 AND NOT (EXISTS(SELECT * FROM ordered_txt_lines l, ordered_zones WHERE ordered_zones.ordered_product_id = ordered_products.id AND l.ordered_zone_id = ordered_zones.id) OR EXISTS(SELECT * FROM ordered_zone_artworks art, ordered_zones WHERE ordered_zones.ordered_product_id = ordered_products.id AND art.ordered_zone_id = ordered_zones.id))"])
	end
  
  def nb_tshirts_without_prints
	if self.nb_shirts_without_prints.nil?
		self.nb_shirts_without_prints = Order.nb_tshirts_without_prints_orders([self])
		update_attributes(:nb_shirts_without_prints => self.nb_shirts_without_prints)
	end

	return self.nb_shirts_without_prints
  end
  
	def nb_tshirts
		return nb_tshirts_without_prints + nb_tshirts_with_prints
	end

  def extra_ordered_products()
    ops = []

    products = OrderedProduct.find_all_by_order_id(id, :order => "id ASC")

    products.each do |ordered_product|
      ops << ordered_product if ordered_product.is_extra_garment
    end

    return ops
  end

  def garments_changed()
    ordered_products.each do |item|

	if item.coupon
		next
	end

      if item.garments_changed
        return true
      end
    end
    
    return false
  end

  def was_artwork_required_problem


    return false
  end

  def estimate_assigned_on
    #garments_ordered_on
    dates = [Time.now]

    ordered_products.each do |ordered_product|

	if ordered_product.coupon
		next
	end

      estimation = ordered_product.expected()
      
      if ! estimation
        next
      end
      
      ordered_on = Time.mktime( estimation.year, estimation.month, estimation.day, 0, 0, 0, 0 )
      dates << ordered_on if ordered_product.garments_ordered_on
    end

    return dates.max { |a,b| a <=> b }
  end

  def calculate_rebate
    begin
      total_rebate / (total_rebate+subtotal)
    rescue
      0
    end
  end

	def insert_master_user_earnings(user, amount)
		begin
			if amount > 0 && user.refered_by_user_id > 0

				master_user = User.find(user.refered_by_user_id)

				amt = amount* master_user.percentage_to_master_affiliate

				Earning.create({:user_id => master_user.id,
					       :created_on => Date.current,
					       :amount_earned => amt,
					       :ordered_zone_id => nil,
					       :image_id => nil,
					       :earning_type => "Commission"})
			end
		rescue
		end
	end

def pay_affiliate(user,amount,currency, affiliates_cookie)

	if user && user.user_level.level == 100
		return
	end

    if user.username !="guest" && !user.affiliate_id.nil? && !user.affiliate_id.to_s.empty? && user.affiliate_expiry_date >= Time.now
      affiliate_id = user.affiliate_id
      space_id = user.affiliate_space_id
      referrer = user.affiliate_referrer
    elsif affiliates_cookie

      begin
        cookie_hash = Marshal.load(affiliates_cookie)
        to_hash = cookie_hash[AFFILIATES_SPACE_PARAM]+cookie_hash[AFFILIATE_ID_PARAM]+cookie_hash[AFFILIATE_REFERRER_PARAM]
        to_hash += cookie_hash[AFFILIATE_PATH_PARAM] if cookie_hash[AFFILIATE_PATH_PARAM] && ! cookie_hash[AFFILIATE_PATH_PARAM].empty?
        to_hash += cookie_hash[AFFILIATE_EXPIRY_DATE].to_s + SALT_AFFILIATE_COOKIE
        if cookie_hash[CHECK_COOKIE] != Digest::SHA1.hexdigest(to_hash)
          return
        end
        if cookie_hash[AFFILIATE_EXPIRY_DATE] <= Time.now
          return
        end
        affiliate_id = cookie_hash[AFFILIATE_ID_PARAM]
        space_id = cookie_hash[AFFILIATES_SPACE_PARAM]
        referrer = cookie_hash[AFFILIATE_REFERRER_PARAM]
      rescue
        return
      end
    else
      return
    end

    url = CONNEXPLACE_PAYMENT_URL
    if (ENV['RAILS_ENV'] == "production")
      url += "?"
    else
      url += "&"
    end

    url += AFFILIATES_SPACE_PARAM + "=" + space_id.to_s
    url += "&" + AFFILIATE_ID_PARAM + "=" + affiliate_id.to_s
    url += "&" + AFFILIATE_REFERRER_PARAM + "=" + referrer
    url += "&" + AMOUNT_PARAM + "=" + amount.to_s
    url += "&" + CURRENCY_PARAM + "=" + currency
    url += "&" + IP_PARAM + "=127.0.0.1"

	Rails.logger.error("UUUURL = #{url}")

    Thread.new{
      Net::HTTP.get(URI.parse(url))
    }
    return affiliate_id
  end


  def insert_earnings

	begin
		if user.user_level.level == 100
			return
		end
	rescue
  end

	begin
		if online_seller > 0
			return
		end
	rescue
	end

    begin
      if confirmed && 
        !earnings_saved && status == SHIPPING_TYPE_SHIPPED


	total_earnings = 0.0

        if refering_user && refering_user != user
          UserReferalCredit.create({:user_id => refering_user_id,
                                    :order_id => id,
                                    :amount => REFERING_USER_EARNING })
          if Country.find_by_shortname(refering_user.country).is_europe
            refering_user.available_credit += REFERING_USER_EARNING_EUROPE
          else
            refering_user.available_credit += REFERING_USER_EARNING
          end
          refering_user.save
        end

        ordered_products.each do |prod|

		if prod.coupon
			next
		end



          #Insert a new Commission Earning if applicable
          if prod.store && prod.store.user && (prod.commission > 0.0 || prod.store.user.auto_commission) && prod.purchase_source_id != 5
            if prod.store.user.auto_commission && prod.model.vip_model_specifications.exists?(:user_id => prod.store.user.id)
              izishirt_cost = prod.izishirt_cost(prod.store.user.id)
              amt = ( prod.price * prod.quantity - prod.quantity * izishirt_cost ) * prod.store.user.earning_percent / 100
            else
              amt=prod.commission*prod.quantity
            end

		total_earnings += amt

            Earning.create({:user_id => prod.store.user.id, 
                           :created_on => prod.created_on, 
                           :amount_earned => amt,
                           :ordered_product_id => prod.id,
                           :earning_type => "Commission"}) 

	    insert_master_user_earnings(prod.store.user, amt)
          end

          #Insert a Affiliation earning for marketplace on boutique
          if User.exists?(prod.marketplace_affiliate_id)
            u = User.find(prod.marketplace_affiliate_id)

		amt = prod.price*prod.quantity*MARKETPLACE_EARNING_PERCENTAGE

		total_earnings += amt

            Earning.create({:user_id => u.id, 
                           :created_on => prod.created_on, 
                           :amount_earned => amt,
                           :ordered_product_id => prod.id,
                           :earning_type => "Affiliation",
                           :note => "Marketplace on boutique"})

	    insert_master_user_earnings(u, amt)
          end

          #Insert a Affiliation earning if applicable
          if User.exists?(prod.affiliate_user_id)
            u = prod.affiliate_user ? prod.affiliate_user : prod.store.user 
            izishirt_cost = prod.izishirt_cost(u.id)

		amt = ((prod.price*prod.quantity - (prod.price*prod.quantity*calculate_rebate))-(prod.quantity*izishirt_cost)) * u.earning_percent / 100

		total_earnings += amt

            Earning.create({:user_id => u.id, 
                           :created_on => prod.created_on, 
                           :amount_earned => amt,
                           :ordered_product_id => prod.id,
                           :earning_type => "Affiliation"})

	    insert_master_user_earnings(u, amt)
          end
          #Insert a new Image Earning if applicable 
          prod.ordered_zones.each do |oz|
            oz.ordered_zone_artworks.each do |artwork|
              if artwork.image && artwork.image.user && prod.purchase_source_id != 5 && artwork.image.user.earnings_per_image > 0

		amt = oz.ordered_product.quantity * artwork.image.user.earnings_per_image

		total_earnings += amt

                Earning.create({:user_id => artwork.image.user.id,
                               :created_on => oz.ordered_product.created_on,
                               :amount_earned => amt,
                               :ordered_zone_id => oz.id,
                               :image_id => artwork.image.id,
                               :earning_type => "Image"})

	        insert_master_user_earnings(artwork.image.user, amt)
              end
            end
          end
        end

	affiliate_id = pay_affiliate(user, total_price.to_s, Currency.find(curency_id).label, affiliates_cookie)
        update_attributes(:earnings_saved => true, :affiliate_id => affiliate_id)

        # update_attributes(:earnings_saved => true)
      end
    rescue => e
      RAILS_DEFAULT_LOGGER.error("Error Generating Earning: #{e}")
    end
  end

  def province_str()
    if shipping.province.nil?
      return shipping.province_name
    else
      return shipping.province.name
    end
  end
  
  def contains_out_of_stock()
    ordered_products.each do |product|

	if product.coupon
		next
	end

      if ! product.model_in_stock
        return true
      end
    end
    
    return false
  end
  
  def set_back_order_to_out_of_stock_products()
    ordered_products.each do |product|
      if ! product.coupon && ! product.model_in_stock
        product.in_back_order = true
        product.save
      end
    end
  end
  
  def country_str
    if shipping.country.nil? 
      return shipping.country_name
    else
      return shipping.country.name
    end
  end

  def self.tax_percent(order)
    order.billing && order.billing.province ? order.billing.province.taxe.to_s : "0.00"
  end

  def bulk_order?
    coupon_code && coupon_code == "bulk" 
  end
  
  def bulk_margin
    sales_price.to_f - garment_cost.to_f - print_cost.to_f - shipping_cost.to_f
  end

  def self.estimate_tax(order)
    Order.total_price(order) * (Order.tax_percent(order).to_f / 100.0) 
  end

  def self.set_to_shipped (order, send_mail = true, set_shipped_on = true)
	if set_shipped_on
		order.update_attributes( :shipped_on => Time.now.to_date)
	end

	if send_mail
		SendMail.deliver_shipped_order_user(order)
	end
  end

  def self.set_to_other_status_from_shipped(order, old_status, new_status)
    if old_status.to_i == SHIPPING_TYPE_SHIPPED && new_status .to_i != SHIPPING_TYPE_SHIPPED
      order.update_attributes( :shipped_on => nil)
    end
  end

  def production_cost
    cost = 0
    cost += garment_cost if garment_cost
    cost += print_cost if print_cost
    cost += shipping_cost if shipping_cost
    cost
  end 

  def cancel
    update_attribute('artwork_sent', true)
    ordered_products.each { |op| op.update_attribute('garments_ordered', true) }
    email = assigned_to.cancelled_order_email if assigned_to 
    if email != nil && email != '' 
      SendMail.deliver_cancelled_order_email(id, email)  
    end
  end   

	def printer_username
		begin
			return User.find(printer).username
		rescue
			return ""
		end

		return ""
	end

	def printer_usernames

		usernames = []

		begin

			u = User.find(printer).username

			usernames << u
		rescue
		end

		ordered_products.each do |product|

			if ! product.active || product.is_extra_garment || product.coupon
				next
			end

			begin
				u = User.find(product.printer).username

				if ! usernames.include?(u)
					usernames << u
				end
			rescue
			end
		end

		return usernames
	end

	def printer_usernames_to_s
		usernames = printer_usernames

		return usernames.inspect.to_s.gsub("[", "").gsub("]", "").gsub("\"", "")
	end

  def assigned
    izishirt_user = User.find_by_username("izishirt")

    return printer != 0 && ((garments_ordered && artwork_sent) || (printer != izishirt_user.id))
  end

  def cost_price
    cost = 0.0
    ordered_products.each { |p| cost += p.cost_price * p.quantity}
    cost
  end

	def detailed_cost_price
		cost = 0.0

		ordered_products.each { |p| cost += ((p.coupon) ? 0.0 : p.model.detailed_cost_price_with_color_id(p.model_size_id, p.color_id) * p.quantity) }

		return cost
	end

  def count_models
    count = 0
    ordered_products.each { |op| count += op.quantity }
    count 
  end

  def count_zones
    count = 0
    ordered_products.each do |op|

	if op.coupon
		next
	end
      
      product = (op.is_extra_garment) ? OrderedProduct.find(op.ordered_product_id) : op
      
      product.ordered_zones.each do |zone|
        count += product.quantity if zone.contains_artwork_or_text
      end
    end
    count
  end

	def count_received

		c = 0

		ordered_products.find(:all, :conditions => ["is_extra_garment = 0 AND coupon_id = 0"]).each do |op|
			if op.garments_state_str == "Received"
				c += op.quantity
			end
		end

		return c
	end
  
  def count_ordered_garments
    
    cpt = 0
    
    ordered_products.each do |product|
	
      if product.garments_ordered
        cpt += product.quantity
      end
    end
    
    return cpt
  end

  def nb_of_certain_size(size_name, ordered = true)

    cpt = 0

    ordered_products.each do |product|

      if product.is_extra_garment || product.coupon
        next
      end

	#prod.model_size.local_name(I18n.locale)

      if product.model_size.local_name(I18n.locale) == size_name && product.garments_ordered == ordered
        cpt += product.quantity
      end
    end

    return cpt
  end

  def list_size_counts_ordered()

    infos = {}

    used_model_sizes = []

	ordered_products.each do |prod|

		if prod.coupon || ! prod.model_size
			next
		end

		if ! used_model_sizes.include?(prod.model_size)
			used_model_sizes << prod.model_size
		end
	end

    used_model_sizes.each do |model_size|
	n = model_size.local_name(I18n.locale)

      infos[n] = nb_of_certain_size(n)
    end

    return infos
  end

	def get_shipping_name()

    text = case shipping_type
      when SHIPPING_BASIC then I18n.t(:standard_shipping, :locale => Language.find(language_id).shortname)
      when SHIPPING_EXPRESS then I18n.t(:express_shipping, :locale => Language.find(language_id).shortname)
      when SHIPPING_PICKUP then I18n.t(:pick_up_in_store, :locale => Language.find(language_id).shortname)
      when SHIPPING_RUSH_PICKUP then I18n.t(:rush_pick_up_in_store, :locale => Language.find(language_id).shortname)
    end
    return text
  end
  
  def count_garments
    
    cpt = 0
    
    ordered_products.each do |product|

      if product.is_reordered_garment? || product.coupon
        next
      end

      cpt += product.quantity
    end
    
    return cpt
  end

  def total_print_cost
    @white = Color.find(:first,:include => :localized_colors, 
                          :conditions => ["localized_colors.name = 'White' and color_type_id = 3"])
    cost = 0.0
    ordered_products.each do |op|

	if op.coupon
		next
	end
      
      product = (op.is_extra_garment) ? OrderedProduct.find(op.ordered_product_id) : op
      
      product.ordered_zones.each do |zone|
        if zone.contains_artwork_or_text
          if product.color_id == @white.id && product.size_id >= 5
            cost += product.print_cost_white_xxl * product.quantity
          elsif product.color_id == @white.id 
            cost += product.print_cost_white * product.quantity
          elsif product.size_id >= 5
            cost += product.print_cost_other_xxl * product.quantity
          else
            cost += product.print_cost_other * product.quantity
          end
        end
      end
    end
    cost
  end

  def garments_ordered
    flag=true
    
    ordered_products.each { |op| flag = false if ((!op.garments_ordered) and !op.garment_in_stock_at_printer) }
    flag
  end

  def self.total_price(order)
    price = 0
    order.ordered_products.each {|item| price += item.price * item.quantity}
    price    
  end

  def self.total_qty (order)
    qty = 0
    order.ordered_products.each {|item| qty += item.quantity}
    qty
  end
  def self.total_qty_original (order)
    qty = 0
    order.ordered_products.each {|item| qty += item.quantity if ! item.is_extra_garment }
    qty
  end

  def order_country
    if ca_order?
      :CA
    elsif us_order?
      :US
    else
      :INTL
    end
  end

  def self.estimate_shipping (order)
    cost = SHIPPING_PRICES[order.shipping_type.to_i][order.order_country].to_f
    if (order.shipping_type.to_i == SHIPPING_BASIC)
		return res = (Order.total_qty(order) > 2) ? 0.0 : (Order.total_qty(order) * cost)
	elsif (order.shipping_type.to_i == SHIPPING_XPRESS_POST)
        return res = (Order.total_qty(order) > 8) ? cost + ((Order.total_qty(order)-8) * 2.00) : cost
	elsif (order.shipping_type.to_i == SHIPPING_EXPRESS)
		return res = (Order.calc_shipping_multiplier(order) * cost)
	elsif (order.shipping_type.to_i == SHIPPING_RUSH)
		return res = (Order.calc_shipping_multiplier(order) * cost)
	elsif (order.shipping_type.to_i == SHIPPING_CHRISTMAS)
		return res = (Order.calc_shipping_multiplier(order) * cost)
	else
		res = (Order.total_qty(order) > 2) ? 0.0 : (Order.total_qty(order) * cost)
	end	
    
  end

  def self.calc_shipping_multiplier(order)
    ret=1
    if(Order.total_qty(order) >= 40)
      ret = (Order.total_qty(order)/ 40)
      if(Order.total_qty(order) % 40)
          ret = ret+1;
      end
    end	
    return ret
  end

  def self.to_izishirt?(order)
    return order.shipping.address1.downcase.to_s.index("5605") && order.shipping.address1.downcase.to_s.index("5605") >= 0 && order.shipping.address1.downcase.to_s.index("gaspé") && order.shipping.address1.downcase.to_s.index("gaspé") >= 0
  end

  def self.shipping_color(order)
    if to_izishirt?(order) 
      "#44A5FF;" 
    elsif order.shipping_type == SHIPPING_XPRESS_POST || order.rush_order == true
      "#CC0000;" 
    else
      "#000000;" 
    end
  end

  def us_order?
    begin
      us = Country.find_by_shortname("US").name.downcase
      country = shipping.country ? shipping.country.name.downcase : shipping.country_name.downcase
      return country == us
    rescue
      return false
    end
  end

  def ca_order?
    begin
      ca = Country.find_by_shortname("CA").name.downcase
      country = shipping.country ? shipping.country.name.downcase : shipping.country_name.downcase
      return country == ca
    rescue
      return false
    end
  end

  # Get the mean number of days of delay depending on the shipping type and the shipping company.
  def mean_shipping_nb_days_delay()
    begin
      address = Address.find(shipping_address)

      # Find the delay depending on the shipping type (rush order, etc.) and the shipping company (canada post, etc.)
      shipping_delay_info = ShippingDelay.find_full_delay(address.country_id, shipping_type)

      delay_min = shipping_delay_info.min_delay
      delay_max = shipping_delay_info.max_delay
    rescue
      delay_min = 0
      delay_max = 0
    end

    # Calculates the mean: round((min + max)/2)
    mean_nb_days_delay = (delay_min && delay_max) ? (((delay_min.to_f + delay_max.to_f) / 2.0).round).to_i : 0

    return mean_nb_days_delay
  end

  # Définition : Date de paiement du client + 1 jour ouvrable + nb de jours ouvrable moyen nécessaire pour le type de shipping choisi.
  def eta()
    # Nouvelle notion pour chaque commande : l'ETA.
    # Définition : Date de paiement du client + 1 jour ouvrable + nb de jours ouvrable moyen nécessaire pour le type de shipping choisi.
    # Exemple : le client passe commande le 14, shipping normal (6-12j ouvrables) un vendredi. On rajoute un jour ouvrable, ce qui nous
    # fait le 17. On rajoute ensuite 9 jours ouvrables, ce qui nous amene au 25.

    eta = next_business_days(created_on, 1)

    mean_nb_days_delay = mean_shipping_nb_days_delay()

    eta = next_business_days(eta, mean_nb_days_delay)

    return eta
  end

  # Number of days from now to the ETA if it is in the future.
  def nb_days_remaining_to_eta()
    eta_date = eta()
    current_date = Date.today

    if eta_date <= current_date
      return 0
    end

    nb_days = 0

    while(eta_date != current_date)
      nb_days += 1

      current_date = next_business_day(current_date)
    end

    return nb_days
  end

  # "Alert" contient les commandes "To Ship" dont l'ETA est supérieur à "Date courante + 3 jours ouvrables".
  def is_shipping_order_alert()
    return eta() <= next_business_days(DateTime.now, 3)
  end

  # BEGIN Business days (should be in a util class)
  def next_business_day(date)
    skip_weekends(date, 1)
  end

  def previous_business_day(date)
    skip_weekends(date, -1)
  end


  def next_business_days(date, nb)
    if nb == 0
      return date
    end

    (1..nb).each do |i|
      date = next_business_day(date)
    end

    return date
  end

  def skip_weekends(date, inc)
    date += inc

    while (date.wday % 7 == 0) or (date.wday % 7 == 6) do
      date += inc
    end

    date
  end
  # END Business days

	def calc_production_date
		# online: 
		#  standard = + 5 jours ouvrables
		#  rush, 24h ou vip = + 1 jour ouvrable

		if ! bulk_order?
			# ONLINE
			if rush_order || Order.is_24_hours_order(ordered_products) || is_vip
				# lendemain ouvrable
				return next_business_days(created_on, 1)
			else
				return next_business_days(created_on, 5)
			end
		else
			return requested_production_on
		end
	end

  # Date Maximale de livraison prévue = Shipping Date + maximum de jours ouvrable nécessaire en fonction du shipping type choisi
  def maximum_shipping_date
    if ! shipped_on
      return nil
    end

    begin

      address = Address.find(shipping_address)

      shipping_delay_info = ShippingDelay.find_delay_only_to_ship(address.country_id, shipping_type, shipping_company_id)

      max_days_shipping_type = shipping_delay_info.max_delay

      if max_days_shipping_type == nil
        max_days_shipping_type = 0
      end
    rescue
      max_days_shipping_type = 0
    end

    return next_business_days(shipped_on, max_days_shipping_type)
  end

  def calculate_artwork_required_on
    # Date de commande + 1 jour ouvrable + délai
    #
    # Délai =
    # Rush orders : 1 jour ouvrable
    # Pick up : 3 jours ouvrables
    # Rapidpost : 5 jours ouvrables
    # Normal : 7 jours ouvrables

    begin
      delay_artwork = ARTWORK_SHIPPING_TYPE_DELAYS[shipping_type]
    rescue
      delay_artwork = 0
    end

    if delay_artwork.nil?
      delay_artwork = 0
    end

    complete_delay = 1 + delay_artwork

    required_on = next_business_days(created_on, complete_delay)

    return required_on
  end

	def comments_per_comment_type(type_str_id, page = 1, per_page = 15, sort_by_user_id = 0, with_deleted = true)

		page = page ? page.to_i : 1
		per_page = per_page ? per_page.to_i : 15

		begin
			sort_by_user_id = User.find(sort_by_user_id).id
		rescue
			sort_by_user_id = 0
		end 

		cond_with_deleted = with_deleted ? "" : " AND deleted = 0"

		begin
			type = CommentType.find_by_str_id(type_str_id)

			order_by = sort_by_user_id > 0 ? "comments.user_id = #{sort_by_user_id} DESC, comments.id DESC" : "comments.id DESC"

			return comments.paginate(:conditions => ["comment_type_id = #{type.id} #{cond_with_deleted}"], :page => page, :per_page => per_page, :order => "#{order_by}")
		rescue
			return []
		end
	end

	def users_with_comments()
		users = Set.new []

		comments.each do |comment|

			if ! comment.user
				next
			end

			users.add(comment.user)
		end

		return users
	end

	def garments_fully_received?()

		# 24 hours order are in stock
		if Order.is_24_hours_order(ordered_products) && ! bulk_order?
			return true
		end

		ordered_products.each do |op|
			if op.is_extra_garment || op.coupon
				next
			end

			begin
				if op.garments_state_str.downcase != "received"
					return false
				end
			rescue
			end
		end

		return true
	end

	def nb_prints_done
		return PrinterStatistic.sum(:nb_prints, :conditions => ["orders.id = #{id}"], :include => [:ordered_product => :order])
	end

	def nb_shirts_printed
		return PrinterStatistic.sum(:nb_printed, :conditions => ["orders.id = #{id}"], :include => [:ordered_product => :order])
	end

	def nb_shirts_missed
		return PrinterStatistic.sum(:nb_missed, :conditions => ["orders.id = #{id}"], :include => [:ordered_product => :order])
	end

	def fully_printed?()
		ordered_products.each do |op|
			if op.is_extra_garment || op.coupon
				next
			end

			if op.total_nb_printed < op.quantity
				return false
			end
		end

		return true
	end

  def coupon_code=(new_coupon)
    
    sellers = User.find_all_by_active_and_user_level_id(1, UserLevel.find_by_name("Izishirt Seller").id)
    
    sellers.each do |seller|
      begin
        if ! seller.acronym || seller.acronym == ""
          next
        end

        if new_coupon.to_s.downcase.index(seller.acronym) == 0
          update_attributes(:online_seller => seller.id)
        end
      rescue

      end 
    end
    
    super
  end

  def shipping_type=(st)
    super # set shipping type normally.

    begin
      self.artwork_required_on = calculate_artwork_required_on()
      self.save
    rescue
    end

	begin
		t_val = st.to_i

		if t_val == SHIPPING_PICKUP || t_val == SHIPPING_RUSH_PICKUP
			self.pick_up = true
		else
			self.pick_up = false
		end

		self.save
	rescue
	end
  end

  def email_client
	begin
	    if user.username == "izishirt" || (custom_client_email && custom_client_email != "" && custom_client_email != "orders@izishirt.com")
	      return custom_client_email
	    end
	    if user.username == "guest"
	      return guest_email
	    end

	    return user.email
	rescue
	end

	return ""
  end

  def increment_coupon
    coupon = Coupon.find_by_code(coupon_code)

    if coupon
      coupon.total_given += 1
      coupon.save
    end
  end

	def contains_back_order_garments?
		ordered_products.each do |prod|
			if prod.back_order?
				return true
			end
		end

		return false
	end

	def products_in_back_order

		l = []

		ordered_products.each do |prod|

			if prod.coupon
				next
			end

			garment_info = {:model => prod.model, :color => prod.color, :model_size => prod.model_size}

			if prod.back_order? && ! l.include?(garment_info)
				l << garment_info
			end
		end

		return l
	end


  
  def main_purchase_source()
    
    max = 0
    source_str = "Unknown"
    
    PurchaseSource.all.each do |source|
      cpt = 0
      
      ordered_products.each do |product|

	if product.coupon
		next
	end

        if product.purchase_source_id == source.id
          cpt += 1
        end
      end
      
      if cpt > max
        source_str = source.str_id
        max = cpt
      end
    end
    
    return source_str
  end
	
	def self.rush_color
		return "fab012"
	end
	
	def self.old_15_days_color
		return "ff3333"
	end

	def self.old_7_days_color
		return "ffff66"
	end

	def self.shirt_24_hours_color
		return "90bfff"
	end

	def self.shirt_24_hours_white_color
		return "99ff99"
	end

	def self.bulk_color
		return "cccccc"
	end

	def self.vip_color
		return "ffccff"
	end

	def color()
		#begin


			
			if Date.today - created_on > 15
				return Order.old_15_days_color
			end

			if Date.today - created_on > 7
				return Order.old_7_days_color
			end



			if rush_order
				return Order.rush_color
			end
		#rescue
		#end

		return "ffffff"
	end

	def production_status
		if is_vip
			return "vip"
		end

		if Order.is_24_hours_order(ordered_products) && bulk_order?
			return "bulk"
		end

		if Order.is_24_hours_order(ordered_products)
			return "24 hours"
		end
		
		if Date.today - created_on > 15
			return "15 days"
		end

		if Date.today - created_on > 7
			return "7 days"
		end

		if bulk_order?
			return "bulk"
		end

		if rush_order
			return "rush"
		end
		
		return "normal"
	end
  
  def color_code_assigned_to(mark_problems = false)
    if artwork_order_assignments.length != 1
      return ""
    end
    
    begin
      
      assignment = artwork_order_assignments[0]
      
      if mark_problems && assignment.artwork_order_assignment_state.str_id == "artworks_problem"
        return "#ff3c3c"
      end
      
      return assignment.staff.color_code
    rescue
      return ""
    end
  end
  
  def assigned_to_artwork_member()
    if artwork_order_assignments.length != 1
      return ""
    end
    
    begin
      return artwork_order_assignments[0].staff.name
    rescue
      return ""
    end
  end
  
  def bulk_seller_id
    begin
      return bulk_order.seller
    rescue
      return 0
    end
  end

  def fullname
    if user_id == User.get_guest_user.id
      # billing name
      return billing.name
    else
      return "#{user.firstname} #{user.lastname}"
    end
  end
  
end
