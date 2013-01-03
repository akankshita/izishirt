class Admin::UserController < Administration  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }


  def list
    where = ["user_level_id=:ulid", { :ulid => params[:id]}] if params[:id]
    @users = User.paginate :per_page => ITEMS_PER_PAGE, :conditions => where, :page => params[:page], :order => params[:order]
    prepare_select_lists
    @levels = [ UserLevel.new({:id=>0, :name=>'all'}) ] + UserLevel.find(:all)
  end


  def new
    @user = User.new({:user_level_id => params[:id]})
    @user.printing_address = Address.new({:address_type => 3}) if @user.printing_address.nil?
    prepare_select_lists
  end


  def create
    params[:user].delete(:printing_address_attributes) if params[:user][:user_level_id].to_i != 5
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = t(:admin_flash_created)


	if @user.user_level.name == "Production Manager"
		Staff.create(:user_id => @user.id)
	end

      redirect_to :action => 'list', :id => @user.user_level_id
    else
      prepare_select_lists
      @user.printing_address = Address.new({:address_type => 3}) if @user.printing_address.nil?
      render :action => 'new', :id => params[:id]
    end
  end


  def edit
    @user = User.find(params[:id])
    @user.printing_address = Address.new({:address_type => 3}) if @user.printing_address.nil?
    prepare_select_lists
  end

  def edit_models
    @models = Model.active_models
    @models = @models.delete_if {|model| ![nil,params[:id].to_i].include?(model.user_id) }
    prepare_edit_models()
  end

  def update
    params[:user].delete(:printing_address_attributes) if params[:user][:user_level_id].to_i != 5
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = t(:admin_flash_updated)
      redirect_to :action => 'list', :id => @user.user_level_id
    else
      prepare_select_lists
      render :action => 'edit', :id => params[:id]
    end
  end

  def update_user_models
    params[:vspec].delete_if{|key, values| !values[:active]}

    model_ids = params[:vspec].map{|key, values| values[:model_id]}.join(',')
    VipModelSpecification.delete_all(["user_id = ? and model_id not in (?)", params[:id], model_ids])
    params[:vspec].each do |key, values|
      values.delete(:active)
      @vspec = VipModelSpecification.find_or_create_by_user_id_and_model_id(params[:id],values[:model_id])
      @vspec.update_attributes(values)
    end
    flash[:notice] = "User models have been saved"
    redirect_to :action => 'edit', :id => params[:id] 
  end


  def destroy
    u = User.find(params[:id])

    if u.username != "guest" && u.username != "izishirt"
      u.destroy
    end
    
    redirect_to :action => 'list'
  end
  
  
  def search
    prepare_select_lists
    where = [ "(username like :search_term or firstname like :search_term or lastname like :search_term or email like :search_term)", { :search_term => '%' + params[:search] + '%' } ]
    #Removed so that user searches for all level ids...admins couldn't find users
    #unless params[:level_id].nil? || params[:level_id].empty?
    #  where[0] +=  " and user_level_id = :level_id"
    #  where[1][:level_id] = params[:level_id]
    #end

    @levels = [ UserLevel.new({:id=>0, :name=>'all'}) ] + UserLevel.find(:all)
    @users = User.paginate :per_page => ITEMS_PER_PAGE, :conditions => where, :page => params[:page], :order => params[:order]
    render :action => "list"
  end

  def model_search
    conditions = ["active = ? and localized_models.language_id = ?", true, session[:language_id]]
    if params[:search] && params[:search] != ""
      conditions[0]+=" and localized_models.name like ?"
      conditions<<"%#{params[:search]}%"
    end

    if params[:model][:category_id] && params[:model][:category_id] != ""
      conditions[0]+=" and category_id = ?"
      conditions<<params[:model][:category_id]
    end

    @models = Model.find(:all, 
                         :include => [:localized_models, :vip_model_specifications],
                         :conditions => conditions)
    @models = @models.delete_if {|model| ![nil,params[:id].to_i].include?(model.user_id) }
    @model = @models.first if params[:model][:category_id] && params[:model][:category_id] != ""
    prepare_edit_models()

    render :action => "edit_models"
  end
  
  
  private
  
  def prepare_edit_models()
    @user = User.find(params[:id])
    @categories = Category.find_all_by_active_and_category_type_id(1, 2)
    @categories.map!{|category| [category.local_name(session[:language_id]), category.id]}

    @vip_model_specifications=@models.map do |model| 
      VipModelSpecification.find_or_initialize_by_model_id_and_user_id(model.id, @user.id)
    end
    @vip_model_specifications.sort! do |x,y| 
      x.model.local_name(session[:language_id]) <=> y.model.local_name(session[:language_id])
    end
  end
  
  def prepare_select_lists
    @levels = UserLevel.find(:all).map {|l| [l.name, l.id]}
    @languages = Language.find(:all).map {|l| [l.name, l.id]}
    #
  end
end
