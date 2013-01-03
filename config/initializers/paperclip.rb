if RAILS_ENV=="production"
  Paperclip.options[:command_path] = '/usr/local/bin/'
end
if RAILS_ENV=="development"
  #Paperclip.options[:command_path] = "C:/Program Files/ImageMagick-6.4.8-Q8"
end
  Paperclip.options[:swallow_stderr] = false


Paperclip::Attachment.interpolations[:year_created_on] = proc do |attachment, style|
  attachment.instance.year_created_on
end

Paperclip::Attachment.interpolations[:month_created_on] = proc do |attachment, style|
  attachment.instance.month_created_on
end

Paperclip::Attachment.interpolations[:day_created_on] = proc do |attachment, style|
  attachment.instance.day_created_on
end

Paperclip::Attachment.interpolations[:color_id] = proc do |attachment, style|
  attachment.instance.color_id
end

Paperclip::Attachment.interpolations[:product_id] = proc do |attachment, style|
  attachment.instance.product_id
end

Paperclip::Attachment.interpolations[:str_zone_definition] = proc do |attachment, style|
  attachment.instance.str_zone_definition
end

Paperclip::Attachment.interpolations[:bulk_order_id] = proc do |attachment, style|
  attachment.instance.bulk_order_id
end

Paperclip::Attachment.interpolations[:timestamp] = proc do |attachment, style|
  attachment.instance.timestamp
end
