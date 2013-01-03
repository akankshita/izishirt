function fbShowConnectButton(){
  FB.getLoginStatus(function(response) {
    if (response.session) {
      pic = "http://graph.facebook.com/"+response.session.uid+"/picture";
      $j("#fb_profile").attr("src", pic);
      $j("#fb_connected").css("display","block");
      $j("#fb_not_connected").css("display","none");
    } 
    else {
      $j("#fb_connected").css("display","none");
      $j("#fb_not_connected").css("display","block");
    }
  }, true);
}

function fbAddShare(itemToShare, shareValue, permissionGrantedHandler){
  permissionGrantedHandler=permissionGrantedHandler || function(){};

  FB.login(function(response) {
    if (response.session && response.perms) { 
      url = '/facebook/add_share/'+response.session.uid;
      url+= '?share='+itemToShare;
      url+= '&value='+shareValue;
      url+= '&access_token='+response.session.access_token;
      $j.ajax({
        url: url,
        success: function(data) {
          permissionGrantedHandler();
        }
      });        
    } 
  }, {perms:'read_stream,publish_stream,offline_access'});
}

function fbPost(type, token, profile,  msg, link, name, pic, desc, onComplete){
  FB.api('/'+profile+'/feed', 
       'post', 
       { access_token: token, message: msg, link: link, name: name, picture: pic, description: desc },
       function(response){
         //Save post on izishirt
         fbSavePost(response.id, msg, link, name, pic, desc, type, onComplete);
       }
  );
}

function fbSavePost(postId, msg, link, name, pic, desc, type, onComplete){
  url = '/facebook/add_post/'+postId;
  url+= '?msg=' + msg;
  url+= '&link='+ link;
  url+= '&name='+ name;
  url+= '&pic=' + pic;
  url+= '&desc='+ desc;
  url+= '&type='+ type;
  $j.ajax({url: url, success: onComplete});        
}

function fbShare(item, element){
  fbAddShare(item, element.checked, function(){
    element.parentNode.highlight();
  });
}

function fbShareProduct(lang){
  if (lang != "") lang="/"+lang;
  $j.getJSON(lang+"/myizishirt/products/newest.json",
        function(data){
          if (data.share){
            if (data.facebook_post_to_delete != "")
              FB.api(data.facebook_post_to_delete,'delete', {access_token: data.facebook_access_token});

            fbPost('product_share', 
                   data.facebook_access_token,
                   data.facebook_profile,
                   data.facebook_post,
                   data.link_to_boutique,
                   data.name,
                   data.front_url,
                   data.description);
          }
        });
}

function fbShareDesign(lang, onComplete){
  onComplete = onComplete || function(){};
  if (lang != "") lang="/"+lang;
  $j.getJSON(lang+"/myizishirt/design/newest.json",
        function(data){
          if (data.share){
            if (data.facebook_post_to_delete != "")
              FB.api(data.facebook_post_to_delete,'delete', {access_token: data.facebook_access_token});

            fbPost('design_share', 
                   data.facebook_access_token,
                   data.facebook_profile,
                   data.facebook_post,
                   data.link_to_boutique,
                   data.name,
                   data.full_url,
                   data.description,
                   onComplete);
          }
          else{onComplete();}
        });
}

function fbShareContestSubmit(id, onComplete){
  onComplete = onComplete || function(){};
  $j.getJSON("/myizishirt/design/contest_image/"+id+".json",
        function(data){
          if (data.share_contest && $j("#image_pending_approval").val() == "1"){
            if (data.facebook_contest_post_to_delete != "")
              FB.api(data.facebook_contest_post_to_delete,'delete', {access_token: data.facebook_access_token});
            fbPost('contest_design_share', 
                   data.facebook_access_token,
                   data.facebook_profile,
                   data.facebook_post,
                   data.link_to_contest,
                   data.name,
                   data.full_url,
                   data.description,
                   onComplete);
          }
          else{onComplete();}
        });
}

function fbShareVote(id, onComplete){
  onComplete = onComplete || function(){};
  $j.getJSON("/myizishirt/design/contest_image_for_vote/"+id+".json",
        function(data){
          if (data.share_contest_votes){
            if (data.facebook_vote_post_to_delete != "")
              FB.api(data.facebook_vote_post_to_delete,'delete', 
                     {access_token: data.logged_in_user_facebook_access_token});
            fbPost('vote_share', 
                   data.logged_in_user_facebook_access_token,
                   data.logged_in_user_facebook_profile,
                   data.facebook_vote_post,
                   data.link_to_contest,
                   data.name,
                   data.full_url,
                   data.description,
                   onComplete);
          }
          else{onComplete();}
        });
}
