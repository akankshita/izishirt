# #############################################################################
# General
# #############################################################################

# Notes:
# The checkout module also needs a named route called 'login' to indicate the 
# login URL. You can create one in config/routes.rb like so:
# map.login 'login', :controller => 'login', :action => 'login'

# Require the user to login before buying.
CHECKOUT_REQUIRE_LOGIN = true

# URL to go back to when the user selects 'Continue shopping'
CHECKOUT_CONTINUE_SHOPPING_URL = '/display/create_tshirt'

# Session variable to check to determine if user is currently logged in
CHECKOUT_USER_LOGIN_VAR = 'user_id'

# Tax settings for Canada
CAD_TAXES = {'QC' => 13.95, 'ON' => 6.0, 'SK' => 6.0, 'AL' => 6.0, 'BC' => 6.0, 'MN' => 6.0, 'NS' => 14.0, 'NB' => 14.0, 'PE' => 14.0, 'NF' => 14.0, 'YT' => 6.0, 'NU' => 6.0, 'NT' => 6.0}

# #############################################################################
# Cart
# #############################################################################

# Allow rebate codes
CART_COUPONS = true

# Allow user to change quantity of each item
CART_CHANGE_QTY = true

  
# #############################################################################
# Shipping
# #############################################################################

# Determine if shipping is enabled or not.
SHIPPING_ENABLE = true

# Determine which module to use for shipping. Choices are 'canadapost', 'static' or 'none'.
SHIPPING_MODULE = 'none'

# Enable free shipping for orders over X dollars. 0 disables the feature.
SHIPPING_FREE_AMOUNT = 0.00

# Minimum shipping amount. Anything less than that will be auto adjusted (unless free).
SHIPPING_MINIMUM = 5.00

# Numbers of days to add to any shipping methods (for handling)
SHIPPING_HANDLING_DELAY = 3

# Allow insurance on shipping ? (Canada Post Only)
SHIPPING_ALLOW_INSURANCE = false

# #############################################################################
# Billing
# #############################################################################

# Enabled payment processing module. Choices are 'internetsecure'.
BILLING_MODULES = ['internetsecure']

