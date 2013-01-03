class RemoteLinkRenderer < WillPaginate::LinkRenderer  
 def prepare(collection, options, template)    
  #@remote = options.delete(:remote) || {}  #(1)
  options.delete(:remote)  #(2)
  @remote = options || {}    #(3)
  super  
 end 

 protected  

def page_link(page, text, attributes = {})
      @template.link_to_remote(text, {:url => url_for(page), :method =>:get}.merge(@remote))  
 end
end
