class Admin::SeoinfoController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :update ],
         :redirect_to => { :action => :list }

  def list
    @seoinfos = Seoinfo.find(:all, :order => "url")
    
  end

  def new
    @seoinfo = Seoinfo.new
    
  end

  def edit    
    @seoinfo = Seoinfo.find(params[:id])
    
  end
  
  def create
      
	if params[:url].to_s ==""
		flash[:notice] = "Error!! You must enter the page's url"
		redirect_to :action => 'new',:url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_frch => params[:title_frch], :metadesc_frch => params[:metadesc_frch], :keywords_frch => params[:keywords_frch], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]
	else 
		@seoinfo_new = Seoinfo.new({:url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]})
		@seoinfo_new.save
		flash[:notice] = "Information saved successfully"
		@seoinfos = Seoinfo.find(:all, :order => "url")
		redirect_to :action => 'list'
	end
	
  end

  def update
    @seoinfo = Seoinfo.find(params[:id])
	if params[:url].to_s ==""
		flash[:notice] = "Error!! You must enter the page's url"
        redirect_to :action => 'edit',:id => params[:id], :url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_frch => params[:title_frch], :metadesc_frch => params[:metadesc_frch], :keywords_frch => params[:keywords_frch], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]
    else 
        @seoinfo.url = params[:url]
		@seoinfo.title_fr = params[:title_fr]
		@seoinfo.metadesc_fr = params[:metadesc_fr]
		@seoinfo.keywords_fr = params[:keywords_fr]
		@seoinfo.title_frch = params[:title_frch]
		@seoinfo.metadesc_frch = params[:metadesc_frch]
		@seoinfo.keywords_frch = params[:keywords_frch]
		@seoinfo.title_en = params[:title_en]
		@seoinfo.metadesc_en = params[:metadesc_en]
		@seoinfo.keywords_en = params[:keywords_en]
		@seoinfo.title_us = params[:title_us]
		@seoinfo.metadesc_us = params[:metadesc_us]
		@seoinfo.keywords_us = params[:keywords_us]
        if @seoinfo.save
			flash[:notice] = "Information saved successfully"
			@seoinfos = Seoinfo.find(:all, :order => "url")
			redirect_to :action => 'list'
		else 
			flash[:notice] = "Error!! Please try again."
			redirect_to :action => 'edit',:id => params[:id], :url => params[:url], :title_fr => params[:title_fr], :metadesc_fr => params[:metadesc_fr], :keywords_fr => params[:keywords_fr], :title_frch => params[:title_frch], :metadesc_frch => params[:metadesc_frch], :keywords_frch => params[:keywords_frch], :title_en => params[:title_en], :metadesc_en => params[:metadesc_en], :keywords_en => params[:keywords_en], :title_us => params[:title_us], :metadesc_us => params[:metadesc_us], :keywords_us => params[:keywords_us]
		end
    end
    
  end

  # If a category is destroyed and it has sub categories set the
  # sub categories parent category to parent category, or none
  # if destroyed category has no parent
  def destroy
    seoinfo = Seoinfo.find(params[:id])
    seoinfo.destroy
	@seoinfos = Seoinfo.find(:all, :order => "url")
    redirect_to :action => 'list'
  end

  
end
