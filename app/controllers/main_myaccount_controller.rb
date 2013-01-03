# Filters added to this controller apply to all controllers in the admin section.
# Likewise, all the methods added will be available for all those controllers. (app/controllers/admin/...)

class MainMyaccountController < ApplicationController
  before_filter :prepare_my_izishirt, :except => [:refresh_products_index, :display_subcategories,
    #TODO: Move these actions to a new controller that doesn't extend this one
    :create_theme, :edit_banner, :edit_frame, :edit_tshirt_info, :edit_main_body, :edit_mainbg, :edit_contentbg,
    :edit_header, :edit_cart_header, :edit_cat_header, :edit_avatar_header, :edit_links_header, :edit_stats_header, :edit_blog_header,
    :edit_cart, :edit_categories, :edit_avatar, :edit_links, :edit_stats, :edit_flick, :edit_blog, :edit_menu, :edit_name,
    :edit_name_and_continue, :update_section, :switch_layout, :reset_theme, :delete_theme, :update_theme, 
    :activate_theme, :update_theme_and_continue, :upload_background, :upload_image,:change_category]

  before_filter :very_basic_prepare_my_izishirt, :only => [:refresh_products_index]


  layout 'myaccount'

  def very_basic_prepare_my_izishirt
   	begin
	      @user = User.find(session[:user_id], :include=>[:profile])
	rescue
	end
  end

  def prepare_my_izishirt
    @in_my_izishirt = true

	@currency_symbol = get_currency_symbol


    begin
      @user = User.find(session[:user_id], :include=>[:profile])
      @profile = @user.profile
      @profile_img = @profile.picture ? @profile.picture : 'noavatar.gif'

      @orders = Order.find_all_by_user_id(@user.id)

      #Append decimal point to number before it used for nice display

    rescue Exception => e
      @total_sales = 0.0
      logger.error("e = #{e}")
    end
  end

  def prepare_upload(category)
    tmp_categories = Category.active_parent_categories(3).select{|c| ! c.is_custom_category }

    @categories = [[t(:front_office_myizishirt_select_category), 0]] | tmp_categories.map{|c|
      [c.local_name(session[:language_id]), c.id]
    }

    @first_parent_id = nil

    begin
      @first_parent = category.parent_categories.first

      if @first_parent
        @first_parent_id = @first_parent.id
        @subcategories = @first_parent.sub_categories.map { |c| [c.local_name(session[:language_id]), c.id] }
      else
        @first_parent = category

        if @first_parent
          @first_parent_id = @first_parent.id
          @subcategories = [@first_parent].map { |c| [c.local_name(session[:language_id]), c.id] }
        end
      end
    rescue
      @subcategories = [[t(:front_office_myizishirt_select_sub_category), 0]]
    end



    @preview = ""
  end

  private

  def my_izishirt_display_subcategories
    begin
      @subcategories = Category.sub_categories(params[:parent]).map{|c|
        [c.local_name(session[:language_id]), c.id]
      }
      if @subcategories.length == 0
        c = Category.find(params[:parent])
        @subcategories << [c.local_name(session[:language_id]), c.id]
      end
    rescue
      @subcategories = [[t(:front_office_myizishirt_select_sub_category), 0]]
    end
  end
end
