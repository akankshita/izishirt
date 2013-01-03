# create_tshirt.rss.builder
xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    if !@product.nil?
      xml.title "#{t(:product_title_rss, :product=>@product.name)}"
      xml.description "#{t(:product_description_rss, :product=>@product.name)}"
      xml.link "#{@URL_ROOT}#{create_tshirt_product_url(@product.id)}"
    elsif !@design_rss.nil?
      xml.title "#{t(:design_title_rss, :design_rss => @design_rss.name)}"
      xml.description "#{t(:design_description_rss, :design_rss => @design_rss.name)}"
      xml.link "#{@URL_ROOT}#{design_url(@design_rss.id)}"
    end
    
    if !@product.nil?
      xml.item do
        xml.title "#{@product.name} T-Shirt"
        xml.link "#{@URL_ROOT}#{create_tshirt_product_url(@product.id)}"
        xml.description "<a href='#{@URL_ROOT}#{create_tshirt_product_url(@product.id)}' title='#{get_title_link_adding(@product.images[0].name, t(:seo_word_0))}'><img alt='#{get_title_link_adding(@product.images[0].name, t(:seo_word_0))}' src='#{@URL_ROOT}#{@product.front}'/></a>"
        #xml.pubDate article.created_at.to_s(:rfc822)
        #xml.guid formatted_article_url(article, :rss)
    
      end
      
    elsif !@design_rss.nil?
      xml.item do
        xml.title "#{@design_rss.name} T-Shirt"
        xml.link "#{@URL_ROOT}#{design_url(@design_rss.id)}"
        xml.description "<a href='#{@URL_ROOT}#{design_url(@design_rss.id)}' title='#{get_title_link_adding(@design_rss.name, t(:seo_word_0))}'><img alt='#{get_title_link_adding(@design_rss.name, t(:seo_word_0))}' src='#{@URL_ROOT}#{@design_rss.orig_image.url("100")}'/></a>"
        xml.pubDate @design_rss.created_on.to_s(:rfc822)
        #xml.guid formatted_article_url(article, :rss)
    
      end
    end
      
      @top_designs.each do |image|
         xml.item do
           xml.title "#{image.name} T-Shirt"
           xml.description "<a href='#{@URL_ROOT}#{design_url(image.id)}' title='#{get_title_link_adding(image.name, t(:seo_word_0))}'><img alt='#{get_title_link_adding(image.name, t(:seo_word_0))}' src='#{@URL_ROOT}#{image.orig_image.url("100")}'/></a>"
           xml.link "#{@URL_ROOT}#{design_url(image.id)}"
        end
      end   
  end
end