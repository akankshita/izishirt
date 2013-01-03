class Admin::CityController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :update ],
         :redirect_to => { :action => :list }

  def list
    @cities = City.find(:all, :order => "name")
    
  end

  def new
    @city = City.new
	@provinces = Province.find(:all, :order => "name")
    
  end

  def edit    
    @city = City.find(params[:id])
	@provinces = Province.find(:all, :order => "name")
    
  end
  
  def create
      
	if params[:name].to_s =="" or params[:url].to_s =="" or params[:name_en].to_s ==""
		flash[:notice] = "Error!! You must enter the city's name and the url"
		redirect_to :action => 'new',:province_id => params[:province_id], :name => params[:name], :name_en => params[:name_en], :url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]
	else 
		@city_new = City.new({:province_id => params[:province_id], :name => params[:name], :name_en => params[:name_en], :url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]})
		@city_new.save
		flash[:notice] = "City created successfully"
		@cities = City.find(:all, :order => "name")
		redirect_to :action => 'list'
	end
	
  end

  def update
    @city = City.find(params[:id])
	if params[:name].to_s =="" or params[:url].to_s =="" or params[:name_en].to_s ==""
		flash[:notice] = "Error!! You must enter the city's name and the url"
        redirect_to :action => 'edit',:id => params[:id],:province_id => params[:province_id], :name => params[:name], :name_en => params[:name_en], :url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]
    else 
        @city.province_id = params[:province_id]
		@city.name = params[:name]
		@city.name_en = params[:name_en]
		@city.url = params[:url]
		@city.title_fr = params[:title_fr]
		@city.metadesc_fr = params[:metadesc_fr]
		@city.keywords_fr = params[:keywords_fr]
		@city.title_en = params[:title_en]
		@city.metadesc_en = params[:metadesc_en]
		@city.keywords_en = params[:keywords_en]
		@city.title_us = params[:title_us]
		@city.metadesc_us = params[:metadesc_us]
		@city.keywords_us = params[:keywords_us]
        if @city.save
			flash[:notice] = "City updated successfully"
			redirect_to :action => 'list'
		else 
			flash[:notice] = "Error!! Please try again."
			redirect_to :action => 'edit',:id => params[:id],:province_id => params[:province_id], :name => params[:name], :name_en => params[:name_en], :url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]
		end
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

  
end
