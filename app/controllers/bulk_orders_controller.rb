class BulkOrdersController < ApplicationController

  before_filter :set_title


  def index

	logger.error("#{request.url}")

	if request.url.index("bulk_orders")
		redirect_to "/" + t(:new_bulk_main_url), :status => :moved_permanently
		return
	end

    redirect_to :controller => 'display', :action => 'create_tshirt' if session[:country] != 'CA' && session[:country] != 'FR' && session[:country] != 'US'

	@meta_title = t(:new_bulk_bulk_meta_title, :country_name => session[:country_long], :country => get_country_for_meta_title)
	@meta_description = t(:new_bulk_bulk_meta_description, :country => session[:country_long])

   # @bulk_order = BulkOrder.new
  end
  
	def screen_printing
		@meta_title = t(:screenprint_meta_title, :country => session[:country_long])
		@meta_description = t(:screenprint_meta_description, :country => session[:country_long])
	end
  

  def advanced
    if params[:session]
      @bulk_order = session[:bulk_order]
      @nb_garments = session[:bulk_order_nb_garments]
      @bulk_order.bulk_orders_garments = @bulk_order.bulk_orders_garments.first(@nb_garments)
      for garment in @bulk_order.bulk_orders_garments
        for print in garment.bulk_orders_garments_prints
          begin
            image = BulkOrdersGarmentsPrintsImage.find(print.bulk_orders_garments_prints_image_id)
          rescue
          end
          if image
            print.bulk_orders_garments_prints_image = BulkOrdersGarmentsPrintsImage.new
          else
            print.bulk_orders_garments_prints_image = BulkOrdersGarmentsPrintsImage.new
          end

        end
        create_bulk_orders_garments_prints(garment, 4 - garment.bulk_orders_garments_prints.size)

      end
      while @bulk_order.bulk_orders_garments.size < 9
        new_garment = BulkOrdersGarment.new
        create_bulk_orders_garments_prints(new_garment)
        @bulk_order.bulk_orders_garments << new_garment   
      end
    else
      @bulk_order = BulkOrder.new
      create_bulk_orders_garments(@bulk_order)
      @nb_garments = 1
    end
    

    @models_select = LocalizedModel.find_all_by_language_id(session[:language_id], :order=>:name).map{|m| [m.name, m.model_id]}
    @model_types_select = LocalizedModelType.find_all_by_language_id(session[:language_id], :order=>:id).map{|m| [m.name, m.model_type_id]}
    @brands_select = LocalizedCategory.find_all_by_language_id(session[:language_id], :joins=>:category, :conditions=>"categories.category_type_id=4", :order=>:name).map {|c| [c.name, c.category_id]}
    @colors_select = LocalizedColor.find_all_by_language_id(session[:language_id], :include=>:color, :conditions=>["colors.color_type_id=3 and colors.active=1"], :order=>:name).map{|c| [c.name, c.color_id]}
    @print_types_select = LocalizedPrintType.find_all_by_language_id(session[:language_id], :order=>:name).map{|p| [p.name, p.print_type_id]}
    @units_select = LocalizedUnit.find_all_by_language_id(session[:language_id], :order=>:name).map{|u| [u.name, u.unit_id]}

  end

  def create
    params[:bulk_order][:wants_newsletter] = params[:bulk_order][:wants_newsletter] == "on"
    params[:bulk_order][:contact_by_phone] = params[:bulk_order][:contact_by_phone] == "on"
    params[:bulk_order][:contact_by_email] = params[:bulk_order][:contact_by_email] == "on"

    @bulk_order = params[:bulk_order]    
 
    begin
      SendMail.deliver_bulk_order_request(@bulk_order)
    rescue
    end

    #begin
      SendMail.deliver_bulk_order_details_request(@bulk_order)
  # rescue
   # end

    redirect_to :action=>:confirmation
  end

  def confirmation
    @confirmation = true
  end


  def summarize
    @bulk_order = BulkOrder.new(params[:bulk_order])
    @bulk_order.language_id = session[:language_id]

    nb_garments = params[:nbGarments].to_i - 1
    #@bulk_order.build_garments(nb_garments)

    if session[:bulk_order]
      old_bulk = session[:bulk_order]
    end
    trim_garments(@bulk_order, nb_garments, old_bulk)
    params[:bulk_order]=nil
    session[:bulk_order] = @bulk_order
    session[:bulk_order_nb_garments] = @bulk_order.bulk_orders_garments.size

    redirect_to :action=>:summary
  end

  def summary
    @bulk_order = session[:bulk_order]
    
  end

  def create_advanced
    bulk_order = session[:bulk_order]
    bulk_order.save
    SendMail.deliver_bulk_order_request(bulk_order)
    session[:bulk_order]= nil
    redirect_to :action=>:confirmation
  end

  private


  def set_title
    @meta_title = t(:meta_title_bulk_orders)
  end

  def create_bulk_orders_garments(bulk_order)
    9.times {|i|
      bulk_order.bulk_orders_garments.build
      create_bulk_orders_garments_prints(bulk_order.bulk_orders_garments[i])
    }
  end

  def create_bulk_orders_garments_prints(bulk_orders_garment, amount=4)
    amount.times{ |i|
      bulk_orders_garment.bulk_orders_garments_prints.build
      create_bulk_orders_garments_prints_image(bulk_orders_garment.bulk_orders_garments_prints[4-amount+i])
    }
  end

  def create_bulk_orders_garments_prints_image(bulk_orders_garments_print)
    bulk_orders_garments_print.bulk_orders_garments_prints_image = BulkOrdersGarmentsPrintsImage.new
  end

  def trim_prints(bulk_orders_garment, old_garment = nil)
    bulk_orders_garment.bulk_orders_garments_prints = bulk_orders_garment.bulk_orders_garments_prints.first(bulk_orders_garment.nb_prints)

    i = 0
    for print in bulk_orders_garment.bulk_orders_garments_prints
      if print.bulk_orders_garments_prints_image.nil? && old_garment.nil?
        i = i+1
        next
      end
      if print.bulk_orders_garments_prints_image
        print.bulk_orders_garments_prints_image.save
        id_image =  print.bulk_orders_garments_prints_image.id
      elsif old_garment
        begin
          id_image = old_garment.bulk_orders_garments_prints[i].bulk_orders_garments_prints_image_id
        rescue
        end
      end
      print.bulk_orders_garments_prints_image = nil
      print.bulk_orders_garments_prints_image_id = id_image
      i = i+1
    end
  end

  def trim_garments(bulk_order, nb_garments, old_bulk=nil)
    nb_garments.times { |i|
      if old_bulk && old_bulk.bulk_orders_garments[i]
        old_garment = old_bulk.bulk_orders_garments[i]
      end
      trim_prints(bulk_order.bulk_orders_garments[i], old_garment)
    }
    bulk_order.bulk_orders_garments = bulk_order.bulk_orders_garments.first(nb_garments)
  end

end
