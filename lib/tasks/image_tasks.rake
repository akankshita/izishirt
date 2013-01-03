namespace :images do
  task(:get_user_images => :environment) do
    izishirtfiles="/Users/adam/Sites/izishirtfiles"
    puts "[+] getting images for #{ENV['USER']}"
    #make image folder
    User.find_by_username(ENV['USER']).images.map{|i| system "mkdir -p #{izishirtfiles}/images/#{i.date_folder}/#{i.id}"}
    puts "[+] All image folders created"
    #copy images
    User.find_by_username(ENV['USER']).images.map{|i| system "scp -r izishirt.ca:/storage/izishirtfiles/images/#{i.date_folder}/#{i.id} #{izishirtfiles}/images/#{i.date_folder}"}
    puts "[+] All images copied"

    #make product folder
    User.find_by_username(ENV['USER']).store.products.each{|p|  system "mkdir -p #{izishirtfiles}/#{p.relative_product_folder_without_id}/#{p.id}" }
    puts "[+] All product folders created"
    #copy products
    User.find_by_username(ENV['USER']).store.products.each{|p|  system "scp -r  izishirt.ca:/storage/izishirtfiles/#{p.relative_product_folder_without_id}/#{p.id} #{izishirtfiles}/#{p.relative_product_folder_without_id}" }
    puts "[+] All product images copied"
  end

  task(:get_cooltees_img => :environment) do
    for image in Image.find(:all, :conditions=>"id <= 110") do
      begin
      system "wget -O '/codency/www/izishirt/public/tmp/#{image.orig_image_file_name}' http://www.izishirt.com"+image.orig_image.url(:original)
      f = File.new('/codency/www/izishirt/public/tmp/'+image.orig_image_file_name)
      image.orig_image = f
      image.save
      image.orig_image.reprocess!
      rescue
        image.destroy
      end
    end
  end

  task(:get_cooltees_img2 => :environment) do
    for image in Image.find(:all, :conditions=>"id <= 110") do
      #begin
      system "wget -O '/codency/www/izishirt/public/tmp/#{image.image_png_file_name}' http://www.izishirt.com"+image.image_png.url(:original)
      f = File.new('/codency/izishirt/public/tmp/'+image.image_png_file_name)
      image.orig_image = f
      image.save
      image.orig_image.reprocess!
      #rescue
        #image.destroy
      #end
    end
  end

  task(:get_newest_marketplace => :environment) do
    izishirtfiles="/Users/adam/Sites/izishirtfiles"
    products = Product.find(:all,
      :order => "products.rank ASC, products.added_to_marketplace_at DESC",
      :conditions => ["category_id > 0 and product_removed = ?", false],
      :limit => 24
    )
    #make product folder
    products.each{|p|  system "mkdir -p #{izishirtfiles}/#{p.relative_product_folder_without_id}/#{p.id}" }
    puts "[+] All product folders created"
    #copy products
    products.each{|p|  system "scp -r  izishirt.ca:/storage/izishirtfiles/#{p.relative_product_folder_without_id}/#{p.id} #{izishirtfiles}/#{p.relative_product_folder_without_id}" }
    puts "[+] All product images copied"
  end

  task(:get_top_25 => :environment) do
    izishirtfiles="/Users/adam/Sites/izishirtfiles"
    @top_designs = TopDesign.find_by_region(ENV['COUNTRY'], ENV['LANG']).map { |td| td.image }
    puts "[+] getting top images"
    #make image folder
    @top_designs.map{|i| system "mkdir -p #{izishirtfiles}/images/#{i.date_folder}/#{i.id}"}
    puts "[+] All image folders created"
    #copy images
    @top_designs.map{|i| system "scp -r izishirt.ca:/storage/izishirtfiles/images/#{i.date_folder}/#{i.id} #{izishirtfiles}/images/#{i.date_folder}"}
    puts "[+] All images copied"
  end
end
