class TopDesign < ActiveRecord::Base

  belongs_to :image

  def self.find_top_designs_image_count_old(image_id, country_id = nil, lang_id = nil)
    where_specific = (country_id && lang_id) ? " AND EXISTS (SELECT * FROM addresses WHERE addresses.user_id = images.user_id AND addresses.country_id = #{country_id} AND users.language_id = #{lang_id})" : ""

    cnt = Image.count_by_sql("SELECT COUNT(orders.id) FROM images " +
          "INNER JOIN users ON images.user_id = users.id INNER JOIN ordered_zone_artworks ON ordered_zone_artworks.image_id = images.id " +
          "INNER JOIN ordered_products ON ordered_products.id = ordered_zones.ordered_product_id " +
          "INNER JOIN ordered_zones ON ordered_zones.id = ordered_zone_artworks.ordered_zone_id " +
          "INNER JOIN orders ON ordered_products.order_id = orders.id " +
          "WHERE images.active = 1 and images.pending_approval = 1 and images.is_private = 0 AND orders.created_on BETWEEN '#{Date.today-31}' AND '#{Date.today}' AND images.id = #{image_id} #{where_specific} ")

    return cnt
  end

  def self.find_top_designs_old(rows, country_id = nil, lang_id = nil)

    where_specific = (country_id && lang_id) ? " AND EXISTS (SELECT * FROM addresses WHERE addresses.user_id = images.user_id AND addresses.country_id = #{country_id} AND users.language_id = #{lang_id})" : ""

    designs = Image.find(:all, :conditions=>["images.active = 1 and images.pending_approval = 1 and images.is_private = 0 AND orders.created_on BETWEEN '#{Date.today-31}' AND '#{Date.today}' #{where_specific}"], :include => [:user],
      :joins => "INNER JOIN ordered_zone_artworks ON ordered_zone_artworks.image_id = images.id INNER JOIN ordered_zones ON ordered_zones.id = ordered_zone_artworks.ordered_zone_id INNER JOIN ordered_products ON ordered_products.id = ordered_zones.ordered_product_id INNER JOIN orders ON ordered_products.order_id = orders.id",
      :group => "ordered_zone_artworks.image_id",
      :order => "COUNT(ordered_zone_artworks.image_id) DESC",
      :limit => rows)
 
    designs
  end

  def self.find_top_designs_image_count(image_id, country_id = nil, lang_id = nil)
    where_specific = (country_id && lang_id) ? " AND EXISTS (SELECT * FROM addresses WHERE addresses.user_id = images.user_id AND addresses.country_id = #{country_id} AND users.language_id = #{lang_id})" : ""

    cnt = Image.count_by_sql("SELECT COUNT(DISTINCT orders.id) FROM images " +
          "INNER JOIN users ON images.user_id = users.id INNER JOIN ordered_zone_artworks ON ordered_zone_artworks.image_id = images.id INNER JOIN ordered_zones ON ordered_zones.id = ordered_zone_artworks.ordered_zone_id " +
          "INNER JOIN ordered_products ON ordered_products.id = ordered_zones.ordered_product_id " +
          "INNER JOIN orders ON ordered_products.order_id = orders.id " +
          "WHERE images.active = 1 and images.pending_approval = 1 and images.is_private = 0 AND orders.created_on BETWEEN '#{Date.today-31}' AND '#{Date.today}' AND images.id = #{image_id} #{where_specific} ")

    return cnt
  end

  def self.find_top_designs(rows, country_id = nil, lang_id = nil)

    where_specific = (country_id && lang_id) ? " AND EXISTS (SELECT * FROM addresses WHERE addresses.user_id = images.user_id AND addresses.country_id = #{country_id} AND users.language_id = #{lang_id})" : ""

    designs = Image.find(:all, :conditions=>["images.active = 1 and images.pending_approval = 1 and images.is_private = 0 AND orders.created_on BETWEEN '#{Date.today-31}' AND '#{Date.today}' #{where_specific} AND category_id NOT IN (#{TOP25_BLACKLISTED_CATEGORIES})"], :include => [:user],
      :joins => "INNER JOIN ordered_zone_artworks ON ordered_zone_artworks.image_id = images.id INNER JOIN ordered_zones ON ordered_zones.id = ordered_zone_artworks.ordered_zone_id INNER JOIN ordered_products ON ordered_products.id = ordered_zones.ordered_product_id INNER JOIN orders ON ordered_products.order_id = orders.id",
      :group => "ordered_zone_artworks.image_id",
      :order => "COUNT(DISTINCT orders.id) DESC",
      :limit => rows)

    designs
  end

  def self.repopulate_all(rows, country_id, lang_id, is_default)
    #designs = find_top_designs(rows, country_id, lang_id)
    designs = find_top_designs(rows)

    designs.each { |d|
      #nb = find_top_designs_image_count(d.id, country_id, lang_id)
      nb = find_top_designs_image_count(d.id)

      TopDesign.create(:date_created=>Time.now.to_s(:db), :country_id => country_id, :language_id => lang_id, :image_id=>d.id,:number_sold => nb,:is_default => is_default)
    }
  end

  def self.repopulate(rows)
    TopDesign.clear_top_designs()
    repopulate_all(rows, nil, nil, true)

    countries = Country.find_all_by_is_frontpage_country(1)
    languages = Language.all

    countries.each do |country|
      languages.each do |language|
        TopDesign.destroy_all(:country_id => country, :language_id => language.id)
        repopulate_all(rows, country.id, language.id, false)
      end
    end
  end

  def self.find_by_region(country, lang, limit=25)
    country = Country.find_by_shortname(country) ? Country.find_by_shortname(country).id : 0 
    @designs = TopDesign.find(:all, 
                              :limit => limit, 
                              :order => "number_sold DESC, date_created DESC", 
                              :include => :image, 
                              :conditions => {:is_default => false, :country_id => country.id, :language_id => lang})

    if @designs.size  == limit
      return @designs
    else
      return TopDesign.find_all_by_is_default(true, :limit=>limit)
    end
  end

  def self.reset(country,lang,rows)
    TopDesign.destroy_all(:country_id => country, :language_id => lang)
    designs = TopDesign.find_top_designs(rows, country, lang)
    
    designs.each { |d| 
      TopDesign.create(:date_created=>Time.now.to_s(:db),:image_id=>d.id,:number_sold=>d.ordered_zones.count,:is_default => false,:country_id => country, :language_id => lang)
    }
  end

  def self.clear_top_designs()
    TopDesign.destroy_all(:is_default => true)
  end

end
