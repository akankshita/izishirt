TWITTER_KEY="8510sIMsd49JkW4gjYYYHw"
TWITTER_SECRET="haorlu8J4eeZqVwkbgFV30Mc6iIeWlmcRlL4C36yok"
AVAILABLE_COUNTRIES=['US','CA']
AVAILABLE_LOCALES=["fr-CA","en-CA","en-US"]

DOMAINS_AND_LANG = ["es.izishirt.us", "www.izishirt.ca", "fr.izishirt.ca", "www.izishirt.ca.au",  "www.izishirt.us", "www.izishirt.be", "www.izishirt.fr", "www.izishirt.co.uk", "localhost:3000", "localhost:3000/france", "www.izishirt.es", "www.izishirt.mx", "www.izishirt.de", "www.izishirt.at", "www.izishirt.ca.pt"]

NB_MAX_BOUTIQUE_TAGS = 20

FEATURED_DESIGNER_ID = 820
ITEMS_PER_PAGE = 30
CONFIG_USER_LEVEL = 25
CONFIG_VENDOR_LEVEL = 50
CONFIG_STAFF_LEVEL = 75
CONFIG_ADMIN_LEVEL = 100
TEXTAREA_COLS_NUM = '60'
TEXTAREA_ROWS_NUM = '8'
PAGE_NOT_FOUND_URL = 'notfound'
ACCESS_FORBIDDEN_URL = 'forbidden'
VECTOR_EXTENSIONS = [ 'eps' ]

# change in environment ALSO ! (can't use constant from there
DIRECTORY_CACHE_HTML = '/storage/izishirt/cache_html'

CACHEDIRECTORY = "/storage/izishirt/cache_html"
VIEWS_FOLDER = "views"

DIRECTORY_COLOR = 'public/izishirtfiles/colors'
DIRECTORY_MYSTORE = 'public/izishirtfiles/mystore'
DIRECTORY_IMAGE = 'public/izishirtfiles/images'
DIRECTORY_PRODUCT = 'public/izishirtfiles/products'
DIRECTORY_UPLOADED_IMAGE = 'public/izishirtfiles/images/useruploadedimage/'
DIRECTORY_PROFILE = 'public/izishirtfiles/user_profile'
DIRECTORY_PROFILE_VIEW = '/izishirtfiles/user_profile'
DIRECTORY_BANNER_VIEW = '/izishirtfiles/banners'
DIRECTORY_MODEL = 'public/izishirtfiles/models'
DIRECTORY_LOCALIZED_MODEL = 'public/izishirtfiles/localized_models'
DIRECTORY_MENU = 'public/izishirtfiles/menus'
DIRECTORY_SHOP_THEMES = 'public/izishirtfiles/shop_themes'
WORDANS_FLASH_CONFIG_NEW_UPLOAD_CATEGORY = 'public/izishirtfiles/images/uploads'
MAIL_CONTACT_ADMIN = 'contact@izishirt.com'
ADMIN_RICH_TEXTAREA_COLS = 60
ADMIN_RICH_TEXTAREA_ROWS = 24
NB_TAG_TO_GENERATE_IN_THE_CLOUD = 14
MAX_LINES = [0,5,5,2,2]
FONT_TYPE = ["","Arial", "Times New Roman", "Courier New", "Cheri Liney"]
ZONES_POSITION = ["","front","back","left","right"]
EARNINGS_PER_IMAGE = 2.00
REFERING_USER_EARNING_EUROPE = 2.00
REFERING_USER_EARNING = 3.00
MAX_COMMISSION_PER_PRODUCT = 15.00
TEXT_PRICING_DIVIDER = 22
DESIGN_PRICING_DIVIDER = 100
QUANTITY_REBATE_DIVIDERS = Array.new
QUANTITY_REBATE_DIVIDERS << { :quantity=>3, :percent=>0.05 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>15, :percent=>0.10 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>25, :percent=>0.15 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>35, :percent=>0.20 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>45, :percent=>0.25 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>65, :percent=>0.30 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>85, :percent=>0.35 }
QUANTITY_REBATE_DIVIDERS << { :quantity=>100, :percent=>0.40 }

