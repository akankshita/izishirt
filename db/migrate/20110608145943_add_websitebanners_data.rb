class AddWebsitebannersData < ActiveRecord::Migration
  def self.up


    w = WebsiteBanner.new
    #set attributs
    w.name = "yourtext_your_image"
    w.created_at = Time.now
    w.updated_at = Time.now
    w.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 1
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = "Create tshirts"
    wimage.image = File.new("/var/www/izishirt/public/images/izishirt2011/en/owntshirt.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 1
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = "Création tshirts"
    wimage.image = File.new("/var/www/izishirt/public/images/izishirt2011/fr/owntshirt.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 1
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = "Create tshirts"
    wimage.image = File.new("/var/www/izishirt/public/images/izishirt2011/en/owntshirt.jpg")
    wimage.save

    w = WebsiteBanner.new
    #set attributs
    w.name = "categories_images"
    w.created_at = Time.now
    w.updated_at = Time.now
    w.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 4
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/animals.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 4
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/animals.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 4
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/animals.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 7
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/celebrity.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 7
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/celebrity.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 7
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/celebrity.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 10
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/food&drink.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 10
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/food&drink.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 10
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/food&drink.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 1
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/funny.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 1
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/funny.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 1
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/funny.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 11
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/geography.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 11
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/geography.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 11
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/geography.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 9
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/hobbies&interest.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 9
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/hobbies&interest.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 9
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/hobbies&interest.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 5
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/holidays&events.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 5
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/holidays&events.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 5
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/holidays&events.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 3
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/love.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 3
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/love.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 3
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/love.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 6
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/music.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 6
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/music.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 6
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/music.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 8
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/news&politics.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 8
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/news&politics.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 8
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/news&politics.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 2
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/sports.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 2
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/sports.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 2
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/sports.jpg")
    wimage.save

    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 1
    wimage.the_order = 12
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/symbols&shapes.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 2
    wimage.the_order = 12
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/symbols&shapes.jpg")
    wimage.save
    wimage = WebsiteBannerImage.new
    wimage.website_banner_id = w.id
    wimage.locale_id = 3
    wimage.the_order = 12
    wimage.created_at = Time.now
    wimage.updated_at = Time.now
    wimage.alt = ""
    wimage.image = File.new("/var/www/izishirt/public/images/home_izi/symbols&shapes.jpg")
    wimage.save
  end

  def self.down
  end
end
