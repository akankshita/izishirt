module RemoteUpload #:nodoc:
  def self.append_features(base) #:nodoc:
   super
   base.extend ClassMethods
  end
  
  # == Remote Upload
  #
  # The remote upload plugin allows "ajax" style remote file uploads. The concept was
  # take from a Drupal module. 
  #
  # You will need to copy the <tt>remote_upload.js</tt> from the plugin's javascript
  # directory to <tt>public/javascripts</tt>. The plugin will add <tt>remote_upload</tt> to 
  # the default scripts loaded by <tt>javascript_include_tag :defaults</tt>.
  #
  module ClassMethods

    # Creates a +before_filter+ which will call +start_remote_upload+
    # and an +after_filter+ which will call +finish_remote_upload+.
    #
    def remote_upload_for(*actions)
      before_filter :start_remote_upload

      if actions.flatten.first == :all
        after_filter :finish_remote_upload
      else
        after_filter :finish_remote_upload, :only => actions
      end
    end
    
    def uses_remote_upload
      remote_upload_for :all
    end
  end
  

  # Pretend to be a Prototype AJAX request.
  def start_remote_upload
    if params[:remote_upload] == "yes"
      self.request.env['HTTP_X_REQUESTED_WITH'] = "XMLHttpRequest"
    end
  end

  # Wraps the output in a div container. Then calls back to the handler in the parent window
  # sending along a status code and the output.
  #
  def finish_remote_upload
    if params[:remote_upload] == "yes"
      status = response.headers['Status'][0..2]
      content_type = response.headers['Content-Type']

      template  = "<body onload='parent.window.handleRemoteUpload.#{params[:remote_upload_id]}()'>"
      template << "<textarea id='response_text'>"
      template << status
      template <<   '[remote_upload:split]'
      template << content_type
      template <<   '[remote_upload:split]'
      template << response.body
      template << "</textarea>"
      template << "</body>"

      response.instance_variable_set('@body', template)
      response.headers['Content-Type'] = 'text/html'
    end
  end
end
