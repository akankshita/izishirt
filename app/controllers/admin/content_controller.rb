class Admin::ContentController < Administration
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @contents = Content.paginate :per_page => ITEMS_PER_PAGE, :page => params[:page], :order => params[:order]
  end

  def new
    @content = Content.new
    @levels = UserLevel.find(:all).map {|l| [l.name, l.id]}
    for language in Language.find(:all)
      @content.localized_contents << LocalizedContent.new({ :content_id => @content.id, :language_id => language.id }) 
    end
  end

  def create
    @content = Content.new(params[:content])
    
    for language in Language.find(:all)

      @content.localized_contents << LocalizedContent.new({ 
          :language_id => language.id, 
          :value => params["localized_content_#{language.id}"],
          :url => params["localized_url_#{language.id}"],
          :title => params["localized_title_#{language.id}"],
          :meta_title => params["localized_meta_title_#{language.id}"],
          :meta_keywords => params["localized_meta_keywords_#{language.id}"],
          :meta_description => params["localized_meta_description_#{language.id}"],
          :left_column => params["localized_left_column_#{language.id}"]
      })
    end
    
    if @content.save
      flash[:notice] = t(:admin_flash_created)
      redirect_to :action => 'list'
    else

      @content.errors.each do |f, msg|
        logger.error("f = #{msg}")
      end

      redirect_to :back
    end
  end

  def edit
    @content = Content.find(params[:id])
    @levels = UserLevel.find(:all).map {|l| [l.name, l.id]}
  end

  def update
    @content = Content.find(params[:id])

    for lc in @content.localized_contents
      logger.error("lc -> = #{lc.id}")
      lc.value = params["localized_content_#{lc.language.id}"]
      lc.url = params["localized_url_#{lc.language.id}"]
      lc.title = params["localized_title_#{lc.language.id}"]
      lc.meta_keywords = params["localized_meta_keywords_#{lc.language.id}"]
      lc.meta_description = params["localized_meta_description_#{lc.language.id}"]
      lc.meta_title = params["localized_meta_title_#{lc.language.id}"]
      lc.left_column = params["localized_left_column_#{lc.language.id}"]
      lc.save
    end
    
    if @content.update_attributes(params[:content])
      flash[:notice] = t(:admin_flash_updated)
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Content.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def search
    where = [ "(name like :search_term)", { :search_term => '%' + params[:search].to_s + '%' } ]
    @contents = Content.paginate :per_page => ITEMS_PER_PAGE, :conditions => where, :page => params[:page], :order => params[:order]
    
    render :action => "list"
  end
end
