function twitterAddShare(item, element) {
  url = "/twitter/authorize_share"
  url+= "?share="+item;
  url+= "&value="+element.checked;
  url+= "&element="+element.id;
  window.open(url, "Twitter", 
      "height=380, width=775, location=0, menubar=0, resizable=0, scrollbars=0, status=0, toolbars=0" ); 
}
