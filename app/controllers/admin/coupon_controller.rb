class Admin::CouponController < Administration 
  layout 'admin/admin'
  before_filter :check_can_access

  def check_can_access
    if ! @can_access_coupon_codes
      redirect_to "/admin01"
    end
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
	@coupons = Coupon.paginate :per_page => ITEMS_PER_PAGE, :page => params[:page], :order => params[:order]
  end

  def new
    @coupon = Coupon.new
    @models = Model.find_all_by_active(1)

	@order_id = params[:order_id]

	@default_code = ""

	if @order_id && @order_id.to_i > 0
		@default_code = "#{@order_id}_#{Digest::MD5.hexdigest(Time.current.to_s + @order_id.to_s)[0..10]}"
		@order_id = @order_id.to_i
		@coupon.active = true

		@coupon.end_date = DateTime.now + 1.year
		@coupon.total_allowed = 1
	end

	@coupon.code = @default_code
	@coupon.also_apply_to_shipping = true
  end

  def create
    @coupon = Coupon.new(params[:coupon])
    @coupon.models = []
    params[:model].each { |id,checked| @coupon.models << Model.find(id)} if params[:model]
    if @coupon.save

	if params[:order_id]
	      flash[:notice] = "Custom Coupon Deluxe sent."

		order = Order.find(params[:order_id])

		SendMail.deliver_custom_coupon_code(order, @coupon)

	      redirect_to :controller => "/admin/order", :action => 'show', :id => params[:order_id]
	else
	      flash[:notice] = t(:admin_flash_created)
	      redirect_to :action => 'list'
	end

    else
      flash[:error] = ""

      @coupon.errors.each do |field, msg|
        flash[:error] += "#{field} #{msg}<br />"
      end

      redirect_to :back
    end
  end

  def edit
    @coupon = Coupon.find(params[:id])
    @models = Model.find_all_by_active(1)
  end

  def update
    @coupon = Coupon.find(params[:id])
    @models = Model.find_all_by_active(1)
    @coupon.models = []
    params[:model].each { |id,checked| @coupon.models << Model.find(id)} if params[:model]
    if @coupon.update_attributes(params[:coupon])
      flash[:notice] = t(:admin_flash_updated)
      redirect_to :action => 'list', :id => @coupon
    else
      flash[:error] = ""

      @coupon.errors.each do |attr, msg|
        flash[:error] += "#{attr} - #{msg}<br />"
      end

      render :action => 'edit'
    end
  end

  def destroy
    Coupon.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def purge
    Coupon.delete_all('active = 0')
    redirect_to :action => 'list'
  end

  def search
    where = [ "(code like :search_term)", { :search_term => '%' + params[:search] + '%' } ]
    @coupons = Coupon.paginate :per_page => ITEMS_PER_PAGE, :conditions => where, :page => params[:page], :order => params[:order]
    
    render :action => "list"
  end

  def active
    @active = Coupon.find(params[:id])
    if @active.active
      @active.update_attributes(:active => 0)      
    elsif !@active.active
      @active.update_attributes(:active => 1) 
    end
    redirect_to :action => 'list'
  end  
  
end
