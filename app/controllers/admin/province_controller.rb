class Admin::ProvinceController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :update ],
         :redirect_to => { :action => :list }

  def list
    @provinces = Province.find(:all, :order => "country_id")
    
  end

  def new
    @province = Province.new
    
  end

  def edit    
    @province = Province.find(params[:id])
    
  end
  

  def update
    @province = Province.find(params[:id])
	if params[:name].to_s =="" || params[:name].to_s ==""
		flash[:notice] = "Error!! all fields are requied"
        redirect_to :action => 'edit',:id => params[:id], :name => params[:name], :country_id => params[:country_id], :code => params[:code], :taxe => params[:taxe]
    else 
		@province.name = params[:name]
		@province.country_id = params[:country_id]
		@province.code = params[:code]
		@province.taxe = params[:taxe]
		
        if @province.save
			flash[:notice] = "Information saved successfully"
			@provinces = Province.find(:all, :order => "country_id")
			redirect_to :action => 'list'
		else 
			flash[:notice] = "Error!! Please try again."
			redirect_to :action => 'edit',:id => params[:id], :name => params[:name], :country_id => params[:country_id], :code => params[:code], :taxe => params[:taxe]
		end
    end
    
  end

  # If a category is destroyed and it has sub categories set the
  # sub categories parent category to parent category, or none
  # if destroyed category has no parent
  def destroy
    province = Province.find(params[:id])
    province.destroy
	@provinces = Province.find(:all, :order => "country_id")
    redirect_to :action => 'list'
  end

  
end
