# izishirt_2011.rss.builder
xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title t(:izishirt_2011_title_rss)
    xml.description t(:izishirt_2011_description_rss)
    xml.link "#{@URL_ROOT}"
    
    
    @top_categories.each do |category|
      category.products.each do |product|
        xml.item do
          xml.title get_title_link_adding(product.images[0].name, t(:seo_word_0))
          xml.link "#{@URL_ROOT}#{create_tshirt_product_url(product.id)}"
          xml.description "<a href='#{@URL_ROOT}#{create_tshirt_product_url(product.id)}' title='#{get_title_link_adding(product.images[0].name, t(:seo_word_0))}'><img alt='#{get_title_link_adding(product.images[0].name, t(:seo_word_0))}' src='#{@URL_ROOT}#{product.front}'/></a>"
          
          xml.image do
            xml.url "#{@URL_ROOT}#{product.front}"
            xml.title get_title_link_adding(product.images[0].name, t(:seo_word_0))
            xml.link "#{@URL_ROOT}#{create_tshirt_product_url(product.id)}"
          end
          #we have to add a column in the products table to be able to tell when we updated the product - Louis-Pierre
          #xml.pubDate product.updated_at.to_s(:rfc822)
        end
      end
    end
  end
end