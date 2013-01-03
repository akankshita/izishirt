namespace :flash do
  task(:version => :environment) do
    #Edit javascript files
    ["html-template/AC_OETags.js","public/bin/AC_OETags.js"].each do |file_name|
      #Array for lines
      lines = []
      #Open file in read mode
      puts "[+] Editing file: #{file_name}"
      file = File.open("#{RAILS_ROOT}/#{file_name}",'r')
      file.each do |line|
        if line.index("swf?version=")
          line.gsub!(/swf\?version=...../,"swf?version=#{ENV['VERSION']}")
        end
        lines << line
      end
      puts "[+] Editing Complete"
      file.close

      file = File.open("#{RAILS_ROOT}/#{file_name}",'w')
        lines.each { |line| file.write(line) }
      file.close
    end

    #Edit Views
    ["display/create_tshirt.html.erb",
      "facebook/create.rhtml",
      "myizishirt/products/flash_app.rhtml",
      "my/iframe_create.html.erb",
      "my/iframe_flash_shop.rhtml",
      "my/flash_shop.rhtml",
      "my/custom_flash_shop.html.erb"
      ].each do |file_name|
      #Array for lines
      lines = []
      #Open file in read mode
      puts "[+] Editing file: #{file_name}"
      file = File.open("#{RAILS_ROOT}/app/views/#{file_name}",'r')
      file.each do |line|
        if line.index("Izishirt6.swf")
          line.gsub!(/Izishirt6.swf\?version=...../,"Izishirt6.swf?version=#{ENV['VERSION']}")
        end
        lines << line
      end
      puts "[+] Editing Complete"
      file.close

      file = File.open("#{RAILS_ROOT}/app/views/#{file_name}",'w')
        lines.each { |line| file.write(line) }
      file.close
    end
  end
end