QUANTITY_BLANK_REBATE_DIVIDERS = Array.new
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>3, :percent=>0.05 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>15, :percent=>0.10 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>25, :percent=>0.15 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>35, :percent=>0.20 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>45, :percent=>0.25 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>65, :percent=>0.30 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>85, :percent=>0.35 }
QUANTITY_BLANK_REBATE_DIVIDERS << { :quantity=>100, :percent=>0.40 }

WORDANS_FLASH_SET_DEFAULT_TEXT = 1
URCHIN_TRACKER = 'UA-1994599-4'
HOME_PAGE_TXT_CONTENT = ''

#shipping variables
SHIPPING_BASIC = 0
SHIPPING_XPRESS_POST = 1 
SHIPPING_EXPRESS = 2
SHIPPING_RUSH = 3
SHIPPING_CHRISTMAS = 4
SHIPPING_PICKUP = 5
SHIPPING_RUSH_PICKUP = 6

SHIPPING_PRICES = [ {:CA => 12.00, :US => 12.00, :FR => 12.00, :INTL => 35.00, :EU=>12 },    #Basic
                    {:CA => 29.99, :US =>  29.99, :FR => 29.99, :INTL => "NA", :EU=>29.99 },  #Express/RapidPost
                    {:CA => 29.99, :US => 29.99, :FR => 29.99, :INTL => "NA", :EU=>29.99},     #Other Express - no longer used
                    {:CA => "NA", :US => "NA", :FR => "NA", :INTL => "NA", :EU=>15},     #RUSH - no longer used
                    {:CA => "NA", :US => "NA", :FR => "NA", :INTL => "NA", :EU=>15},     #Christmas - Only used for the holidays
                    {:CA => 4.95, :US => 4.95, :FR => 4.95, :INTL => 6.95, :EU=>6.95 },     #Pick Up
                    {:CA => 15.00, :US => 15.00, :FR => 15.00, :INTL => "NA", :EU=>15 }]   #Rush pickup

ARTWORK_SHIPPING_TYPE_DELAYS = [7, 5, 2, 1, nil, 3]

SHIPPING_NAMES = ['standard','xpress_post','express','rush','christmas', 'pickup', 'rush_pickup']
SHIPPING_FULL_NAMES = ['Standard Shipping','Express Post Shipping','Express Shipping','Rush Shipping','Christmas Shipping','Pick up in store', 'Rush Pick up in store']

SHIPPING_TYPE_PENDING = 0
SHIPPING_TYPE_PROCESSING = 1
SHIPPING_TYPE_SHIPPED = 2
SHIPPING_TYPE_BATCHING = 3
SHIPPING_TYPE_AWAITING_STOCK = 4
SHIPPING_TYPE_CANCELED = 5
SHIPPING_TYPE_PACKAGING = 6
SHIPPING_TYPE_ON_HOLD = 7
SHIPPING_TYPE_PRINTED = 8
SHIPPING_TYPE_ARTWORK_ON_HOLD = 9
SHIPPING_TYPE_AWAITING_PAYMENT = 10
SHIPPING_TYPE_AWAITING_ARTWORKS = 11
SHIPPING_TYPE_CANCELED_COUPON = 12
SHIPPING_TYPE_PARTIALLY_SHIPPED = 13
SHIPPING_TYPE_MOCK_UP = 14
SHIPPING_TYPE_TO_CHECK = 15
SHIPPING_TYPE_BACK_ORDER = 16

INTERNAL_SHIPPING_STATUS_PACKAGING = 0
INTERNAL_SHIPPING_STATUS_READY_FOR_PICK_UP = 1
INTERNAL_SHIPPING_STATUS_PICKED_UP = 2
INTERNAL_SHIPPING_STATUS_SHIPPED = 3

SHIPPING_TYPE_COLOR = ["blue_state", "orange_state", "green_state", "grey_state"]

BOUTIQUE_DISCOUNT_PERCENT = 0.15
AFFILIATE_EARNING_PERCENTAGE = 0.15
MARKETPLACE_EARNING_PERCENTAGE = 0.10

