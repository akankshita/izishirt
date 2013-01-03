namespace :cache do
  task(:clear_daily_html => :environment) do
    app = DisplayController.new # yep, really

    app.clear_category_cache(true)
    app.clear_create_tshirt_cache(true)
    app.clear_izishirt_2011_cache(true)
    app.clear_marketplace_cache(true)
    app.clear_marketplace_shop_cache(true)
    app.clear_design_info_cache(true)
  end

  task(:clear_week_html => :environment) do
    app = DisplayController.new # yep, really

    app.clear_local_cache(true)
    app.clear_sitemap_cache(true)
    app.clear_result_tag_cache(true)

    product_app = ProductFeedsController.new
    product_app.clear_cache_price(true)

  end

  task(:clear_category_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_category_cache(true)
  end

  task(:clear_design_info_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_design_info_cache(true)
  end

  task(:clear_result_tag_cache => :environment) do
    app = DisplayController.new # yep, really
    
    app.clear_result_tag_cache(true)
  end

  task(:clear_marketplace_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_marketplace_cache(true)
  end

  task(:clear_marketplace_search_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_marketplace_search_cache(true)
  end

  task(:clear_marketplace_shop_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_marketplace_shop_cache(true)
  end

  task(:clear_marketplace_shop_product_cache => :environment) do
    app = DisplayController.new # yep, really

    product_id = ENV["PRODUCT_ID"]

    app.clear_marketplace_shop_product_cache(true, product_id)
  end

  task(:clear_create_tshirt_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_create_tshirt_cache(true)
  end

  task(:clear_izishirt_2011_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_izishirt_2011_cache(true)
  end

  task(:clear_local_cache => :environment) do
    app = DisplayController.new # yep, really

    app.clear_local_cache(true)
  end

  #task(:clear_sitemap_cache => :environment) do
  #  app = DisplayController.new # yep, really

  #  app.clear_sitemap_cache(true)
  #end

  task(:clear_francis_cache => :environment) do
    app = ProductFeedsController.new
    app.clear_cache(true)
  end

  task(:list => :environment) do
    print "sudo rake cache:clear_daily_html RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_week_html RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_category_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_result_tag_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_marketplace_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_marketplace_shop_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_create_tshirt_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_design_info_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_izishirt_2011_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:clear_local_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    #print "sudo rake cache:clear_sitemap_cache RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
    print "sudo rake cache:list RAILS_ENV=#{ENV["RAILS_ENV"]}\n"
  end
end

