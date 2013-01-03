namespace :mails do

  task(:yellow_pages => :environment) do
    require 'faster_csv'

    limit = ENV['LIMIT'].to_i

    I18n.locale = "fr-CA"
    entry_logfile = File.open("#{RAILS_ROOT}/log/yellow_pages4_email_#{Date.today}.log", 'a')
    entry_logfile.sync = true
    logger = CustomLogger.new(entry_logfile)
    FasterCSV.foreach(RAILS_ROOT + "/lib/yellow_pages4.csv", :quote_char => '"', :col_sep =>",", :row_sep =>:auto) do |row|
      email = row[5]
      name= row[0]
      if RAILS_ENV=="production" && !YellowPage.exists?(:email=>email)
        YellowPage.create(:name=>name, :email=>email,:language_id=>1)
        begin
          SendMail.deliver_yellow_pages(name,email)
          logger.info("Delivered_to " + email)
          limit = limit - 1
          break if limit == 0
        rescue
        end
        sleep 5

      end

    end
  end

  task(:spam => :environment) do
    require 'faster_csv'
    entry_logfile = File.open("#{RAILS_ROOT}/log/spam_email_#{Date.today}.log", 'a')
    entry_logfile.sync = true
    logger = CustomLogger.new(entry_logfile)

	cpt = 0

    FasterCSV.foreach(RAILS_ROOT + "/lib/spam.csv", :quote_char => '"', :col_sep =>',', :row_sep =>:auto) do |row|


	begin
	      email = row[1]
	      name= row[0]


		if BulkOrder.find(:all, :conditions => ["email = '#{email}'"]).length == 0

			newsletter = Newsletter.find(105)

			country = Country.find_by_shortname("CA")
			language = Language.find_by_shortname("en")

			SendMail.deliver_admin_newsletter(newsletter, name, email, country, language)
      			logger.info("Delivered_to " + email)
			puts "#{email}"
			sleep 5
		end
	rescue Exception => e
		puts "error -> e = #{e}"
	end

      # if (RAILS_ENV=="production" || email == "alberto.anthony@gmail.com") && !YellowPage.exists?(:email=>email)
      #  YellowPage.create(:name=>name, :email=>email,:language_id=>1)
      #  SendMail.deliver_yellow_pages(name,email)
      #  logger.info("Delivered_to " + email)
      #  sleep 5
      # end

    end
  end

  task(:send_newsletter => :environment) do

    newsletter = Newsletter.find(ENV['ID'])
    newsletter.date_sent = Time.now
    newsletter.save


    @start = ENV['START'] != "" ? ENV['START'] : ""
    @end   = ENV['END'] != "" ? ENV['END'] : Time.now.to_date+1.days
    @design_improvement = ENV["DESIGN_IMPROVEMENT"].to_s
    @to_bulk_order_clients = ENV["BULK_ORDER_CLIENTS"] == "on"
    @bulk_order_associate_to_sellers = ENV["BULK_ORDER_ASSOCIATE_TO_SELLERS"] == "on"
    @to_inactive_shops = ENV["INACTIVE_SHOPS"] == "on"
    @to_empty_shops = ENV["EMPTY_SHOPS"] == "on"
    @province_id = ENV["PROVINCE"] ? ENV["PROVINCE"].to_i : 0
    
    if @to_bulk_order_clients
      bulk_orders = BulkOrder.find_all_by_wants_newsletter(1, :group=>:email).each do |bulk_order|
        if bulk_order.email.size > 0
          
          entry_logfile = File.open("#{RAILS_ROOT}/log/bulk_order_newsletter_#{Date.today}.log", 'a')
          entry_logfile.sync = true
          logger = CustomLogger.new(entry_logfile)
          
          begin
            if !SendMail.deliver_admin_newsletter_bulk_orders(newsletter, bulk_order, @bulk_order_associate_to_sellers)
              logger.error("Error_to " + bulk_order.email)
            else
              logger.info("Delivered_to " + bulk_order.email)
            end
          rescue
            logger.error("Error_to " + bulk_order.email)
          end
        end
        
        sleep 10
      end
    else
      if ENV['LATE'] == "on" && ENV['NOT_SHIPPED'] == "on"
        @late = " and ( (datediff(orders.shipped_on,orders.created_on) >= 6 and orders.shipped_on is not null) or (orders.shipped_on is null) )"
      elsif ENV['LATE'] == "on"
        @late = " and (datediff(orders.shipped_on,orders.created_on) >= 6 and orders.shipped_on is not null)"
      elsif ENV['NOT_SHIPPED'] == "on"
        @late = " and orders.shipped_on is null"
      else
        @late = " AND 1 = 1"
      end

      if @province_id > 0
        @province_cond = " AND EXISTS(select * from addresses a WHERE a.id = orders.billing_address AND a.province_id = #{@province_id})"
      else
        @province_cond = " AND 1 = 1"
      end
  
      if @start != ""
        if(newsletter.user_level_id == nil  && newsletter.language_option == 0)
          @users = User.find_all_by_wants_newsletter(1,
            :include => [:orders],
            :conditions => ["orders.created_on between ? and ? #{@late} #{@province_cond}", @start, @end])
  
        elsif (newsletter.user_level_id == nil && newsletter.language_option != 0)
          @users = User.find_all_by_wants_newsletter_and_language_id(1, newsletter.language_option,
            :include => [:orders],
            :conditions => ["orders.created_on between ? and ? #{@late} #{@province_cond}", @start, @end])
  
        elsif (newsletter.user_level_id != nil && newsletter.language_option != 0)
          @users = User.find(:all,
            :include => [:orders],
            :conditions=>["orders.created_on between ? and ? and wants_newsletter = 1 AND user_level_id = ? AND users.language_id = ? #{@late} #{@province_cond}", @start, @end, newsletter.user_level_id, newsletter.language_option])
  
        else
          @users = User.find(:all,
            :include => [:orders],
            :conditions=>["orders.created_on between ? and ? and wants_newsletter = 1 AND user_level_id = ? #{@late} #{@province_cond}", @start, @end, newsletter.user_level_id])
  
        end
        #Start Dates of orders not set
      elsif @design_improvement.size > 0
        @users = User.find(:all, :joins=>[:images], :conditions=>["images.user_id=users.id and images.pending_approval=2"])
        @users.uniq!
	elsif @to_inactive_shops
		search_start = Date.today - 30
		search_end = Date.today

		@users = User.find(:all, :conditions => ["EXISTS(SELECT * FROM stores s where s.user_id = users.id) "+
			" AND NOT ((SELECT COUNT(*) FROM products WHERE products.store_id = stores.id AND created_on BETWEEN '#{search_start}' AND '#{search_end}') + " +
			" (SELECT COUNT(*) FROM images WHERE images.user_id = users.id AND (CAST(created_on AS DATE) BETWEEN '#{search_start}' AND '#{search_end}')) >= 3 " +
			" AND users.active=1)"], :include => [:store])
	elsif @to_empty_shops
		@users = User.find(:all, :conditions => ["EXISTS(SELECT * FROM stores s where s.user_id = users.id) AND NOT EXISTS(SELECT * FROM images where images.user_id = users.id) " +
			"AND NOT EXISTS(SELECT * FROM products WHERE products.store_id = stores.id)"], :include => [:store])
      else
        if(newsletter.user_level_id == nil  && newsletter.language_option == 0)
          @users = User.find_all_by_wants_newsletter(1)
        elsif (newsletter.user_level_id == nil && newsletter.language_option != 0)
          @users = User.find_all_by_wants_newsletter_and_language_id(1, newsletter.language_option)
        elsif (newsletter.user_level_id != nil && newsletter.language_option != 0)
          @users = User.find(:all, :conditions=>["wants_newsletter = 1 AND user_level_id = ? AND language_id = ?",newsletter.user_level_id, newsletter.language_option])
        else
          @users = User.find(:all, :conditions=>["wants_newsletter = 1 AND user_level_id = ?",newsletter.user_level_id])
        end
      end
      entry_logfile = File.open("#{RAILS_ROOT}/log/newsletter_#{Date.today}.log", 'a')
      entry_logfile.sync = true
      logger = CustomLogger.new(entry_logfile)
      logger.info("Total users : " + @users.size.to_s)
      logger.info("Design improvement email") if @design_improvement.size > 0
      
      cpt = 0

	################################################################ GUEST #######################################################################

	if newsletter.user_level_id.nil? || newsletter.user_level_id == 0
		# ALL, include orders guest mails
		orders_with_guest = Order.find_all_by_guest_wants_newsletter(true, :conditions => ["guest_email IS NOT NULL AND guest_email <> ''"])
		#orders_with_guest = [Order.find_by_guest_wants_newsletter(true, :order => "id desc")]

		guest_users = {}

		# retrieve guests information
		orders_with_guest.each do |order|

			if order.email_client == "" || order.email_client.nil?
				next
			end

			if guest_users[order.email_client] == nil
				begin
					guest_users[order.email_client] = {:country => order.billing.country, :language => order.language, :name => order.billing.name}
				rescue
				end
			end
		end

		# let's spam them
		guest_users.each do |email, guest_infos|

			if ! newsletter.newsletter_available?(guest_infos[:country], guest_infos[:language])
				next
			end

			cpt += 1

			  entry_logfile = File.open("#{RAILS_ROOT}/log/newsletter_#{Date.today}.log", 'a')
			  entry_logfile.sync = true
			  logger = CustomLogger.new(entry_logfile)

			  begin
			    if !SendMail.deliver_admin_newsletter(newsletter, guest_infos[:name], email, guest_infos[:country], guest_infos[:language])
			      logger.error("Error_to " + email)
			    else
			      logger.info("Delivered_to " + email)
			    end
			  rescue
			    logger.error("Error_to " + email)
			  end

			  sleep 10
		end
	end

	############################################################# END GUEST #######################################################################

      for ue in @users do

        if RAILS_ENV == 'development' && cpt > 10 #&& ue.email != 'contact@izishirt.com' && ue.email != 'contact@izishirt.com' && ue.email != 'contact@izishirt.com'
          next

        end

        if ue.wants_newsletter && ue.active

          email = ue.email

	  country = nil
	  language = nil


          begin
            order = ue.orders.first
	    language = order.language
	    country = order.billing.country

            email = ue.email
          rescue
		email = ue.email

		begin
			country = Country.find_by_shortname(ue.country)
			language = ue.language
		rescue
			country = nil
			language = nil
		end
          end

	  if ! language
		language = Language.find(2)
	  end

	  if ! country
		country = Country.find_by_shortname("CA")
	  end

		if ! newsletter.newsletter_available?(country, language)
			next
	  	end

          if email == "" || email.nil?
            email = ue.email
          end

          cpt += 1

          entry_logfile = File.open("#{RAILS_ROOT}/log/newsletter_#{Date.today}.log", 'a')
          entry_logfile.sync = true
          logger = CustomLogger.new(entry_logfile)

          begin
            if !SendMail.deliver_admin_newsletter(newsletter, ue.firstname, email, country, language)
              logger.error("Error_to " + email)
            else
              logger.info("Delivered_to " + email)
            end
          rescue
            logger.error("Error_to " + email)
          end
          sleep 10
        end
      end
  
      if @start == "" && @design_improvement.size == 0
        for news_request in NewsletterRequest.find(:all) do
          if RAILS_ENV == 'development' && news_request.email != 'aa@studiocodency.com' && news_request.email != 'alberto.anthony@gmail.com'
            next
          end
  
          entry_logfile = File.open("#{RAILS_ROOT}/log/newsletter_#{Date.today}.log", 'a')
          entry_logfile.sync = true
          logger = CustomLogger.new(entry_logfile)
          if !SendMail.deliver_admin_newsletter(newsletter, news_request)
            logger.error("Error_to_news_request " + news_request.email)
          else
            logger.info("Delivered_to_news_request " + news_request.email)
          end
          sleep 10
        end
      end
    end


  end
end
 
