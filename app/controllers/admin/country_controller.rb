class Admin::CountryController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :update ],
         :redirect_to => { :action => :list }

  def list
    @countries = Country.find(:all, :order => "name")
    
  end

  def new
    @country = Country.new
    
  end

  def edit    
    @country = Country.find(params[:id])
    
  end
  

  def update
    @country = Country.find(params[:id])
	if params[:name].to_s =="" || params[:name].to_s ==""
		flash[:notice] = "Error!! all fields are requied"
        redirect_to :action => 'edit',:id => params[:id], :name => params[:name], :shortname => params[:shortname], :tax => params[:tax]
    else 
		@country.name = params[:name]
		@country.shortname = params[:shortname]
		@country.tax = params[:tax]
		
        if @country.save
			flash[:notice] = "Information saved successfully"
			@countries = Country.find(:all, :order => "name")
			redirect_to :action => 'list'
		else 
			flash[:notice] = "Error!! Please try again."
			redirect_to :action => 'edit',:id => params[:id], :name => params[:name], :shortname => params[:shortname], :tax => params[:tax]
		end
    end
    
  end

  # If a category is destroyed and it has sub categories set the
  # sub categories parent category to parent category, or none
  # if destroyed category has no parent
  def destroy
    country = Country.find(params[:id])
    country.destroy
	@countries = Country.find(:all, :order => "name")
    redirect_to :action => 'list'
  end

  
end
