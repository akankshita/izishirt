#!/bin/sh
# Production
RAKE_PATH="/usr/local/bin/rake"
ENVIRONMENT="production"
PATH_ENV="/www/izishirt"

# dev
# RAKE_PATH="rake"
# ENVIRONMENT="development"
# PATH_ENV="/www/izishirt"

cd $PATH_ENV

for lang in fr en es de pt
do
	$RAKE_PATH sitemap:init LANG=$lang RAILS_ENV=$ENVIRONMENT

	$RAKE_PATH sitemap:generate URL_TYPE=main_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=local_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=create_t_shirt_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=main_pages_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=our_shops_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=model_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=design_category_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=design_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=design_info_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=design_tags_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_entry_points LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_tag_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_product_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_custom_product_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_image_list_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_store_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=design_category_page_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=design_tag_page_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_tag_page_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_category_page_urls LANG=$lang RAILS_ENV=$ENVIRONMENT
	$RAKE_PATH sitemap:generate URL_TYPE=marketplace_store_page_urls LANG=$lang RAILS_ENV=$ENVIRONMENT

	for part in front boutique
	do
		$RAKE_PATH sitemap:finalize LANG=$lang WEBSITE_PART=$part RAILS_ENV=$ENVIRONMENT
	done
done
