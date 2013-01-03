require 'RMagick'


products = Product.find :all, :sort=>'id ASC'
for p in products
  puts p.id
  for side in {'front'=>1,'back'=>2,'left'=>3,'right'=>4}
    if File.exists?(File.join('public', 'izishirtfiles', 'products', p.id.to_s, p.id.to_s+'-'+side[0]+'.jpg')) && !File.exists?(File.join('public', 'izishirtfiles', 'products', p.id.to_s, 'preview'+side[1].to_s+'.jpg'))
        puts 'Creating: '+File.join('public', 'izishirtfiles', 'products', p.id.to_s, 'preview'+side[1].to_s+'.jpg')
        img = Magick::Image::read(File.join('public', 'izishirtfiles', 'products', p.id.to_s, p.id.to_s+'-'+side[0]+'.jpg')).first
        thumb = img.scale(100, 100)
        thumb.write File.join('public', 'izishirtfiles', 'products', p.id.to_s, 'preview'+side[1].to_s+'.jpg')
    end    
  end
  puts  ''
end
