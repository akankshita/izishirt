# Filters added to this controller apply to all controllers in the admin section.
# Likewise, all the methods added will be available for all those controllers. (app/controllers/admin/...)

class Production < ApplicationController
  layout 'production/production'
  before_filter :authorize_administrator
  
  def authorize_administrator
    session[:language_id] = 2
    session[:original_uri_login] = request.request_uri
    
    staff = nil
    
    begin
      staff = User.find(session[:user_id]).staff
      @user_is_artwork_manager = staff.is_artwork_manager
    rescue
      @user_is_artwork_manager = false
    end
    
    @user_is_artwork_manager = @user_is_artwork_manager || User.find(session[:user_id]).username == "izishirt"
    
    begin
      @user_is_artwork_member = staff.is_artwork_member
    rescue
      @user_is_artwork_member = false
    end
    
    @user_is_artwork_member = @user_is_artwork_member || User.find(session[:user_id]).username == "izishirt"
    @connected_staff = staff
    
    @check_user_is_artwork_manager = @user_is_artwork_manager
    
    if staff && staff.printer != user_id()
      @user_is_artwork_member = false
      @user_is_artwork_manager = false
    end
    
    @user_id = user_id()
    
    redirect_to :controller => '/myizishirt/login' unless User.verify_administrator(session[:user_id]) || User.verify_production(session[:user_id])
  end

  def paginate_with_sort(collection_id, options={})
    order = (params[:order].nil?) ? 'id': params[:order]
    options[:order] = order if options[:order].nil?
    paginate collection_id, options
  end

  def user_id()
    user_izishirt = User.find_by_username("izishirt")

    if (@check_user_is_artwork_manager || user_izishirt.id == session[:user_id]) && session[:emulated_user_id] && session[:emulated_user_id].to_i > 0
      return session[:emulated_user_id]
    end
    
    staff = get_staff()
    
    if staff
      return staff.printer
    end

    return session[:user_id]
  end

  def mestizo_id
    return User.find_by_username("mestizo").id
  end
  
  private
  
  def get_staff
    begin
      return User.find(session[:user_id]).staff
    rescue
      return nil
    end
  end
end
