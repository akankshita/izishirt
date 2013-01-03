class LandingPageController < ApplicationController
  def index
    render :layout => false
  end

  def products
    if Category.exists?(params[:id])
      @products = Category.find(params[:id]).products
    else
      @products = []
    end
    @products = prepare_products(@products)
    respond_to do |format|
      format.html #
      format.xml { render :xml => @products } 
    end
  end

  def featured_product
    @featured_product = User.find_by_username("landingpages").store.featured_product
    @featured_product = [] if !@featured_product
    @featured_product = prepare_products([@featured_product].flatten)
    respond_to do |format|
      format.html #
      format.xml { render :xml => @featured_product } 
    end
  end
  
  private

  def prepare_products(prods)
    prods.map{|product|
      { :id => product.id,
        :thumb_front => "#{@URL_ROOT}/#{product.thumb_front}",
        :thumb_back => "#{@URL_ROOT}/#{product.thumb_back}",
        :front => "#{@URL_ROOT}/#{product.front}",
        :back =>  "#{@URL_ROOT}/#{product.back}",
        :buy_link => "#{@URL_ROOT}/create-custom-t-shirt/product/#{product.id}",
        :name => product.name,
        :description => product.description,
        :price => product.price,
        :tags => product.tag_links
      }
    }
  end
end
