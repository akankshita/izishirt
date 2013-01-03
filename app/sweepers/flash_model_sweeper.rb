class FlashModelSweeper < ActionController::Caching::Sweeper
  observe Model, LocalizedModel, ModelZone, 
          ModelSizeSpec, OutOfStock, ModelSpecification, 
          Color, ModelPrice, BulkDiscount

  def after_save(model)
    expire_cache(model)
  end

  def after_destroy(model)
    expire_cache(model)
  end

  private 

  def expire_cache(model)
    #Will not work
    #expire_action :controller => 'create/models', :action => 'index', :format => 'fxml', :lang => 'australia'

    #Expire cache manualy
    VALID_HOSTS.each do |valid_host|
      RAILS_DEFAULT_LOGGER.error("Clear cache for host: #{valid_host}")
      ['','fr/','us/','fr-eu/','france/','uk/','australia/','eu/'].each do |lang|
        cache_dir = "/storage/cache_html/views/#{valid_host}/#{lang}create"
        if File.exist?(cache_dir)
          FileUtils.rm_r(Dir.glob(cache_dir+"/*")) rescue Errno::ENOENT
          RAILS_DEFAULT_LOGGER.error("##########  Cache Directory '#{cache_dir}' fully swept ########")
        end
      end
    end
  end
end
