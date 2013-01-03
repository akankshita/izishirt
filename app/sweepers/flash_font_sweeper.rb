class FlashFontSweeper < ActionController::Caching::Sweeper
  observe Font

  def after_save(font)
    expire_cache(font)
  end

  def after_destroy(font)
    expire_cache(font)
  end

  private 

  def expire_cache(font)
    #Will not work
    #expire_action :controller => 'create/models', :action => 'index', :format => 'fxml', :lang => 'australia'


    #Expire cache manualy
    VALID_HOSTS.each do |valid_host|
      ['','fr/','us/','fr-eu/','france/','uk/','australia/','eu/'].each do |lang|
        cache_dir = "/storage/cache_html/views/#{valid_host}/#{lang}create"
        if File.exist?(cache_dir)
          FileUtils.rm_r(Dir.glob(cache_dir+"/*")) rescue Errno::ENOENT
          RAILS_DEFAULT_LOGGER.info("##########  Cache Directory '#{cache_dir}' fully swept ########")
        end
      end
    end
  end
end
