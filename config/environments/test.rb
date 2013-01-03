# Settings specified here will take precedence over those in config/environment.rb
#ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update( :session_domain => '.izishirt.ca')

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = false

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :sendmail
config.action_mailer.default_charset = "utf-8"


BULK_PICTURES_PATH = ":rails_root/public/izishirtfiles/bulk/:attachment/:id/:style/:filename"
BULK_PICTURES_URL = "/izishirtfiles/bulk/:attachment/:id/:style/:filename"

CATEGORY_PICTURES_PATH = ":rails_root/public/izishirtfiles/category/:attachment/:id/:style/:filename"
CATEGORY_PICTURES_URL = "/izishirtfiles/category/:attachment/:id/:style/:filename"

URL_ROOT = "http://testcodency.no-ip.org"
URL_SESSIONS = "http://testcodency.no-ip.org"
SECURE_URL_ROOT = "https://testcodency.no-ip.org"
RAILS_DEFAULT_LOGGER.level = Logger::ERROR if defined? RAILS_DEFAULT_LOGGER

LCL_MERCHANT_ID = "014295303911111"
LCL_PATHFILE = "#{Rails.root}/lib/lcl/test/pathfile"
