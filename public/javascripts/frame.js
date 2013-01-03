$j(document).ready(function(){
  if (top === self){
      return false;
  }
  else{
      window.parent.location = self.location;
  }
});
