class Myaccount::ProfileController < MainMyaccountController
  before_filter :authorize,  :except => [:unsubscribe, :delete_confirm]
  

  def index
    redirect_to :controller => "/myaccount/profile", :action => 'profile'
  end
  
  def control_panel

    @nb_designs_sold = @user.nb_designs_sold_last_week

    if session[:first_time_shop_created]

      @msg_control_panel = session[:first_time_shop_created]
      session[:first_time_shop_created] = nil
    end

    render :layout => 'myizishirt_2011'
  end

  def help_center
    
  end
  
  def profile
    #begin
      @user = User.find(session[:user_id])
      @shop = @user.store
      @address = @user.address 
      @profile = @user.profile
      @months  = ["January","February","March","April","May","June","July",
                  "August","September","October","November", "December"]
      render :layout => 'myizishirt_2011'
    #rescue
    #  redirect_to(:controller => 'login')
    #end
  end
  
  def unsubscribe
    begin
      if params['e']
        @email = Base64.decode64(params['e']) 
        @user  = User.find_by_email(@email)
      elsif request.post? 
        @user = User.authenticate(params[:username], params[:password])
        @email = params[:email]
        if @user
          @user.wants_newsletter = false
          @user.save
          flash[:notice] = t(:unsubscription_complete)
        else
          @user  = User.find_by_email(@email)
          flash[:notice] = t(:myizishirt_login_ctl_invalid)
        end
      end
    rescue
      redirect_to(:controller => 'display', :action => 'new_home')
    end
  end
  
  def update
     begin
      if params[:user_preview_only] == "1" || params[:user_avatar_only] == "1"
        save_image()
        redirect_to :back
      else
        @user = User.find(session[:user_id])
        email = params[:user][:email]

        @user.email = email if email != @user.email

        @user.update_attribute(:show_name, params[:user][:show_name])
        @user.update_attribute(:lastname, params[:user][:lastname])
        @user.update_attribute(:language_id, params[:user][:language_id])
        @user.update_attribute(:firstname, params[:user][:firstname])
        @user.update_attributes({:email => email})

        # Two cases: 1- same email, 2- modified, need
        if @user.valid?
          @user.profile = Profile.create({:user_id => session[:user_id], :picture => 'avatar.png'}) if @user.profile.nil?

          @user.update_attribute(:password, params[:pass][:pass]) if params[:pass][:pass] == params[:pass][:pass_conf] && params[:pass][:pass] != nil && params[:pass][:pass] != ""

          save_image()

          @addr = params[:address]
          @address = @user.address.nil? ? Address.new() : @user.address
          @address.update_attributes(params[:address])
          @address.country_id = Country.find_by_name(@addr[:country_name]) ? Country.find_by_name(@addr[:country_name]).id : nil
          @address.province_id = Province.find_by_name(@addr[:province_name]) ? Province.find_by_name(@addr[:province_name]).id : nil
          @address.save

          @user.address = @address
          flash[:info] = t(:myizishirt_profile_ctl_updated)
          redirect_to :action => 'profile'
        else
          flash[:error] = t(:myizishirt_profile_ctl_updated_error) + " <br />"

          @user.errors.each do |field, msg|
            flash[:error] += "#{field} - #{msg}<br />"
          end

          redirect_to :back
        end

      end

      
    rescue Exception => e
      logger.error("ERR = #{e}")
      flash[:error] = t(:myizishirt_profile_ctl_updated_error) + "<br />"

      @user.errors.each do |field, msg|
        flash[:error] += "#{field} - #{msg}<br />"
      end

      redirect_to :back
    end
  end

  def confirm_delete
    begin
      @user = User.find(session[:user_id])
      @user.active = 0
      @user.save
    rescue
      redirect_to(:controller => '/display')
    end

    redirect_to(:controller => 'login', :action => 'logout', :flash=>t(:delete_my_account_confirm))
  end

  private

  def save_image
    @user = User.find(session[:user_id])

    if @user.valid?
      @user.profile = Profile.create({:user_id => session[:user_id], :picture => 'avatar.png'}) if @user.profile.nil?
      @user.profile.uploaded_picture = params[:user_preview_image]
      @user.profile.save
    end
  end


end

