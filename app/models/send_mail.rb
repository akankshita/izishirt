class SendMail < ActionMailer::Base
  helper ApplicationHelper

  # Lorsqu'il y a des bulk orders, chaque bulk order doit avoir son propre PO number, et 
  # tout le reste (les petites commandes), vont dans un autre paquet avec un PO différent.
  # Retourne une liste de maps: [[:po_number => po, :garments => liste_garments]]
  def split_garments(garment_ids)
    results = []
    
    # Remove nil garments:
    garment_ids.delete_if {|x| ! x}
    
    # First, get the order_id for each bulk orders
    bulk_orders = Set.new
    
    garment_ids.each do |garment_id|
      
      current_garment = OrderedProduct.find(garment_id)
      
      if current_garment.order && current_garment.order.coupon_code == "bulk"
        bulk_orders.add(current_garment.order)
      end
    end
    
    copy_garment_ids = garment_ids.dup
    
    # Then scan the bulk orders to collect the garments for each bulk order:
    bulk_orders.each do |bulk_order|
      
      garment_ids_in_bulk_order = []
      
      garment_ids.each do |garment_id|
        
        current_garment = OrderedProduct.find(garment_id)
        
        # Add this garment in the bulk order
        if current_garment.order.id == bulk_order.id
          garment_ids_in_bulk_order << garment_id
          
          # Delete this garment only in the copy in order to not re-scan it for the garments not in a bulk order
          copy_garment_ids.delete(garment_id)
        end
      end
      
      results << {:po_number => PoNumber.create({:status => "Sent", :created_on => Time.now}), :garments => garment_ids_in_bulk_order}
    end
    
    # Finally, we must add the rest of the garments in another PO for the small orders:
    if copy_garment_ids.length > 0
      results << {:po_number => PoNumber.create({:status => "Sent", :created_on => Time.now}), :garments => copy_garment_ids}
    end
    
    return results
  end

  def automatic_supplier_email(listing, shipping_type, blank_order = false)

    rush_str = shipping_type == "rush_order" ? "Rush " : ""
    apparel_supplier = listing.apparel_supplier

    @subject    = "Izishirt #{rush_str}Order Placement #{blank_order != false ? " - Blank - " : ""} #{listing.po_number}"

	if RAILS_ENV == "production"
	    @recipients = listing.apparel_supplier.email
	    @cc         = 'contact@izishirt.com'
	else
	    @recipients = "contact@izishirt.com"
	end
    @from       = 'contact@izishirt.com'

    garments = listing.garments_according_to_order_and_models(2)

    @sent_on    = Time.now
    @headers    = {}
    #@body["garments"] = @garments
    @body["lang"] = 2
    @body["listing"] = listing
    @body["apparel_supplier"] = apparel_supplier
    @body["printer"] = User.find(listing.printer)
    @body["garments_according_to_order_and_model"] = garments
    @body["rush_order"] = shipping_type == "rush_order"
    @body["blank_order"] = blank_order
  end

  def order_garment_return(order_garment_return)

    @subject    = "Izishirt Items return ##{order_garment_return.id}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'

    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = 2
    @body["return"] = order_garment_return
  end

  def gift_certificate(ordered_product, path_cert)

    @subject    = I18n.t(:gift_certficate_mail_subject, :locale => Language.find(ordered_product.order.language_id).shortname)
	
	Rails.logger.error("BYYYYYY ->#{ordered_product.gift_email_by}<-")

	if ! ordered_product.gift_email_to || ordered_product.gift_email_to == ""
	    @recipients = ordered_product.gift_email_by
	else
	    @recipients = ordered_product.gift_email_to
	end
    @from       = "#{ordered_product.gift_email_by}"
    @cc       = "#{ordered_product.gift_email_by}"

    @sent_on    = Time.now
    @content_type = "multipart/mixed"   	
    @headers    = {}
    @body["ordered_product"] = ordered_product

    part :content_type => "text/html" , :body => render_message("gift_certificate" , :ordered_product => ordered_product)

	# cert_str  = File.new(path_cert)

	# attachment :content_type => "application/x-pdf",
	#	:body => File.read(cert_str),
	#	:filename => "gift_izishirt.pdf"
  end

  def new_business_opportunity(business_opportunity)

    @subject    = "[Izishirt.ca notification] - New business opportunity with #{business_opportunity.company}"
    @recipients = "contact@izishirt.com"
    @from       = 'contact@izishirt.com'

    @sent_on    = Time.now
    @headers    = {}
    @body["business_opportunity"] = business_opportunity
  end

  def notify_shipping_po_box(order)
    @subject    = "#{I18n.t(:send_mail_notify_shipping_po_box_subject, :locale => Language.find(order.language_id).shortname, :order_id => order.id)}"
    @recipients = order.email_client
    @from       = 'Izishirt <contact@izishirt.com>'

    @sent_on    = Time.now
    @headers    = {}
    @body["order"] = order
  end

  def to_check_notification(order, because_blank = false)

	blank_str = "BLANK"

	if ! because_blank
		blank_str = ""
	end

    @subject    = "[Izishirt] #{order.id} to check #{blank_str}"
    @recipients = "contact@izishirt.com"
    @from       = 'Izishirt <contact@izishirt.com>'

    @sent_on    = Time.now
    @headers    = {}
    #@body["garments"] = @garments
    @body["order"] = order
  end

  def big_online_order_notification(order)

    @subject    = "[Izishirt] #{order.id} Client to contact"
    @recipients = "contact@izishirt.com"
    @from       = 'Izishirt <contact@izishirt.com>'

    @sent_on    = Time.now
    @headers    = {}
    #@body["garments"] = @garments
    @body["order"] = order
  end

  def bulk_order_email(order)
    @subject    = "#{I18n.t(:send_mail_bulk_order_1, :locale => Language.find(order.language_id).shortname, :order_id => order.id)}"
    @recipients = order.custom_client_email
    @from       = "#{order.user.fullname} <#{order.user.email}>"

    @sent_on    = Time.now
    @headers    = {}
    @body["order"] = order
  end

  def follow_up_order_garment(listing, product)

    apparel_supplier = listing.apparel_supplier

    @subject    = "Izishirt FOLLOW UP of #{listing.po_number}"
    @recipients = listing.apparel_supplier.email
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'

    garments = [product]

    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = 2
    @body["listing"] = listing
    @body["apparel_supplier"] = apparel_supplier
    @body["printer"] = User.find(listing.printer)
    @body["garment_products"] = garments
  end

  def bulk_follow_up_order_garment(apparel_supplier, products)

    @subject    = "Izishirt FOLLOW UP"
    @recipients = apparel_supplier.email
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'

    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = 2
    @body["apparel_supplier"] = apparel_supplier
    @body["products"] = products
  end

  def contest_design_sent(image)

    @subject    = "#{I18n.t(:send_mail_subject_contest_design_sent, :locale => Language.find(image.user.language_id).shortname)}"
    @recipients       = image.user.email
    @from       = 'Izishirt Contest <contact@izishirt.com>'
    #@cc         = ''
    @sent_on    = Time.now
    @headers    = {}
    @body["language_id"] = image.user.language_id
    @body["name"] = "#{image.user.firstname} #{image.user.lastname}"
  end

  def partially_ship(order_shipping_history)
	order = order_shipping_history.order

	partially_shipped_products = []

	order_shipping_history.ordered_product_shipping_histories.each do |prod_hist|
		prod = prod_hist.ordered_product
		prod.quantity = prod_hist.quantity

		partially_shipped_products << prod
	end

	subject, content = prepare_order_shipped(order, partially_shipped_products, "PARTIALLY_SHIPPED", order_shipping_history.tracking_number)

    @subject    = subject
    @recipients       = order.email_client
    @from       = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["content"] = content
  end

  def printer_shift_report(printer_shift)

    @subject    = "Printing Report of #{printer_shift.printer_fullname} on #{printer_shift.printing_machine_username} | #{printer_shift.created_at} -> #{printer_shift.finished_at}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["printer_shift"] = printer_shift
  end

  def artwork_shift_report(shift)

    @subject    = "Artwork Report of #{shift.fullname} | #{shift.created_at} -> #{shift.finished_at}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["shift"] = shift
  end

  def general_shift_report(shift)

    @subject    = "Report of #{shift.fullname} | #{shift.created_at} -> #{shift.finished_at}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["shift"] = shift
  end

  def shipping_shift_report(shift)

    @subject    = "Shipping Report of #{shift.fullname} | #{shift.created_at} -> #{shift.finished_at}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["shift"] = shift
  end

  def garment_processor_shift_report(shift)

    @subject    = "Garment Processing Report of #{shift.fullname} | #{shift.created_at} -> #{shift.finished_at}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["shift"] = shift
  end

  def alert_shift_today(user)

    @subject    = "CURRENT Shift ALERT for #{user.username}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
  end

  def alert_shift_week(user)

    @subject    = "WEEK Shift ALERT for #{user.username}"
    @recipients       = 'contact@izishirt.com'
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
  end

  def validate_contest_image(image)

	# Subject: Your Submission has been accepted!
	@is_approved = image.pending_approval == DESIGN_VALIDATION_STATE_APPROVED_ID

	if @is_approved
		s = I18n.t(:send_mail_contest_validation_subject_approved, :locale => Language.find(image.user.language_id).shortname)
	else
		s = I18n.t(:send_mail_contest_validation_subject_rejected, :locale => Language.find(image.user.language_id).shortname)
	end

	currency = Country.currency_of(image.user.country).label

	@subject    = "#{s}"
	@recipients       = image.user.email
	@from       = "Izishirt Contest <contact@izishirt.com>"
	@cc         = ''
	@sent_on    = Time.now
	@headers    = {}
	@body["image"] = image
	@body["is_approved"] = @is_approved
	@body["language"] = image.user.language.shortname
	@body["currency"] = currency
  end

	def order_products_html_listing(order, ordered_products)


		str = "<table>\n" +
		"<tr>\n" +
			"<th>#{I18n.t(:send_mail_refund_cancel_with_coupon_3, :locale => Language.find(order.language_id).shortname)}</th>\n" +
			"<th>#{I18n.t(:send_mail_refund_cancel_with_coupon_4, :locale => Language.find(order.language_id).shortname)}</th>\n" +
			"<th>#{I18n.t(:send_mail_refund_cancel_with_coupon_5, :locale => Language.find(order.language_id).shortname)}</th>\n" +
			"<th>#{I18n.t(:send_mail_refund_cancel_with_coupon_6, :locale => Language.find(order.language_id).shortname)}</th>\n" +
		"</tr>\n"

		 ordered_products.each do |product|

			if product.is_extra_garment
				next
			end

			str += "<tr>\n"
				str += "<td>#{product.id}</td>\n"
	
				if ! product.coupon
					str += "<td>#{product.model.local_name(order.language_id)}</td>\n"
					str += "<td>\n"
						str += "<ul>\n"	
							product.ordered_zones.each do |zone|
								zone.ordered_zone_artworks.each do |art|
									str += "<li>#{art.name}</li>\n"
								end
							end
						str += "</ul>\n"
					str += "</td>\n"
				else
					str += "<td>#{I18n.t(:gift_cert_for, :locale => Language.find(order.language_id).shortname)} #{product.gift_for_name}</td>\n"
					str += "<td></td>\n"
				end
				str += "<td>#{product.quantity}</td>\n"
			str += "</tr>\n"
		end 

		str += "</table>\n"
	end

	def prepare_refund_email(order, ordered_products, reason_str, coupon)
		newsletter = Newsletter.find_by_name("ITEMS_CANCELED")

		country = order.mail_country
		language_id = order.language_id

		loc_news = nil

		begin
			loc_news = newsletter.localized_newsletters.find_by_country_id_and_language_id_and_active(country.id, language_id, true)
		rescue
		end

		if ! loc_news
			loc_news = newsletter.localized_newsletters.find_by_language_id_and_active(language_id, true)
		end

		subject = loc_news.subject.gsub("{{order_id}}", "#{order.id}")
		content = loc_news.content.gsub("{{firstname}}", "#{order.billing.name}")
		content = content.gsub("{{issue}}", reason_str)
		content = content.gsub("{{listing_items}}", order_products_html_listing(order, ordered_products))
		content = content.gsub("{{coupon}}", coupon.code)
		content = content.gsub("{{value}}", "#{coupon.currency_off.round(2)} #{Currency.find(order.curency_id).label}")
		content = content.gsub("{{bonus_amount}}", "#{coupon.coupon_reason_type.extra_amount.round(2)} #{Currency.find(order.curency_id).label}")

		return subject, content
	end

	

  def refund_with_a_coupon(coupon, order)

	reason_def = coupon.coupon_reason_type
	@extra_amount = reason_def.extra_amount

	if reason_def.str_id == "order_canceled_copyright"
		reason_str = I18n.t(:send_mail_refund_copyright, :locale => Language.find(order.language_id).shortname)
	elsif reason_def.str_id == "order_canceled_back_order"
		reason_str = I18n.t(:send_mail_refund_back_order, :locale => Language.find(order.language_id).shortname)
	elsif reason_def.str_id == "client_choice"
		reason_str = I18n.t(:send_mail_refund_client_choice, :locale => Language.find(order.language_id).shortname)
	end

	subject, content = prepare_refund_email(order, order.ordered_products, reason_str, coupon)

    @subject    = subject
    @recipients = order.email_client
    @from       = 'Izishirt.com <contact@izishirt.com>'


    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = order.language_id
    @body["coupon"] = coupon
    @body["order"] = order
    @body["content"] = content
  end

	def prepare_general_newsletter(newsletter_name, country, language)
		newsletter = Newsletter.find_by_name(newsletter_name)

		language_id = language.id

		loc_news = nil

		begin
			loc_news = newsletter.localized_newsletters.find_by_country_id_and_language_id_and_active(country.id, language_id, true)
		rescue
		end

		if ! loc_news
			loc_news = newsletter.localized_newsletters.find_by_language_id_and_active(language_id, true)
		end

		subject = loc_news.subject
		content = loc_news.content

		return subject, content
	end

  def boutique_subscription(store)
	subject, content = prepare_general_newsletter("BOUTIQUE_SUBSCRIPTION", Country.find_by_shortname(store.user.country), store.user.language)
	content = content.gsub("{{username}}", store.user.username)
	content = content.gsub("{{email}}", store.user.email)

    @subject    = subject
    @recipients = store.user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'


    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = store.user.language_id
    @body["content"] = content
  end

  def boutique_user_guide(store)
	subject, content = prepare_general_newsletter("BOUTIQUE_USER_GUIDE", Country.find_by_shortname(store.user.country), store.user.language)
	content = content.gsub("{{username}}", store.user.username)
	content = content.gsub("{{boutique_url}}", store.shop_url)
	content = content.gsub("{{earning_per_design}}", "#{store.user.earnings_per_image} #{Country.currency_of(store.user.country).symbol}")
	content = content.gsub("{{earning_contest}}", "#{Image.contest_amount_by_currency(Country.currency_of(store.user.country).label)} #{Country.currency_of(store.user.country).symbol}")

    @subject    = subject
    @recipients = store.user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'


    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = store.user.language_id
    @body["content"] = content
  end

  def boutique_encouragement(store)
	subject, content = prepare_general_newsletter("BOUTIQUE_ENCOURAGEMENT", Country.find_by_shortname(store.user.country), store.user.language)
	content = content.gsub("{{username}}", store.user.username)
	content = content.gsub("{{boutique_url}}", store.shop_domain)
	content = content.gsub("{{email}}", store.user.email)

    @subject    = subject
    @recipients = store.user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'


    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = store.user.language_id
    @body["content"] = content
  end

  def boutique_reminder(store)
	subject, content = prepare_general_newsletter("BOUTIQUE_REMINDER", Country.find_by_shortname(store.user.country), store.user.language)
	content = content.gsub("{{username}}", store.user.username)
	content = content.gsub("{{boutique_url}}", store.shop_domain)
	content = content.gsub("{{email}}", store.user.email)

    @subject    = subject
    @recipients = store.user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'


    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = store.user.language_id
    @body["content"] = content
  end

  def refund_with_a_coupon_create_sub_order(coupon, order, products_to_cancel)
	reason_def = coupon.coupon_reason_type
	@extra_amount = reason_def.extra_amount

	if reason_def.str_id == "order_canceled_copyright"
		reason_str = I18n.t(:send_mail_refund_copyright, :locale => Language.find(order.language_id).shortname)
	elsif reason_def.str_id == "order_canceled_back_order"
		reason_str = I18n.t(:send_mail_refund_back_order, :locale => Language.find(order.language_id).shortname)
	elsif reason_def.str_id == "client_choice"
		reason_str = I18n.t(:send_mail_refund_client_choice, :locale => Language.find(order.language_id).shortname)
	end

	subject, content = prepare_refund_email(order, products_to_cancel, reason_str, coupon)

    @subject    = subject
    @recipients = order.email_client
    @from       = 'Izishirt.com <contact@izishirt.com>'


    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = order.language_id
    @body["order"] = order
    @body["content"] = content
  end

  def custom_coupon_code(order, coupon)
    @subject    = I18n.t(:mail_custom_coupon_title, :locale => Language.find(order.language_id).shortname, :order_id => order.id)

	value = ""

	if coupon.currency_off > 0.0
		value = "#{coupon.currency_off.round(2)} #{Currency.find(order.curency_id).label}"
	else
		value = "#{coupon.percent_off} %"
	end

    @recipients = order.email_client
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @cc       = 'Izishirt.com <contact@izishirt.com>'

    @sent_on    = Time.now
    @headers    = {}
    @body["language_id"] = order.language_id
    @body["order"] = order
    @body["coupon"] = coupon
    @body["value"] = value
  end

  def back_order_email(order)
    @subject    = I18n.t(:sendmail_back_order_title, :locale => Language.find(order.language_id).shortname) + "#{order.id}"
    @recipients = order.email_client
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @cc       = 'Izishirt.com <contact@izishirt.com>'

    @sent_on    = Time.now
    @headers    = {}
    @body["language_id"] = order.language_id
    @body["order"] = order
  end
  
  def report_supplier_problem(listing, subject, message)
    @subject    = subject
    @recipients = listing.apparel_supplier.email
    @from       = 'contact@izishirt.com'
    @cc         = 'contact@izishirt.com'

    @sent_on    = Time.now
    @headers    = {}
    @body["lang"] = 2
    @body["listing"] = listing
    @body["printer"] = User.find(listing.printer)
    @body["message"] = message
  end

  def cancelled_order_email(id, email)
    @subject    = "#{id} Cancelled"
    @recipients = email
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
  end

  def contact_request(contact_request)
    if contact_request['title'] && contact_request['title'].size > 0
      @subject = contact_request['title']
    else
      @subject    = "Contact Request from " + contact_request['email'] + " for #{contact_request['department']}"
    end
    @recipients = contact_request['department']
    @from       = "Izishirt.com <contact@izishirt.com>"
    @reply_to   = contact_request['email']
    @sent_on    = Time.now
    @headers    = {}
    @body["contact_request"] = contact_request
  end

  def contact_mail_request(contact)
    @subject = contact[:subject]

    @recipients = "Izishirt.com <contact@izishirt.com>"
    @from       = contact[:email]
    @reply_to   = contact[:email]
    @sent_on    = Time.now
    @headers    = {}
    @body["contact"] = contact
  end
  
  
  def bulk_order_request(bulk_order)
  
    @subject = I18n.t(:send_mail_bulk_subject)
    @recipients = bulk_order[:email]
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["bulk_order"] = bulk_order
  end

  def bulk_order_details_request(bulk_order)
  
    @subject = "Izishirt Bulk Order #{bulk_order[:id]}, Qty: #{bulk_order[:approx_qty]}"
    @recipients = 'Izishirt.com <contact@izishirt.com>'
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["bulk_order"] = bulk_order
  end

  def bulk_order_mock_up_confirmation(mock_up)
    bulk_order = mock_up.bulk_order

    revision = mock_up.mock_up_revisions.find(:first, :order => "created_at DESC")

    @subject = I18n.t(:sendmail_approve_mock_up_subject, :locale => Language.find(bulk_order.language_id).shortname)
    @recipients = bulk_order.email
    @cc         = "contact@izishirt.com"
    @from       = bulk_order.seller_email
    @sent_on    = Time.now
    @headers    = {}
    @body["bulk_order"] = bulk_order
    @body["mock_up"] = mock_up
    @body["revision"] = revision
  end

  def boutique_earnings_notification(store)
    user = store.user

    @subject    = I18n.t(:send_mail_boutique_earnings_notification_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email
    @from       = "Izishirt.com <contact@izishirt.com>"
    @sent_on    = Time.now
    @headers    = {}
    @body["store"] = store
    @body["user"] = user
  end

  def admin_newsletter(newsletter, name, email, country, language)
    @subject    = newsletter.localized_newsletters.find_by_language_id_and_country_id(language.id, country.id).subject
    @recipients = email
    @from       = "Izishirt.com <contact@izishirt.com>"
    @reply_to   = "contact@izishirt.com"
    @sent_on    = Time.now
    @headers    = {}
    @body["email"] = Base64.encode64(email)
    @body["name"] = name
    @body["newsletter"] = newsletter  
    @body["language"] = language
    @body["country"] = country
  #@newsletter.localized_newsletters.find_by_language_id(@user.language_id).content %>  
end

  def webmaster_manual_email(user)
    @subject    = I18n.t(:webmaster_manual_email_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email
    @from       = "Izishirt.com <contact@izishirt.com>"
    @reply_to   = "contact@izishirt.com"
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
  end


  def admin_newsletter_bulk_orders(newsletter, bulk_order, associate_to_sellers)  

	language = bulk_order.language
	country = bulk_order.country

	if ! newsletter.newsletter_available?(country, language)
		raise "newsletter lang country invalid #{country.id}, #{language.id}"
	end
	
	loc_news = newsletter.localized_newsletters.find_by_language_id_and_country_id(language.id, country.id)
	content = loc_news.content


	# FIND SELLER

	seller_user = nil

	Rails.logger.error("associate to sellers = #{associate_to_sellers}")

	if associate_to_sellers
		begin
			seller_user = User.find(bulk_order.seller)
		rescue
			seller_user = nil
		end

		if ! seller_user || ! seller_user.active
			begin
				possible_sellers = User.find_all_by_user_level_id_and_active(UserLevel.find_by_name("Izishirt Seller").id, true)

				seller_user = possible_sellers[rand(possible_sellers.length)]
			rescue
			end
		end

	end


	from_mail = "Izishirt.com <quotes@izishirt.com>"

	if seller_user
		from_mail = "#{seller_user.fullname} <#{seller_user.email}>"
		content = content.gsub("{{seller_name}}", "#{seller_user.fullname}")
	end

    @subject    = loc_news.subject
    @recipients = bulk_order.email 
    @from       = "#{from_mail}"
    @reply_to   = "#{from_mail}"
    @sent_on    = Time.now
    @headers    = {}
    @body["email"] = Base64.encode64(bulk_order.email)
    @body["bulk_order"] = bulk_order 
    @body["newsletter"] = newsletter    
    @body["content"] = content
    @body["language"] = language
    @body["country"] = country
end

  def product_removed_image_declined(user, image_id)
    image = Image.find(image_id)

    @subject    = I18n.t(:send_mail_product_removed_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email
    @from       = "Izishirt.com <contact@izishirt.com>"
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
    @body["image"] = image
  end

  def product_removed_image_deleted(user, image_id = nil, products = nil)
    image = Image.find(image_id) if image_id

    @subject    = I18n.t(:send_mail_product_removed_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email
    @from       = "Izishirt.com <contact@izishirt.com>"
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
    @body["image"] = image if image
    @body["products"] = products
  end

  def product_removed_model(user, products)
    @subject    = I18n.t(:send_mail_product_removed_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
    @body["products"] = products
  end

  def backup_images(exception)  
    @subject    = "[Izishirt automatic email] - Backup images problem"
    @recipients = "contact@izishirt.com"
    @cc         = "embpoint@yahoo.ca"
    @from       = "Izishirt.com <contact@izishirt.com>"
    @sent_on    = Time.now
    @headers    = {}
    @body["exception"] = exception    
  end  

  def notify_24_hours_order(order)  
    @subject    = "#{order.id} NEXTDAY"
    @recipients = "contact@izishirt.com"
    @cc         = "contact@izishirt.com"
    @from       = "Izishirt.com <contact@izishirt.com>"
    @sent_on    = Time.now
    @headers    = {}
    @body["order"] = order
  end  
  
  def reject_product_preview(product)
    @subject    = I18n.t(:send_mail_reject_preview_subject, :locale => Language.find(product.store.user.language_id).shortname)
    @recipients = product.store.user.email 
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = product.store.user	
  end  
  
  def approve_product_preview(product)
    @subject    = I18n.t(:send_mail_approve_preview_subject, :locale => Language.find(product.store.user.language_id).shortname)
    @recipients = product.store.user.email 
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = product.store.user	
  end  

  def lost_pass(user, pass)  
    @subject    = I18n.t(:send_mail_lost_pass_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email 
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user	
    @body["pass"] = pass	
  end  
  
  def pay_me(user, payment_method, email, comment, address, store_payment)
    @subject    = "Demande de paiement Izishirt"
    @recipients = 'contact@izishirt.com'
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user	
    @body["payment_method"] = payment_method	
    @body["comment"] = comment	
    @body["email"] = email	
    @body["address"] = address
    @body["store_payment"] = store_payment
  end
  
  def payment_created(store_payment)
    if (store_payment.store.user.language_id == 1)
      @language = 'fr'
      @subject    = "Félicitations, Izishirt vient de vous faire un transfert d’argent sur ton compte Paypal"
    else
      @language = 'en'
      @subject    = "Congratulations, Izishirt has issued a payment on your Paypal Account"
    end
    
    @currency = 'CAD'

    @cc         = 'contact@izishirt.com'
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @recipients = store_payment.store.user.email
    @body["user"] = store_payment.store.user
    @body["amount"] = store_payment.amount
    @body["paypal_txn_id"] = store_payment.paypal_txn_id
  end
  
  def zero_dollar_payment_request(user)
    if (user.language_id == 1)
      @subject    = "Nous avons bien reçu votre demande de paiement Izishirt"
    else
      @subject    = "We have received your Izishirt payment request"
    end
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @recipients = 'embpoint@yahoo.ca' #user.email
    @body["user"] = user
  end
  
  def new_user(user)  
    @subject    = I18n.t(:send_mail_new_user_subject, :locale => Language.find(user.language_id).shortname)
    @recipients = user.email 
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user	
  end   
  
  def validate_design(image, email, user, path_preview, mail_from, order_id = nil)
    
    if mail_from.nil?
      mail_from = 'Izishirt.com <contact@izishirt.com>'
    end
    Rails.logger.error("test 7 order id = #{order_id}")
    @subject    = I18n.t(:send_mail_design_validation_subjet, :locale => Language.find(user.language_id).shortname)
    @recipients =  email
    @from       = mail_from
    @sent_on    = Time.now
    @headers    = {}
    @body["order_id"] = order_id
    @body["user"] = user
    @body["image_link"] = path_preview
    @body["image_name"] = (image.class == Image) ? image.name : nil
    @body["image_id"] = (image.class == Image) ? image.id : nil
    @body["comment_admin"] = (image.class == Image) ? image.coment_admin : ""
    @body["image"] = image
  end

  def design_is_being_improved(image, mail_from)
    if mail_from.nil?
      mail_from = 'Izishirt.com <contact@izishirt.com>'
    end
    
    @subject    = I18n.t(:send_mail_design_being_improved_subject, :locale => Language.find(image.user.language_id).shortname)
    @recipients =  image.user.email
    @from       = mail_from
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = image.user
    @body["image"] = image
  end

  def decline_design (image, email, user, path_preview, mail_from, order_id = nil)
    reason = LocalizedDesignImageDeclineReason.find_by_design_image_decline_reason_id_and_language_id(image.design_image_decline_reason_id, user.language_id)
    
    if mail_from.nil?
      mail_from = 'Izishirt.com <contact@izishirt.com>'
    end

    @subject       = I18n.t(:send_mail_decline_subject, :locale => Language.find(user.language_id).shortname)
    @recipients    = email
    @from          = mail_from
    @sent_on       = Time.now
    @headers       = {}
    @body["image"] = image
    @body["order_id"] = order_id
    @body["reason_title"] = (reason) ? reason.name : ""
    @body["image_link"] = path_preview
    @body["image_name"] = (image.class == Image) ? image.name : nil
    @body["image_id"] = (image.class == Image) ? image.id : nil
    @body["reason_description"] = image.decline_reason
    @body["user"]  = user
  end 

	def prepare_confirm_order(order)


		newsletter = Newsletter.find_by_name("ORDER_CONFIRMATION")

		country = order.mail_country
		language_id = order.language_id

		loc_news = nil

		begin
			loc_news = newsletter.localized_newsletters.find_by_country_id_and_language_id_and_active(country.id, language_id, true)
		rescue
		end

		if ! loc_news
			loc_news = newsletter.localized_newsletters.find_by_language_id_and_active(language_id, true)
		end

		subject = loc_news.subject.gsub("{{order_id}}", "#{order.id}")
		content = loc_news.content.gsub("{{firstname}}", "#{order.shipping.name}")
		content = content.gsub("{{order_id}}", "#{order.id}")
		content = content.gsub("{{listing_items}}", order_products_html_listing(order, order.ordered_products))
		content = content.gsub("{{name}}", order.shipping.name)
		content = content.gsub("{{address}}", order.shipping.address1)
		content = content.gsub("{{phone_number}}", order.shipping.phone)
		content = content.gsub("{{email}}", order.email_client)
		content = content.gsub("{{shipping_type}}", order.get_shipping_name)
		content = content.gsub("{{sub_total}}", "#{order.subtotal.round(2)} #{Currency.find(order.curency_id).label}")
		content = content.gsub("{{sales_tax}}", "#{order.total_taxes.round(2)} #{Currency.find(order.curency_id).label}")
		content = content.gsub("{{shipping}}", "#{order.total_shipping.round(2)} #{Currency.find(order.curency_id).label}")
		content = content.gsub("{{total}}", "#{order.total_price.round(2)} #{Currency.find(order.curency_id).label}")

		tracking = (order.tracking_number && order.tracking_number != "") ? order.tracking_number : "N/A"

		content = content.gsub("{{tracking_number}}", tracking)

		return subject, content
	end
  
  def confirm_order_user(order)
u = User.find(order.user_id)
    subject = I18n.t(:subject_email_confirm, :locale => Language.find(u.language_id).shortname, :order_id=>order.id.to_s)
    content = I18n.t(:body_email_confirm, :locale => Language.find(u.language_id).shortname, :order_id=>order.id.to_s)


	subject, content = prepare_confirm_order(order)

    @subject    = subject
    @recipients = order.email_client
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @cc = 'contact@izishirt.com'
    #@body["order"] = order
    #@body["user"] = u
    #@body["products"] = OrderedProduct.find_all_by_order_id(order.id)


	part :content_type => "text/html" , :body => render_message("confirm_order_user" , :content => content)

	attachment :content_type => "application/x-pdf",
		:body => File.read(order.invoice_pdf.path),
		:filename => "izishirt-order-#{order.id}.pdf"
  end

  def manage_contact_boutique(store_id, subject, body)
    store = Store.find(store_id)

    @subject    = subject
    @recipients = store.user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["store"] = store
    @body["msg_body"] = body
  end


  def confirm_order_guest(order, language_id)

	  subject = I18n.t(:subject_email_confirm, :locale => Language.find(language_id).shortname, :order_id=>order.id.to_s)
    content = I18n.t(:body_email_confirm, :locale => Language.find(language_id).shortname, :order_id=>order.id.to_s)

    @subject    = subject
    @recipients = order.email_client
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @cc = 'contact@izishirt.com'
    #@body["order"] = order
    #@body["language_id"] = language_id
    #@body["products"] = OrderedProduct.find_all_by_order_id(order.id)

	part :content_type => "text/html" , :body => render_message("confirm_order_guest" , :content => content)

	attachment :content_type => "application/x-pdf",
		:body => File.read(order.invoice_pdf.path),
		:filename => "izishirt-order-#{order.id}.pdf"
  end

	def prepare_order_shipped(order, ordered_products_shipped, newsletter_name, tracking_number)

		newsletter = Newsletter.find_by_name(newsletter_name)

		country = order.mail_country
		language_id = order.language_id

		loc_news = nil

		begin
			loc_news = newsletter.localized_newsletters.find_by_country_id_and_language_id_and_active(country.id, language_id, true)
		rescue
		end

		if ! loc_news
			loc_news = newsletter.localized_newsletters.find_by_language_id_and_active(language_id, true)
		end

		subject = loc_news.subject.gsub("{{order_id}}", "#{order.id}")
		content = loc_news.content.gsub("{{firstname}}", "#{order.shipping.name}")
		content = content.gsub("{{order_id}}", "#{order.id}")
		content = content.gsub("{{listing_items}}", order_products_html_listing(order, ordered_products_shipped))
		content = content.gsub("{{name}}", order.shipping.name)
		content = content.gsub("{{address}}", order.shipping.address1)
		content = content.gsub("{{phone_number}}", order.shipping.phone)
		content = content.gsub("{{email}}", order.email_client)
		content = content.gsub("{{shipping_type}}", order.get_shipping_name)

		tracking = (tracking_number && tracking_number != "") ? tracking_number : "N/A"

		content = content.gsub("{{tracking_number}}", tracking)

		return subject, content
	end
  
  def shipped_order_user(order, tracking_number)
	user = User.find(order.user_id)

	products = []

	order.ordered_products.each do |prod|
		products << prod if ! prod.is_extra_garment
  end


  if ![SHIPPING_PICKUP,SHIPPING_RUSH_PICKUP].include?(order.shipping_type)
	  subject, content = prepare_order_shipped(order, products, "ORDER_SHIPPED", tracking_number)
  else
    subject, content = prepare_order_shipped(order, products, "ORDER_SHIPPED_PICKUP", tracking_number)
  end


    @subject       = subject
    @recipients    = order.email_client
    @from          = "Izishirt.com <contact@izishirt.com>"
    @sent_on       = Time.now
    @headers       = {}
    @body["content"] = content
    
  end 

  def confirm_gift_user(coupon,gift) 
    user = User.find(gift.user_id)
    
    @subject        = "#{I18n.t(:send_mail_gift_subject, :locale => Language.find(user.language_id).shortname)} #{gift.sender}"
    @recipients     = "#{gift.receiver_email}"
    @cc             = user.email
    @from           = "Izishirt.com <contact@izishirt.com>"
    @sent_on        = Time.now
    @headers        = {}
    @body["user"]   = user
    @body["coupon"] = coupon
    @body["gift"]   = gift       
  end

  def quote_email(quote_email, bulk_order, quote_calculation_invoice_id)

	begin
		@invoice = QuoteCalculationInvoice.find(quote_calculation_invoice_id)
	rescue
		@invoice = nil
	end

    @subject = quote_email.title
    @recipients = bulk_order.email
    @cc         = "contact@izishirt.com"
    @from = "Izishirt.com <contact@izishirt.com>"
    @sent_on = Time.now

    @content_type = "multipart/mixed"   	
    @headers = {"Return-Receipt-To"=>"contact@izishirt.com", "X-Confirm-Reading-To"=>"contact@izishirt.com"}
    part :content_type => "text/html" , :body => render_message("quote_email" , :quote_email => quote_email)
    #@body = {:quote_email=>quote_email}

	if @invoice
		attachment :content_type => "application/x-pdf",
			:body => File.read(@invoice.quote_pdf.path),
			:filename => "izishirt-order.pdf"
	end
  end

  def bulk_order_invoice_comptability(quote_calculation_invoice)

	order_id = quote_calculation_invoice.quote_calculation.bulk_order.order.id

    @subject = "Bulk order comptability invoice - Order ##{order_id}"
    @recipients = "contact@izishirt.com"
    @cc         = "contact@izishirt.com"
    @from = "Izishirt.com <contact@izishirt.com>"
    @sent_on = Time.now

    @content_type = "multipart/mixed"   	
	if quote_calculation_invoice
		attachment :content_type => "application/x-pdf",
			:body => File.read(quote_calculation_invoice.invoice_comptability_pdf.path),
			:filename => "bulk-order-#{order_id}.pdf"
	end
  end

  def bulk_order_invoice(quote_calculation_invoice)

	order_id = quote_calculation_invoice.quote_calculation.bulk_order.order.id

	order = Order.find(order_id)
	language_id = order.bulk_order.language_id

	@subject = "#{I18n.t(:bulk_order_email_title, :locale => Language.find(language_id).shortname)} ##{order_id}"
	@recipients = order.bulk_order.email
	@cc         = "contact@izishirt.com"
	@from = "Izishirt.com <contact@izishirt.com>"
	@sent_on = Time.now

	part :content_type => "text/html" , :body => render_message("bulk_order_invoice", :language_id => language_id)

	@content_type = "multipart/mixed"   	

	if quote_calculation_invoice
		attachment :content_type => "application/x-pdf",
			:body => File.read(quote_calculation_invoice.invoice_pdf.path),
			:filename => "order-#{order_id}.pdf"
	end
  end
  
  def approve_design(image, file2)  
    @subject    = "Design Approbation"
    @recipients =  "contact@izishirt.com"
    @from       = 'Izishirt.com <contact@izishirt.com>'
	@sent_on = Time.now
	#@content_type = "multipart/mixed"   	
	@body = {:image => image}
	
	#part :content_type => "text/html" , :body => render_message("approve_design" , :image => image)

=begin	
	# attach files
	file_path = File.join("public", "izishirtfiles","images", image.id.to_s, image.img_design)
	attachement = File.read(file_path) #== FOR LINUX
	#attachement = File.open(file_path, 'rb') { |f| f.read } #== FOR WINDOWS 
	
	content_type = case File.extname(file_path)
		when ".jpg" , ".jpeg" ; "image/jpeg"
		when ".png" ; "image/png"
		when ".bmp" ; "image/bmp"
		else; "application/octet-stream"
	end	
	
	attachment	:content_type => content_type, 
						:body => attachement, 
						:filename => file2.original_filename,
						:transfer_encoding => "Base64",
						:charset => "utf-8"	
=end	
					
  end  
  
  def cron_24h(user)
    if (user.language_id == 1)
      @subject    = "Livraison gratuite sur Izishirt"
    else
      @subject    = "Free shipping on Izishirt"
    end
    @recipients = user.email 
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user	
  end
    
  def valued_customer_discount(user)
    #embed email signature image
#@cid = Time.now.to_f.to_s + "email_sig.jpg@izishirt.com"
#   image_path = "#{RAILS_ROOT}/public/images/email_sig.jpg"
#   file = File.open(image_path, 'rb')
#   inline_attachment :content_type => "image/jpg",
#                     :body => file.read,
#                     :filename => "email_sig.jpg",
#                     :cid => "<#{@cid}>"

    
    
    if (user.language_id == 1)
      @subject    = "Izishirt veut vous remercier avec ce code rabais spécial"
    else
      @subject    = "Izishirt wants to thank you with a special coupon code"
    end
    @recipients = user.email
    @from       = 'contact@izishirt.com'
    @sent_on    = Time.now
    
    
    @body["user"] = user
    
#@body["cid"] = @cid
    
  end

  def affiliate_monthly_sales(user, date)
    @subject    = I18n.t("sendmail.monthly_sales.subject", :locale => user.language.shortname)
    @recipients = user.email
    @cc         = "contact@izishirt.com"
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
    @body["date"] = date
  end
    
  def cron_1month_notify_affiliates(user,amount)
    if (user.language_id == 1)
      @subject    = "Vos Gains Izishirt: Recevez Votre Argent en 48 heures"
    else
      @subject    = "Your Izishirt Earnings: Request Your Payment within 48 hours"
    end
    @recipients = user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
    @body["amount_owed"] = amount
    
    
  end
    
  def upload_design_promote_shop(user,image)
    if (user.language_id == 1)
      @subject    = "Félicitation, vos designs ont été validés, commencez à gagner de l'argent!"
    else
      @subject    = "Congratulations, your designs have been validated, start making money!"
    end
    @recipients = user.email
    @from       = 'Izishirt.com <contact@izishirt.com>'
    @sent_on    = Time.now
    @headers    = {}
    @body["user"] = user
    @body["image"] = image	
  end
  
  def send_order_email(order, from_email, subject, body)
    @subject = subject
    @recipients = order.email_client()
    @from = from_email
    @sent_on = Time.now
    @content_type = "text/html"
    @headers = {}
    @body = {:body_content=>body, :order => order, :user => order.user}
  end

  def lost_orders_id(email, orders, language)
    @subject = I18n.t(:lost_orders_id_email_subject, :locale=>language)
    @recipients = email
    @from = "Izishirt.com <contact@izishirt.com>"
    @sent_on = Time.now
    @content_type = "text/html"
    @headers = {}
    @body = {:orders => orders, :language => language}
  end

  def notification_comment(email,subject,comment,language)
    @subject = subject
    @recipients = email
    @from = "Izishirt.com <noreply@izishirt.com>"
    @send_on = Time.now
    @content_type = "text/html"
    @headers = {}
    @body = {:comment => comment, :language => language}
  end

	def prepare_pick_up(order, pick_up_store)
		newsletter = Newsletter.find_by_name("PICK_UP")

		country = order.mail_country
		language_id = order.language_id

		loc_news = nil

		begin
			loc_news = newsletter.localized_newsletters.find_by_country_id_and_language_id_and_active(country.id, language_id, true)
		rescue
		end

		if ! loc_news
			loc_news = newsletter.localized_newsletters.find_by_language_id_and_active(language_id, true)
		end

		add = prepare_order_address(order, pick_up_store)

		subject = loc_news.subject.gsub("{{order_id}}", "#{order.id}")
		content = loc_news.content.gsub("{{firstname}}", "#{order.shipping.name}")
		content = content.gsub("{{order_id}}", "#{order.id}")
		content = content.gsub("{{address}}", add)
		content = content.gsub("http://{{google_map}}", pick_up_store.map_url)

		return subject, content
	end

  def nl2br(text)
    text = text.gsub(/\r\n/, "<br/>")
    return text.gsub(/\n/, "<br/>")
  end

	def prepare_order_address(order, pick_up_store)

		str = "<p>\n"

		if pick_up_store
      str += nl2br(pick_up_store.localized_business_hours(order.language_id))
		end 

		str += "</p>\n"

		if pick_up_store
			str += "#{I18n.t(:sendmail_ready_pick_up_3, :locale => Language.find(order.language_id).shortname)}<br /><br />\n"
			
			str += "#{pick_up_store.address.address1}<br />\n"

			if pick_up_store.address.address2 && pick_up_store.address.address2 != ""
				str += "#{pick_up_store.address.address2}<br />\n"
			end

			str += "#{pick_up_store.address.town}, #{pick_up_store.address.country.name}<br /><br />\n"
		end

		return str
	end

  def notify_ready_for_pick_up(order)

	pick_up_store = PickUpStore.find_store(order.shipping.province_id, order.shipping.town,order.shipping.province_name)

	subject, content = prepare_pick_up(order, pick_up_store)

    @subject = subject
    @recipients = order.email_client()
    @from = "Izishirt.com <contact@izishirt.com>"
    @send_on = Time.now
    @content_type = "text/html"
    @headers = {}
    @body = {:content => content}
  end

  def mailing(email)
    @recipients = email[:recipients]
    @from = email[:from]
    @cc = email[:cc]
    @subject = email[:subject]
    @body = email[:body]
    @content_type = email[:content_type]
  end


  def yellow_pages(name,email)
    @recipients = email
    @from = "Izishirt.com <contact@izishirt.com>"
    @reply_to  = "contact@izishirt.com"
    @sent_on    = Time.now
    @headers    = {}
    @subject = I18n.t(:yellow_pages_subject, :name=>name)
    @body["newsletter"] = I18n.t(:yellow_pages_body, :name=>name)
    @content_type = "text/html"
  end

  def admin_tracking_number(order,tr_num)
    #I18n.locale = order.language_id
    @recipients = order.email_client
    @from = "Izishirt.com <contact@izishirt.com>"
    @reply_to  = "contact@izishirt.com"
    @sent_on    = Time.now
    @headers    = {}
    @subject = I18n.t(:mail_tracking_number_subject,:locale =>Language.find(order.language_id).shortname,:order_id=>order.id)#"Tracking number :" + tr_num
    @body["tn"] = tr_num
    @body["order_id"] = order.id
    @body["language_id"] = order.language_id
    @content_type = "text/html"
  end
 
end
