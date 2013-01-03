class Admin::HomepagetextController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :update ],
         :redirect_to => { :action => :list }

  def list
    @homepagetexts = Homepagetext.find(:all)
    
  end

  def new
    @homepagetext = Homepagetext.new
    
  end

  def edit    
    @homepagetext = Homepagetext.find(params[:id])
    
  end
  
  def create
      
		@seoinfo_new = Seoinfo.new({:title_fr => params[:title_fr], :content_fr => params[:content_fr], :title_en => params[:title_en], :content_en => params[:content_en], :title_us => params[:title_us], :content_us => params[:content_us]})
		@seoinfo_new.save
		flash[:notice] = "Information saved successfully"
		@seoinfos = Seoinfo.find(:all)
		redirect_to :action => 'list'
		
  end

  def update
    @homepagetext = Homepagetext.find(params[:id])
 
        @homepagetext.title_fr = params[:title_fr]
		@homepagetext.metadesc_fr = params[:metadesc_fr]
		@homepagetext.keywords_fr = params[:keywords_fr]
		@homepagetext.title_en = params[:title_en]
		@homepagetext.metadesc_en = params[:content_en]
		@homepagetext.title_us = params[:title_us]
		@homepagetext.metadesc_us = params[:content_us]
        if @homepagetext.save
			flash[:notice] = "Information saved successfully"
			@homepagetexts = Homepagetext.find(:all)
			redirect_to :action => 'list'
		else 
			flash[:notice] = "Error!! Please try again."
			redirect_to :action => 'edit',:id => params[:id], :title_fr => params[:title_fr], :content_fr => params[:content_fr], :title_en => params[:title_en], :content_en => params[:content_en], :title_us => params[:title_us], :content_us => params[:content_us]
		end
        
  end

  # If a category is destroyed and it has sub categories set the
  # sub categories parent category to parent category, or none
  # if destroyed category has no parent
  def destroy
    homepagetext = Homepagetext.find(params[:id])
    homepagetext.destroy
	@homepagetexts = Homepagetext.find(:all)
    redirect_to :action => 'list'
  end

  
end
