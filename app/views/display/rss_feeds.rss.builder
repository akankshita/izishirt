# index.rss.builder
xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title t(:recent_designs_title_rss)
    xml.description t(:recent_designs_description_rss)
    xml.link "#{@URL_ROOT}"
    
    @images.each do |image|
      xml.item do
        xml.title "#{image.name} T-Shirt"
        xml.link "#{@URL_ROOT}#{design_url(image.id)}"
        xml.description "<a href='#{@URL_ROOT}#{design_url(image.id)}' title='#{get_title_link_adding(image.name, t(:seo_word_0))}'><img alt='#{get_title_link_adding(image.name, t(:seo_word_0))}' src='#{@URL_ROOT}#{image.orig_image.url("100")}'/></a>"
        xml.pubDate image.created_on.to_s(:rfc822)
        #xml.guid formatted_article_url(article, :rss)
      end
    end
  end
end