#custom orders
CUSTOM_ORDER_PATH = 'public/izishirtfiles/custom_orders/'
CUSTOM_ORDER_DOWNLOAD_PATH = 'izishirtfiles/custom_orders/'

# image files
IMAGE_FILES_PATH = ":rails_root/public/izishirtfiles/image_files/:attachment/:id/:style/:filename"
IMAGE_FILES_URL = "/izishirtfiles/image_files/:attachment/:id/:style/:filename"

#used with sorting in admin and production order controller
STRING_FLAGGED = 'flagged'

#Connexplace Constants
CONNEXPLACE_PAYMENT_URL = "http://izishirt.connexplace.com/tracking/payment"
CONNEXPLACE_ENTRY_URL = "http://izishirt.connexplace.com/tracking/entry"
AFFILIATES_SPACE_PARAM = "s"
AFFILIATE_ID_PARAM = "a"
AFFILIATE_PATH_PARAM = "p"
AFFILIATE_REFERRER_PARAM = "r"
AFFILIATE_EXPIRY_DATE = "d"
CHECK_COOKIE = "c"
IP_PARAM = "ip"
AMOUNT_PARAM = "amount"
CURRENCY_PARAM = "currency"
AFFILIATES_COOKIE = "cpo_a"
SALT_AFFILIATE_COOKIE = "herhehreherherhrh"
FLASH_APP_SALT = "youcanthackmyflashapplicationnonononoway"
FLASH_LAST_CHANGE="22012010"

# Design validation process
# "Pending approval", "Approved", "Approved, is being improved", "Declined"
DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID = 0
DESIGN_VALIDATION_STATE_APPROVED_ID = 1
DESIGN_VALIDATION_STATE_IS_BEING_IMPROVED_ID = 2
DESIGN_VALIDATION_STATE_DECLINED_ID = 3

DESIGN_VALIDATION_STATE_IDS = [DESIGN_VALIDATION_STATE_PENDING_APPROVAL_ID, DESIGN_VALIDATION_STATE_APPROVED_ID,
DESIGN_VALIDATION_STATE_IS_BEING_IMPROVED_ID, DESIGN_VALIDATION_STATE_DECLINED_ID]



NB_TOP_RATED_DESIGNS = 125

NB_DESIGNS_PER_PAGE = 25

BULK_PENDING = 1
BULK_QUOTE_SENT = 2
BULK_QUOTE_SOLD = 3
BULK_QUOTE_FAILED = 4
BULK_QUOTE_ARCHIVE = 5
BULK_QUOTE_RECONTACT = 6
BULK_ALERT_DELAY = 2

TOP25_BLACKLISTED_CATEGORIES = "42,107,16,106,164,108,20,65,66,67,106,107"


VALID_HOSTS = ["www.izishirt.com", "www.izishirt.ca", "fr.izishirt.ca", "frch.izishirt.ca", "izishirt.ca", "izishirt.com"]
DEV_HOSTS = ["www.izishirtdev.com", "www.izishirtdev.ca", "fr.izishirtdev.ca", "izishirtdev.ca", "izishirtdev.com"]

TOP_DOMAINS = ["www.izishirt.com", "www.izishirt.ca", "fr.izishirt.ca", "izishirt.ca", "izishirt.com","www.izishirtdev.com", "www.izishirtdev.ca", "fr.izishirtdev.ca", "izishirtdev.ca", "izishirtdev.com"]
SECRET_CONTEST_KEY = "06,164,108,20,65,66,67,106,Yub1ou18/03wont*12hackMyC0n42,107,16,1107"
LANGUAGE_SUBDOMAINS = ["fr", "frch"]

TAX_COUNTRIES = ["FR", "BE", "GB", "EU", "ES", "DE", "AT", "PT"]
MIN_MONEY_FOR_FREE_SHIPPING = 75
FREE_SHIPPING_DOMAINS = ["www.izishirt.com", "www.izishirt.ca", "fr.izishirt.ca"]
