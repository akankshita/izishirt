namespace :order do
	task(:check_statuses => :environment) do
		izishirt_user_id = User.find_by_username("izishirt").id
		izishirt_brother_id = User.find_by_username("izishirtbrother").id

		# the green order, put to izishirt brother
		ActiveRecord::Base.transaction do
			orders = Order.find(:all, :conditions => ["(printer IS NULL OR printer <= 0) AND confirmed = 1 AND #{Order.is_24_hours_order_condition} AND status NOT IN (#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_ON_HOLD}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_CANCELED_COUPON})"])

			orders.each do |order|
				OrderHistory.create(:order_id => order.id, :attribute => "printer", :from_value => "0", :to_value => izishirt_brother_id, :user_id => izishirt_user_id)

				order.update_attributes(:printer => izishirt_brother_id)
				puts "set order #{order.id} to printer #{izishirt_brother_id}"
			end
		end

		ActiveRecord::Base.transaction do
			# Move to awaiting stocks if status = processing AND artworks_sent = true, but there is missing garments
			orders = Order.find(:all, :conditions => ["status = #{SHIPPING_TYPE_PROCESSING} AND artwork_sent = 1 AND confirmed = 1"])

			orders.each do |order|
				if ! order.garments_fully_received?
					OrderHistory.create(:order_id => order.id, :attribute => "status", :from_value => order.status, :to_value => SHIPPING_TYPE_AWAITING_STOCK, :user_id => izishirt_user_id)

					# MISSING STOCKS
					order.update_attributes(:status => SHIPPING_TYPE_AWAITING_STOCK)
					puts "changing order #{order.id} status to AWAITING STOCK"

				end
			end
		end

		ActiveRecord::Base.transaction do
			# Move to awaiting artworks if artwork_sent = false and there is no missing garment
			orders = Order.find(:all, :conditions => ["artwork_sent = 0 AND status NOT IN (#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_PACKAGING}, #{SHIPPING_TYPE_ON_HOLD}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_PARTIALLY_SHIPPED}, #{SHIPPING_TYPE_MOCK_UP}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_BACK_ORDER}, #{SHIPPING_TYPE_AWAITING_ARTWORKS}) AND confirmed = 1 AND printer > 0"])

			orders.each do |order|
				if order.garments_fully_received?

					OrderHistory.create(:order_id => order.id, :attribute => "status", :from_value => order.status, :to_value => SHIPPING_TYPE_AWAITING_ARTWORKS, :user_id => izishirt_user_id)

					order.update_attributes(:status => SHIPPING_TYPE_AWAITING_ARTWORKS)
					puts "change order #{order.id} status to AWAITING ARTWORKS"
				end
			end
		end

		ActiveRecord::Base.transaction do
			# - mettre packaging si tout imprimé ET statut processing
			orders = Order.find(:all, :conditions => ["status = #{SHIPPING_TYPE_PROCESSING} AND confirmed = 1"])

			orders.each do |order|
				if order.fully_printed?
					OrderHistory.create(:order_id => order.id, :attribute => "status", :from_value => order.status, :to_value => SHIPPING_TYPE_PACKAGING, :user_id => izishirt_user_id)

					order.update_attributes(:status => SHIPPING_TYPE_PACKAGING)
					puts "change order #{order.id} status to PACKAGING"
				end
			end
		end

		ActiveRecord::Base.transaction do
			# Move to PROCESSING si artwork_sent = 1 et garments recus
			orders = Order.find(:all, :conditions => ["artwork_sent = 1 AND status NOT IN (#{SHIPPING_TYPE_SHIPPED}, #{SHIPPING_TYPE_CANCELED}, #{SHIPPING_TYPE_PACKAGING}, #{SHIPPING_TYPE_ON_HOLD}, #{SHIPPING_TYPE_AWAITING_PAYMENT}, #{SHIPPING_TYPE_CANCELED_COUPON}, #{SHIPPING_TYPE_PROCESSING},#{SHIPPING_TYPE_BATCHING},#{SHIPPING_TYPE_PARTIALLY_SHIPPED}, #{SHIPPING_TYPE_TO_CHECK}, #{SHIPPING_TYPE_BACK_ORDER}, #{SHIPPING_TYPE_AWAITING_ARTWORKS}) AND confirmed = 1"])
	
			orders.each do |order|
				if order.garments_fully_received?
					OrderHistory.create(:order_id => order.id, :attribute => "status", :from_value => order.status, :to_value => SHIPPING_TYPE_PROCESSING, :user_id => izishirt_user_id)

					order.update_attributes(:status => SHIPPING_TYPE_PROCESSING)
					puts "change order #{order.id} status to PROCESSING"
				end
			end
		end

		ActiveRecord::Base.transaction do
			orders = Order.find(:all, :conditions => ["total_price = 0 AND coupon_code = 'bulk' AND sales_price IS NOT NULL AND confirmed = 1 AND sales_price > 0"])

			orders.each do |order|
				order.update_attributes(:total_price => order.sales_price)
				puts "changing total price for order #{order.id}"
			end
		end
	end
end
