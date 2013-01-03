# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'lib/custom_logger.rb'
# require 'money' 
require "active_merchant"
require 'active_merchant/billing/integrations/action_view_helper'
#require "lib/moneris/mpgapi4r.rb"
#require 'pdfkit'

# ActionView::Base.send(:include, ActiveMerchant::Billing::Integrations::ActionViewHelper) 

Rails::Initializer.run do |config|
  config.gem "restfulx"
  #config.gem "twitter_oauth"
  #config.gem "smurf"

  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.load_paths += %W( #{RAILS_ROOT}/app/sweepers )
  config.load_paths += %W( #{RAILS_ROOT}/app/middlewares )

#  config.middleware.use "PDFKit::Middleware", :print_media_type => true
#  config.middleware.insert_after ActionController::Failsafe, "UnsetCookieNotModified"

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store
  config.action_controller.session = {
     :key => "_izishirt_session_id",
     :expire_after => 1209600, #2 weeks
     :secret => "fnefweubfuibefefuwifiewpwpq"
  }


#config.action_controller.session_store = :mem_cache_store
   
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
 

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  
end

ActionController::Base.cache_store = :file_store, "/storage/cache_html"


#require 'lib/action_cache_key.rb'
#ActionController::Base.cache_store = :mem_cache_store, "localhost"


# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below
