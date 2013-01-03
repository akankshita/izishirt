class Myizishirt::LoginController < MainMyizishirtController

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :controller=>'/display', :action => 'izishirt_2011' }

  skip_before_filter :authorize

  layout :set_layout

  # Show the login form page and login the user if the page was submitted
  def index
    
    if request.post?
      user = User.authenticate(params[:username], params[:password])
      if user

        if session[:original_uri_login].nil?
          session[:original_uri_login] = ""
        end

        session[:original_uri_login] = session[:original_uri_login].gsub("?lightbox=login","")
        execute_login(user)
        user.last_visit = Time.now
        user.save
      else        
        session[:error] = t(:myizishirt_login_ctl_invalid)
        if params[:from_contest] && params[:from_contest] == 'submit'
          redirect_to :controller => '/contest/tshirt_design', :action => 'submit_your_design'
        elsif params[:from_contest] && params[:from_contest] == 'vote'
          redirect_to :back
        elsif params[:from_url]
          redirect_to params[:from_url]
        else
          redirect_to :controller => '/display', :action => 'izishirt_2011', :lightbox => 'login'
        end
      end
    else
      loginform
      redirect_to :controller => '/display', :action => 'izishirt_2011', :lightbox => 'login'
    end
  end

  def loginform
    if (session[:original_uri_login])
      @intro_title = t(:myizishirt_login_signup_to_order)
      @intro_text = t(:myizishirt_login_signup_to_order_txt)
    else
      @intro_title = t(:myizishirt_login_view_login_with_izishirt_u_can)
      @intro_text = t(:myizishirt_login_view_login_with_izishirt_u_can_txt)
    end
  end

  def lightbox
    @cookie_username = cookies[:r3] ? Base64.decode64(cookies[:r3]) : ""
    @cookie_password = cookies[:r4] ? Base64.decode64(cookies[:r4]) : ""
    if params[:validate].to_i == 1
      session[:original_uri_login] = "/checkout/address"
    elsif !session[:original_uri_login]
      session[:original_uri_login] = request.referrer
    end


    render :layout => false
  end

  def logout
    
    @cart = session[:cart]
    reset_session
    session[:cart] = @cart
    flash[:success] = params[:flash]
    redirect_to "/"
  end


  def new

    if session[:user_id].nil?
      @user = User.new(params[:user])
    else
      redirect_to :controller => "/display", :action => "izishirt_2011"
      return
    end
    render :layout=>"izishirt_2011"
  end  

  def create
    @user = User.new(params[:user])
    @user.first_visit = Time.now
    @user.active = 1	
    @user.user_level_id = UserLevel.find_by_level(CONFIG_USER_LEVEL).id

    @user.country = session[:country]

    if User.exists?(:email=>@user.email)
      flash[:error] = t(:existing_email)
    end
    if User.exists?(:username=>@user.username)
      flash[:error] = t(:existing_username)
    end

    if @user.valid?
      #check_affiliation(@user) 
      @user.save
      Profile.create(:user_id => @user.id, :picture => 'avatar.png')
      begin
        SendMail.deliver_new_user(@user)
      rescue

      end
      execute_login(@user, true)
      if params[:from] && params[:from] == 'contest'
        redirect_to :controller=>'/contest/tshirt_design', :action=>:submit_your_design
        return
      end
      render :action=>"confirmation", :layout=>'izishirt_2011'
    else
      render :action => 'new', :layout=>"izishirt_2011"
    end
  end

  def confirmation
    render :layout=>"izishirt_2011"
  end

  def lightbox_lost
    render :layout => false
  end

  def lostpass 
    redirect_to :controller => '/display', :action => 'izishirt_2011', :lightbox => 'lost'
  end

  def lostpass_submit
    
    
    
    if params[:email] && params[:email] != ''
      user = User.find_by_email(params[:email])
      if user 
        newpass = User.generate_password
        if SendMail.deliver_lost_pass(user, newpass)	  
          @user = User.find_by_email(params[:email])
          @user.update_attribute(:password, newpass)
          flash[:notice] = '<script language="javascript">document.getElementById("lost_password_submit_box").setAttribute("style", "display:none");</script>' + "<span class='successMessage'>" + t(:myizishirt_login_ctl_pass_sent) + "</span>"
        else
          flash[:notice] = "<span class='errorMessage'>" + t(:myizishirt_login_ctl_mail_faillure) + "</span>"
        end
      else
        flash[:notice] = "<span class='errorMessage'>" + t(:myizishirt_login_ctl_mail_match) + "</span>"
      end
      render :text => flash[:notice]
    else
      render :text => ""
    end
  end


  private
  
  def set_layout
    return "izishirt_2011"
  end
 
  def execute_login(user, no_redirect=false)


    session[:user_id] = user.id
    session[:affiliate] = true if user.user_level_id == 6
    session[:new_comment] = nil
#    session[:language] = user.language.shortname
#    session[:language_id] = user.language.id
#    session[:language_index] = Language.count(:all, :conditions => ["id<?", user.language_id])
    #check_affiliation(user)
    user.save

    if params[:remember].to_i == 1
      cookies[:r3] = {
        :value => Base64.encode64(params[:username]),
        :expires => 1.year.from_now
      }
      cookies[:r4] = {
        :value => Base64.encode64(params[:password]),
        :expires => 1.year.from_now
      }
    else
      cookies.delete :r1
      cookies.delete :r2
      cookies.delete :r3
      cookies.delete :r4
    end

    uri = session[:original_uri_login] || "/"
    if params[:from_contest] && params[:from_contest] == 'submit'
      uri = url_for(:controller => '/contest/tshirt_design', :action => 'submit_your_design')
    end
    session[:original_uri_login] = nil
    flash[:success] = t(:myizishirt_login_welcome)

    if session[:country] != user.country

      country_redirection(user.country, session[:language], session[:language], @DOMAIN_NAME)
      return
    end
#render :text => session.inspect and return false
    redirect_to uri if !no_redirect
  end

end
