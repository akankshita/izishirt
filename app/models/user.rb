class User < ActiveRecord::Base
  belongs_to  :user_level
  belongs_to  :language
  
  has_one :address
  has_one :store
  has_one :profile
  has_one :rank
  has_one :top_user
  has_one :facebook
  has_one :twitter
  has_one :staff
  has_one :wfm_printer_configuration
  #Printer Location is used only if user type is printer
  has_one :printing_address, :class_name => 'Address', :conditions => ["address_type = ?",3]

  has_many :models  #For premium users who have their own models
  has_many :contents
  has_many :blog_entries
  has_many :images
  #Printer ation is used only if user type is printer
  has_many :orders
  has_many :refered_orders, :class_name => 'Order', :foreign_key => :refering_user_id
  has_many :comments
  has_many :ordered_zones, :through => :images
  has_many :products, :through => :store
  has_many :ordered_products, :through => :store
  has_many :earnings
  has_many :quote_products
  has_many :print_sizes
  has_many :print_prices
  has_many :order_user_read_all_comments
  has_many :order_email_histories
  has_many :order_histories
  has_many :store_comments
  has_many :printer_shifts
  has_many :user_referal_credits
  #has_many :vip_model_specifications, :dependent => :destroy
  has_many :billing_addresses, :class_name => 'Address', :finder_sql => 'select a.* from addresses a, users u where a.user_id=u.id and a.address_type=1'
  has_many :shipping_addresses, :class_name => 'Address', :finder_sql => 'select a.* from addresses a, users u where a.user_id=u.id and a.address_type=2'
  has_many :order_shipping_histories
  has_many :accounting_variables

  before_save :check_username

  named_scope :french, :conditions => "language_id = 1 and active = true"
  named_scope :english, :conditions => "language_id = 2 and active = true"

  validates_presence_of :username, :password, :email, :firstname, :lastname
  validates_numericality_of :default_profit_margin
  validates_uniqueness_of :username, :email  
  validates_confirmation_of :password
  validates_length_of :username, :minimum => 4
  validates_length_of :password, :minimum => 6
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
  accepts_nested_attributes_for :printing_address, :store

  attr_accessor :password_confirmation

  def apply_discounts; return !dont_apply_discounts; end
  def apply_size_prices; return !dont_apply_size_prices; end


  def check_username
    if username == 'fr'
      errors.add_to_base(I18n.t("activerecord.errors.models.user.taken", :attribute=>"username"))
      return false
    end
  end

	def contest_designs
		begin
			return images.find(:all, :conditions => ["is_contest = 1 AND pending_approval = #{DESIGN_VALIDATION_STATE_APPROVED_ID}"])
		rescue
		end

		return []
	end

  def shop_link_text(language)
    if language == "en"
      username.last == "s" ? "#{username.capitalize}' products" : "#{username.capitalize}'s products" 
    else
      "Produits #{username}"
    end
  end
  
  def commission_earnings
    earnings = []
    products.each do |product|
      earnings += product.earnings
    end
    return earnings
  end

	# modifier semaine lundi-vendredi
	def shift_hours_done_week
	
		s1 = Shift.find(:all, :conditions => ["user_id = #{id} AND CAST(created_at AS DATE) BETWEEN '#{Date.current.beginning_of_week}' AND '#{Date.current.end_of_week - 2}'"])
		s2 = PrinterShift.find(:all, :conditions => ["user_id = #{id} AND CAST(created_at AS DATE) BETWEEN '#{Date.current.beginning_of_week}' AND '#{Date.current.end_of_week - 2}'"])

		shifts = s1 | s2

		the_sum = 0.0

		shifts.each do |s|
			the_sum += s.duration
		end

		return the_sum
	end

	def shift_hours_done_today
	
		s1 = Shift.find(:all, :conditions => ["user_id = #{id} AND finished_at IS NULL"])
		s2 = PrinterShift.find(:all, :conditions => ["user_id = #{id} AND finished_at IS NULL"])

		shifts = s1 | s2

		the_sum = 0.0

		shifts.each do |s|
			the_sum += s.duration
		end

		return the_sum
	end

  def credit_string
    user_country = Country.find_by_shortname(country)
    if user_country.is_europe
      REFERING_USER_EARNING_EUROPE
    else
      REFERING_USER_EARNING
    end
  end
  
  def design_earnings
    earnings = []
    images.each do |image|
      earnings += image.earnings
    end
    return earnings
  end

  def design_count_for_flash
	  conditions = ["user_id = ? AND ( show_in_boutique = 1)", self.id]
    Image.find(:all, :conditions=>conditions).size
  end

  def self.default_values(set_language, set_country, set_earnings)
    {
      :first_visit => Time.now,
      :language_id => set_language,
      :active => 1, 
      :user_level_id => 6, 
      :country => set_country,
      :earnings_per_image => set_earnings
    }
  end
  
  def affiliation_earnings
    Earning.find(:all, :conditions=>['user_id = ? AND earning_type = ?', id, 'Affiliation'])
  end

	def can_do(permission_str_id)
		return user_level.can_do(permission_str_id)
	end
  
  
  
  def commission_revenue_in_month(date)
    commission_revenue = 0.0
    earnings = commission_earnings.select {|earning| earning.created_on >= date.beginning_of_month and earning.created_on < date.end_of_month+1.day }
    earnings.each {|earning| commission_revenue += earning.amount_earned }
    return commission_revenue
  end

  def locale
    "#{language.shortname}-#{country}"
  end

  def domain
    case country
    when "US": "izishirt.com"
    else 
      "izishirt.ca"
    end
  end

  def my_designs(lang)
    if lang == 'en'
      if store.user.username.last == 's'
        my_shop_designs = "#{username.capitalize}' designs"
      else
        my_shop_designs = "#{username.capitalize}'s designs"
      end
    else
      my_shop_designs = "Designs de #{username}"
    end
  end
  
  def design_revenue_in_month(date)
    design_revenue = 0.0
    earnings = design_earnings.select {|earning| earning.created_on >= date.beginning_of_month and earning.created_on < date.end_of_month+1.day }
    earnings.each {|earning| design_revenue += earning.amount_earned }
    return design_revenue
  end
  
  def affiliation_earnings_in_month(date)
    affiliation_revenue = 0.0
    earnings = affiliation_earnings.select {|earning| earning.created_on >= date.beginning_of_month and earning.created_on < date.end_of_month+1.day}
    earnings.each {|earning| affiliation_revenue += earning.amount_earned }
    return affiliation_revenue
  end
  
  def self.authenticate(username, password)
    user = nil

  	if(User.find_by_username_and_password(username, password).nil?)
  	  user = User.find_by_email_and_password(username, password)
  	else
  	  user = User.find_by_username_and_password(username, password)
  	end

    return (user && user.active) ? user : nil

  end

  def image_earnings()
    return earnings("Image")
  end

  def earnings(earning_type)
    Earning.sum('amount_earned', 
      :conditions => ["user_id = ? and earning_type = ?", id, earning_type]) || 0
  end

  def earnings_by_date(earning_type, start_date, end_date)
    Earning.sum('amount_earned',
      :conditions => ["user_id = ? and earning_type = ? and created_on between ? and ?",
        id, earning_type, start_date, end_date]) || 0
  end

  def nb_earnings_by_date(earning_type, start_date, end_date)
    Earning.sum(:quantity,
      :conditions => ["user_id = ? and earning_type = ? and earnings.created_on between ? and ?",
        id, earning_type, start_date, end_date], :include => [:ordered_product]) || 0
  end

  def earnings_by_date(start_date, end_date)
    Earning.sum('amount_earned',
      :conditions => ["user_id = ? and created_on between ? and ?",
        id, start_date, end_date]) || 0.0
  end

  def earnings_last_week()
    start_date = Time.now.to_date - 7.days
    end_date = Time.now.to_date

    return earnings_by_date(start_date, end_date)
  end

  def nb_designs_sold_last_week()
    start_date = Time.now.to_date - 7.days
    end_date = Time.now.to_date

    return nb_earnings_by_date("Image", start_date, end_date)
  end

  def nb_products_sold_last_week()
    start_date = Time.now.to_date - 7.days
    end_date = Time.now.to_date

    earnings = Earning.find(:all,
      :conditions => ["user_id = ? and earning_type = ? and created_on between ? and ?",
        id, "Commission", start_date, end_date])

    cpt = 0

    earnings.each do |earning|
        begin
          cpt += earning.ordered_product.quantity
        rescue
        end
    end

    return cpt
  end
  
  def total_earnings(date_min = nil, date_max = nil)

    cond_dates = (date_min && date_max && date_min != "" && date_max != "") ? " AND created_on BETWEEN '#{date_min.to_date.to_s(:db)}' AND '#{date_max.to_date.to_s(:db)}'" : ""

    total = Earning.sum('amount_earned',
      :conditions => ["user_id = ? and earning_type != ? #{cond_dates}", id, 'Payment']) || 0

    if total <= 0
      total = 0.to_f
    end

    return total.to_f
  end

  def pending_earnings

    wrong_statuses = [SHIPPING_TYPE_CANCELED.to_s + ".00", SHIPPING_TYPE_SHIPPED,SHIPPING_TYPE_CANCELED_COUPON.to_s + ".00",SHIPPING_TYPE_TO_CHECK.to_s + ".00",SHIPPING_TYPE_AWAITING_PAYMENT.to_s + ".00"]
    wrong_statuses = wrong_statuses.join(",")


    # Product commission
    op1 = OrderedProduct.find(:all, :conditions=>"ordered_products.product_id IN (select id from products where store_id=#{store.id}) and EXISTS(select id from orders where orders.id=ordered_products.order_id and earnings_saved=0 and confirmed=1 and status NOT IN(#{wrong_statuses}))")
    # Image commission
    op2 = OrderedProduct.find(:all, :include=>{:ordered_zones=>{:ordered_zone_artworks=>{:image=>:user}}},:conditions=>"users.id=#{id} and EXISTS(select id from orders where orders.id=ordered_products.order_id and earnings_saved=0 and confirmed=1 and status NOT IN(#{wrong_statuses}))")
    # Flash commission 15%
    op3 = OrderedProduct.find(:all, :conditions=>"affiliate_user_id=#{id} and EXISTS(select id from orders where orders.id=ordered_products.order_id and earnings_saved=0 and confirmed=1 and status NOT IN(#{wrong_statuses}))")
    # Marketplace affiliate boutique 10%
    op4 = OrderedProduct.find(:all, :conditions=>"marketplace_affiliate_id=#{id} and EXISTS(select id from orders where orders.id=ordered_products.order_id and earnings_saved=0 and confirmed=1 and status NOT IN(#{wrong_statuses}))")

    logger.error("BEGIN PENDING")

    total_amount = 0
    for prod in op1
      total_amount += prod.commission*prod.quantity

      logger.error("date op1 #{prod.order.created_at} #{prod.order.id}")
      logger.error("amount op1 #{total_amount}")
    end
    for prod in op2
      prod.ordered_zones.each do |oz|
        oz.ordered_zone_artworks.each do |artwork|
          total_amount += prod.quantity * earnings_per_image
          logger.error("amount op2 #{total_amount}")
        end
      end
      logger.error("date op2 #{prod.order.created_at} #{prod.order.id}")
    end
    for prod in op3
      total_amount += ((prod.price*prod.quantity - (prod.price*prod.quantity*prod.order.calculate_rebate))) * earning_percent / 100
      logger.error("date op3 #{prod.order.created_at} #{prod.order.id}")
      logger.error("amount op3 #{total_amount}")
    end

    for prod in op4
      total_amount += prod.price*prod.quantity*MARKETPLACE_EARNING_PERCENTAGE
      logger.error("amount op4 #{total_amount} #{}")
      logger.error("date op4 #{total_amount} #{prod.order.id}")
    end
    logger.error("END PENDING")

    return total_amount

    

  end

  def earnings_paid
    #total = Earning.sum(:amount_paid,
    #  :conditions => ["user_id = ? and earning_type = ?", id, "Payment"]) || 0

    #if total <= 0
    #  total = 0
    #end

    #return total.to_f
    return store.amount_paid
  end    

  def earnings_owed
    total_earnings - earnings_paid  
  end

  def has_new_earnings
    return earnings_owed > 0
  end

  def is_izishirt_seller
    begin
      return user_level.name == "Izishirt Seller"
    rescue
    end
  
    return false
  end


  def self.verify_administrator(user_id)
    user = User.find_by_id(user_id, :conditions => ["user_levels.level = 100"], :include => ["user_level"])
  end

  def self.allowed_back_access(user_id,ip)
    user = User.find_by_id(user_id, :conditions => ["user_levels.level = 100"], :include => ["user_level"])
    return false if !user
    return true
  end

  def self.verify_affiliate_manager(user_id)
    user = User.find_by_id(user_id)

    if user.user_level.name == "Affiliate Manager"
      return user
    end

    return (user.username == "izishirt") ? user : nil
  end

  def self.verify_read_only_affiliate_manager(user_id)
    user = User.find_by_id(user_id)

    if user.user_level.name == "Read-Only Affiliate Manager"
      return user
    end

    return (user.username == "izishirt") ? user : nil
  end
  
  def self.verify_production(user_id)
    user = User.find_by_id_and_user_level_id(user_id, 5)
  end  
  
  #clean up email and username before validation
  def before_validation
    self.email = User.clean_string(self.email || "")
    self.username = User.clean_string(self.username || "")
    self.username = User.clean_username(self.username || "")
  end

  # validate that email is proper format
  #def validate_on_create
  #  @email_format = Regexp.new(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/)
  #  errors.add(:email, I18n.t(:must_be_a_valid_format, 1)) unless @email_format.match(email)
  #end
 
  #after creation, clear password from memory
  def after_create
    @password = nil
    @password_confirmation = nil
  end
  
  def self.generate_password(length = 6)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('1'..'9').to_a - ['o', 'O', 'i', 'I']
    Array.new(length) { chars[rand(chars.size)] }.join
  end
  
  def create_my_url(domain="izishirt.ca")

    if ENV['RAILS_ENV'] == "development"
      url = "http://#{username}.#{domain}"
    else
      url = "http://#{username}.#{domain}"
    end
  end
  
  def active_image_count
    conditions = ["user_id = ? AND (pending_approval = 1 AND active = 1 AND show_in_boutique = 1)", id]    
    Image.count(:conditions => conditions)
  end
  
  def total_design_orders
    total = OrderedZones.find(:all, :include=>[:image], :conditions=>['images.user_id = ?', id])
  end
  
  def total_product_orders
    total = Orders.find(:all, :include=>[:store], :conditions=>['stores.user_id = ?', id])
  end
  
  def get_print_processes(lang_id, quote_product_color)
    print_processes = Set.new
    
    print_sizes.each do |print_size|
      begin
        # special cases for mestizo !
        # Quand on imprime chez mestizo, chandail black ou other => On ne devrait pas pouvoir "6 color process"
        # Quand on imprime chez mestizo, chandail blanc => On ne devrait pas pouvoir choisir "White + ..."  
        mestizo_prices = MestizoPrintPrice.find_all_by_print_process_id_and_quote_product_color_id(print_size.print_process, quote_product_color.id)      
        
        if (username == "mestizo" && mestizo_prices.length > 0) || username != "mestizo"
          print_processes.add(LocalizedPrintProcess.find_by_print_process_id_and_language_id(print_size.print_process, lang_id, :order => "name ASC"))
        end
      rescue
      end
    end
    
    return print_processes.to_a.sort {|x,y| x.name <=> y.name }
  end


  #Meant only for users who are printers
  def unfinished_orders
    Order.count(:conditions => ["printer = ? and status NOT IN (?, ?, ?, ?, ?, ?, ?, ?)", id, SHIPPING_TYPE_SHIPPED, SHIPPING_TYPE_CANCELED, SHIPPING_TYPE_PACKAGING, SHIPPING_TYPE_ON_HOLD, SHIPPING_TYPE_PRINTED, SHIPPING_TYPE_CANCELED_COUPON, SHIPPING_TYPE_PARTIALLY_SHIPPED, SHIPPING_TYPE_AWAITING_PAYMENT])

  end

  #Meant only for users who are printers
  def unfinished_shirts
    #@orders = Order.find(:all, :conditions => ["printer = ? and status NOT IN (?, ?, ?, ?, ?, ?, ?, ?)", id, SHIPPING_TYPE_SHIPPED, SHIPPING_TYPE_CANCELED, SHIPPING_TYPE_PACKAGING, SHIPPING_TYPE_ON_HOLD, SHIPPING_TYPE_PRINTED, SHIPPING_TYPE_CANCELED_COUPON, SHIPPING_TYPE_PARTIALLY_SHIPPED, SHIPPING_TYPE_AWAITING_PAYMENT])
    #@sum = 0
    #@orders.each do |order|
    #  order.ordered_products.each do |op|#

    #    if op.is_extra_garment || ! op.contains_prints
    #      next
    #    end

    #    @sum = @sum + op.quantity
    #  end
    #end
    #@sum

    # return (ordered_zone_artworks.length > 0) || ordered_txt_lines.length > 0
    

    return OrderedProduct.sum(:quantity, :conditions => ["#{OrderedProduct.fast_sql_contains_prints} AND ordered_products.is_extra_garment = 0 AND orders.printer = #{id} and orders.status NOT IN (#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_PACKAGING}, #{SHIPPING_TYPE_ON_HOLD}, #{SHIPPING_TYPE_PRINTED}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_PARTIALLY_SHIPPED}, #{SHIPPING_TYPE_AWAITING_PAYMENT})"], :include => [:order])
  end

  def shirts_given_status(status)
    #@orders = Order.find(:all, :conditions => ["printer = ? AND status IN (?)", id, status])
    #@sum = 0
    #@orders.each do |order|
    #  order.ordered_products.each do |op|

    #    if op.is_extra_garment || ! op.contains_prints
    #      next
    #    end

    #    @sum = @sum + op.quantity
    #  end
    #end
    #@sum

    return OrderedProduct.sum(:quantity, :conditions => ["#{OrderedProduct.fast_sql_contains_prints} AND ordered_products.is_extra_garment = 0 AND orders.printer = #{id} and orders.status IN (#{status})"], :include => [:order])
  end

  def printed_by_date(date)
    @today = date
    @tomorrow = date+1.days

    @batching = 0
    @packaging = 0
    @shirts = 0

    #Get a unique list of orders who's statuses have been set to batching or packagins
    @orders = OrderHistory.find(:all, :include => :order, :conditions => ["attribute = ? and to_value in (?, ?) and created_on between ? and ? and user_id = ?",
      'status', SHIPPING_TYPE_BATCHING, SHIPPING_TYPE_PACKAGING, @today, @tomorrow, id]).map{|hist| hist.order}.uniq
    
    @orders.each do |order|
      @batching += 1 if order.status == SHIPPING_TYPE_BATCHING
      @packaging += 1 if order.status == SHIPPING_TYPE_PACKAGING
      order.ordered_products.each do |op|
        @shirts += op.quantity
      end
    end
    return {:batching => @batching, :packaging => @packaging, :shirts => @shirts, :date => @today}
  end
  
  def self.nb_orders_artwork_not_sent(printer_username)
    printer = User.find_by_username(printer_username)
    
    if printer
      orders = Order.find_all_by_printer(printer.id, :conditions => ["artwork_sent = 0 AND status not in (#{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_AWAITING_PAYMENT})"])
      return orders.length
    else
      return 0
    end
  end

  def self.get_guest_user
    return User.find_by_username("guest")
  end

	def fullname
		begin
			return "#{firstname} #{lastname}"
		rescue
		end
		
		return "N/A"
	end

  def is_guest?
    return username=="guest"
  end

  def self.is_guest?(user_id)
    return User.find_by_username("guest").id == user_id
  end

  def shipped_products_for_affiliate_report(date=nil)
    date = Time.now.to_date if date.nil?
    OrderedProduct.find(:all, :conditions => ["(affiliate_user_id = ? or store_id = ? ) and orders.shipped_on is not null and orders.shipped_on between ? and ?",
                        id,store.id,date.beginning_of_month,date.end_of_month], :include => :order, :order => "orders.shipped_on")
  end


  def design_in_contest
    if Image.exists?(["user_id=#{id} AND is_contest=1 AND ((end_vote IS NOT NULL AND end_vote > NOW() AND pending_approval = #{DESIGN_VALIDATION_STATE_APPROVED_ID}) OR pending_approval=#{DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID})"])
      return Image.find_by_user_id(id, :conditions=>"is_contest=1 AND ((end_vote IS NOT NULL AND end_vote > NOW() AND pending_approval = #{DESIGN_VALIDATION_STATE_APPROVED_ID}) OR pending_approval=#{DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID})")
    else
      return nil
    end
  end

  private
  
  #clean string to remove spaces and force lowercase
  def self.clean_string(string)
    (string.downcase).gsub(" ","")
  end
  
  def self.clean_username(string)
  
	#CleanUsername
    string.downcase.gsub(/[\W_-]/, '')
  
  end
  
end


 

