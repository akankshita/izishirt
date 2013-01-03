# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Enable the breakpoint server that script/breakpointer connects to
#config.breakpoint_server = true


# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
#config.action_view.cache_template_extensions         = false
config.action_view.debug_rjs                         = true

#config.action_controller.page_cache_directory = "c:/storage/cache_html"

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp  
config.action_mailer.default_charset = "utf-8"  
config.action_mailer.smtp_settings = {
    :address => "mail.actigy.com" ,
    :port => 25,
    :domain => "mail.actigy.com"
}

BULK_PICTURES_PATH = ":rails_root/public/izishirtfiles/bulk/:attachment/:id/:style/:filename"
BULK_PICTURES_URL = "/izishirtfiles/bulk/:attachment/:id/:style/:filename"

CATEGORY_PICTURES_PATH = ":rails_root/public/izishirtfiles/category/:attachment/:id/:style/:filename"
CATEGORY_PICTURES_URL = "/izishirtfiles/category/:attachment/:id/:style/:filename"

URL_ROOT = "http://www.izishirtdev.com"
SECURE_URL_ROOT = "http://www.izishirtdev.com"

config.middleware.use "SetCookieDomain", ".izishirtdev.com"
config.log_level = :debug
RAILS_DEFAULT_LOGGER.level = Logger::DEBUG if defined? RAILS_DEFAULT_LOGGER
#RAILS_DEFAULT_LOGGER.level = Logger::ERROR if defined? RAILS_DEFAULT_LOGGER
#Paperclip.options[:command_path] = "C:/Program Files/ImageMagick-6.4.8-Q8"
#URL_SESSIONS = "http://www.izishirtdev.com"#
URL_SESSIONS = "http://localhost:3000/"
config.after_initialize do
  ActiveMerchant::Billing::Base.gateway_mode = :test
  ActiveMerchant::Billing::PaypalGateway.pem_file = File.read(RAILS_ROOT + '/config/cert_key_pem_dev.txt')
end
$PAYPAL_LOGIN = 'support_api1.izishirt.ca'
$PAYPAL_PASSWORD = 'MFKMEMNNXDN4JBCF'

LCL_MERCHANT_ID = "014295303911111"

ActiveMerchant::Billing::Base.mode = :test
LCL_PATHFILE = "#{Rails.root}/lib/lcl/test/pathfile"

HASH_DOMAINS_COUNTRIES = {"Canada"=>"izishirtdev.com", "USA"=>"izishirtdev.us"}
HASH_DOMAINS_ABBR_COUNTRIES = {"CA"=>"izishirtdev.com", "US"=>"izishirtdev.us"}
