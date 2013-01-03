class Admin::CategoryController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :update ],
         :redirect_to => { :action => :list }

  def list
    #Get list of all parent categories
    where = ["category_type_id = :catid and (select count(category_id) from sub_categories where sub_category_category_id = id) = 0", {:catid => params[:id]}] if params[:id]    
    @categories = Category.paginate(:per_page => ITEMS_PER_PAGE, :page=>params[:page], :conditions => where, :order => :position)
    @types = [ CategoryType.new({ :name=>'all' }) ] + CategoryType.find(:all)
    @category_type_id = params[:id]
  end

  def new
    @category = Category.new
    @category.category_type_id = params[:id]

    where = ["category_type_id = :type and (select count(category_id) from sub_categories where sub_category_category_id = categories.id) = 0", {:type => params[:id]}]
    @categories = Category.find(:all, :conditions => where)

    if params[:parent_category]
      @parent = params[:parent_category]
    else
      @parent = "None"
    end
    @types = CategoryType.find(:all).map {|t| [t.name, t.id] }
    for lang in Language.find :all
  	  @category.localized_categories << LocalizedCategory.new({:category_id => @category.id, :language_id => lang.id})
  	end
  end

  def new_image_category
    @localized_category = LocalizedCategory.find(params[:id])

    @list_currencies = Currency.all.collect{|currency| [currency.label, currency.id]}

    @localized_image_category = LocalizedImageCategory.find_by_localized_category_id(params[:id])

    if ! @localized_image_category
      @localized_image_category = LocalizedImageCategory.create({:localized_category_id => params[:id]})
    end

    @localized_currency_image_category = LocalizedCurrencyImageCategory.new

    @language = Language.find(@localized_category.language_id).name
  end

  def create_image_category
    localized_category = LocalizedCategory.find(params[:id])

    begin
      LocalizedCurrencyImageCategory.create(params[:localized_currency_image_category])

      flash[:notice] = t(:admin_flash_created)
      redirect_to :action => 'edit', :id => localized_category.category_id
    rescue
      flash[:notice] = "Failed to add the image"
      redirect_to :action => 'new_image_category', :id => localized_category.id
    end
  end

  def active_image_category
    @active = LocalizedCurrencyImageCategory.find(params[:id])
    if @active.active
      @active.update_attributes(:active => 0)
    elsif !@active.active
      @active.update_attributes(:active => 1)
    end

    redirect_to :action => 'edit', :id => @active.localized_image_category.localized_category.category_id
  end

  def destroy_image_category
    category = LocalizedCurrencyImageCategory.find(params[:id])
    category.destroy

    redirect_to :action => 'edit', :id => params[:category_id]
  end

  def create
      @category = Category.new(params[:category])
      @languages = Language.find :all
      for lang in @languages
          @category.localized_categories << LocalizedCategory.new({:name => params["localized_name_#{lang.id}"], :language_id => lang.id})
      end
      if params[:parent_category] && params[:parent_category].to_s != "None"
          @category.parent_categories = [Category.find_by_id(params[:parent_category])]            
      end
         
      if @category.localized_categories.size == @languages.size && @category.save
         flash[:notice] = t(:admin_flash_created)
         if params[:parent_category] && params[:parent_category].to_s != "None"
            redirect_to :action => 'edit', :id => params[:parent_category]
         else 
            redirect_to :action => 'list', :id => @category.category_type_id
         end
      else
         flash[:notice] = "Please fill out the name for each language!"
         redirect_to :action => 'new', :id => params[:id], :parent_category => params[:parent_category]
      end
  end
  
  def edit    
    @category = Category.find(params[:id])
    where = ["category_type_id = :type and (select count(category_id) from sub_categories where sub_category_category_id = categories.id) = 0", {:type => @category.category_type_id}]
    @categories = Category.find(:all, :conditions => where)
    if @category.parent_categories != []
      @parent = @category.parent_categories[0].id
    else
      @parent = "None"
    end
    @types = CategoryType.find(:all).map {|t| [t.name, t.id] }
  end

  def update
    @category = Category.find(params[:id])
    if params[:parent_category] && params[:parent_category].to_s != params[:id]
       if params[:parent_category].to_s == "None"
          @category.parent_categories = []
       else
          @parent = Category.find(params[:parent_category].to_s)
          @category.parent_categories = [@parent]
       end
       @category.save
    end
    for cat in @category.localized_categories
      cat.name = params["localized_name_#{cat.language_id}"]
      cat.meta_title = params["localized_meta_title_#{cat.language_id}"]
      cat.meta_description = params["localized_meta_description_#{cat.language_id}"]
      cat.meta_keywords = params["localized_meta_keywords_#{cat.language_id}"]
      cat.search_str = params["localized_search_str_#{cat.language_id}"]
      cat.save
    end
    
    if @category.update_attributes(params[:category])
      flash[:notice] = t(:admin_flash_updated)
      redirect_to :action => 'list', :id => @category.category_type_id
    else
      render :action => 'edit'
    end
  end

  # If a category is destroyed and it has sub categories set the
  # sub categories parent category to parent category, or none
  # if destroyed category has no parent
  def destroy
    category = Category.find(params[:id])
    type = category.category_type_id
    @sub_categories = category.sub_categories
    @parent_categories = category.parent_categories
    if @sub_categories != []
      @sub_categories.each do |sub_cat|
         if @parent_categories != []
            sub_cat.parent_categories = [@parent_categories[0]]
         else
            sub_cat.parent_categories = []
         end
      end
    end      
    category.destroy
    redirect_to :action => 'list', :id => type
  end

  # Move Up the current category
  def move_up
    move(true)

    redirect_to :back
  end

  # Move Down the current category
  def move_down
    move(false)

    redirect_to :back
  end
     
  def sort
    @category_type = CategoryType.find(params[:id])
    @category_type.category.each do |cat|
      cat.position = params['categories'].index(cat.id.to_s) + 1
      cat.save
    end
    render :nothing => true
  end
  
  def active
    @active = Category.find(params[:id])
    if @active.active
      @active.update_attributes(:active => 0)      
    elsif !@active.active
      @active.update_attributes(:active => 1) 
    end
    redirect_to :action => 'list', :id => @active.category_type_id
  end
  
  def wholesale
    @wholesale = Category.find(params[:id])
    if @wholesale.wholesale
      @wholesale.update_attributes(:wholesale => 0)      
    elsif !@wholesale.wholesale
      @wholesale.update_attributes(:wholesale => 1) 
    end
    redirect_to :action => 'list', :id => @wholesale.category_type_id
  end  

  private
  # Swap two category positions
  def move_change_position(collection, category, cur_index, move_up)
    movement = (move_up) ? (- 1) : 1

    cur_position = category.position
    to_position = collection[cur_index + movement].position

    other_category = collection[cur_index + movement]

    Category.update(category.id, :position => to_position)
    Category.update(other_category.id, :position => cur_position)
  end

  # Move the current category Up or Down
  def move(move_up)
    category = Category.find(params[:id])
    category_type_id = params[:category_type_id]

    parents = category.parent_categories

    if parents != []
      parent = parents[0]

      limit = (move_up) ? 0 : parent.sub_categories.length - 1
      cur_index = parent.sub_categories.index(category)

      if cur_index != limit
        move_change_position(parent.sub_categories, category, cur_index, move_up)
      end
    else
      # Parent category
      parents = Category.find(:all,
              :conditions => ["category_type_id = #{category_type_id} AND NOT EXISTS (SELECT * FROM sub_categories WHERE sub_category_category_id = categories.id )"],
              :order => "position")

      limit = (move_up) ? 0 : parents.length - 1
      cur_index = parents.index(category)

      if cur_index != limit
        move_change_position(parents, category, cur_index, move_up)
      end
    end
  end
end
