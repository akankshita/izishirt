class Admin::ColorController < Administration
    
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    list
    render :action => 'list'
  end

  def list   
	where = ["colors.color_type_id  = :typeid", {:typeid => params[:id]}] if params[:id]
    @colors = Color.paginate :per_page => ITEMS_PER_PAGE, :conditions => where, :order => params[:order], :page => params[:page]
    @types = ColorType.find(:all)											
  end

  def new
    @color = Color.new({ :color_type_id => params[:id] })
    for lang in Language.find :all
  	  @color.localized_colors << LocalizedColor.new({:color_id => @color.id, :language_id => lang.id})
  	end
    
    @redirect = params[:redirect]

  	populate_dropdowns
  end

  def create
    @color = Color.new(params[:color])
	  
	  languages = Language.find :all
	  languages.each_with_index { |l,idx|
	    @color.localized_colors << LocalizedColor.new({:language_id => l.id, :name => params["localized_name_#{idx + 1}"]})
	  }
	
    @color.preview_image = "defaut.png" 	
	
    if @color.save

      flash[:notice] = t(:admin_flash_created)
      
      if params[:redirect]
        redirect_to params[:redirect]
      else
        redirect_to :action => 'list', :id => @color.color_type_id
      end
      
    else
	    populate_dropdowns 
      render :action => 'new', :redirect => params[:redirect]
    end
  end

  def edit
    @color = Color.find(params[:id])
    populate_dropdowns
  end
  
  def update_preview_image(color)
    if color.uploaded_image
      color.preview_image = color.uploaded_image.original_filename 
    else
      color.preview_image = "defaut.png"   
    end
    
    return color.save
  end

  def update
    @color = Color.find(params[:id])

    for lc in @color.localized_colors do
      lc.name = params["localized_name_#{lc.language_id}"]
      lc.save
    end
	  
    if @color.update_attributes(params[:color])
      
      flash[:notice] = t(:admin_flash_updated)
      redirect_to :action => 'list', :id => @color.color_type_id
    else
      render :action => 'edit'
    end		
  end

  def destroy
    @color = Color.find(params[:id]) 
	  idcolortype = @color.color_type_id

    @color.destroy
    redirect_to :action => 'list' , :id => idcolortype
  end

  def search
    where = [ "color_type_id = :type_id AND (EXISTS (SELECT * FROM localized_colors lc WHERE lc.name like :search AND colors.id = lc.color_id) OR " + 
              "colors.color_code LIKE :search)", 
      { :type_id => params[:id], :search => '%' + params[:search].to_s + '%' } ]

    @colors = Color.paginate :per_page => ITEMS_PER_PAGE, :conditions => where, :order => params[:order], :page => params[:page]
    @types = ColorType.find(:all) 
    
    render :action => "list"
  end
  
   def active
    @active = Color.find(params[:id])
    if @active.active
      @active.update_attributes(:active => 0)      
    elsif !@active.active
      @active.update_attributes(:active => 1) 
    end
    redirect_to :action => 'list', :id => @active.color_type_id
  end  

	def fix_broken_colors
		colors = Color.find_all_by_preview_image("Missing")
	end
  
  private
  
  
  def populate_dropdowns
    @type = ColorType.find(:all).map {|t| [t.name, t.id] }	
  end
end
