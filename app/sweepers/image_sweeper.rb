class ImageSweeper < ActionController::Caching::Sweeper
  observe Image # SWeeper keeps an eye on Image model

  #If sweeper detects image creation call this
  def after_save(image)
    self.class::sweep
  end

  def after_update(image)
    self.class::sweep
  end

  def after_destroy(image)
    self.class::sweep
  end

  def after_idliketovalidatethisdesignwithoutusingthebackofficeabc654897poi(image)
   self.class::sweep
  end

  private

  def self.sweep
    cache_dir = RAILS_ROOT+"/public/izishirt_flash"
    RAILS_DEFAULT_LOGGER.info("##########  Cache Directory '#{cache_dir}' ########")
    unless cache_dir == RAILS_ROOT+"/public"
      FileUtils.rm_r(Dir.glob(cache_dir+"/*")) rescue Errno::ENOENT
      RAILS_DEFAULT_LOGGER.info("##########  Cache Directory '#{cache_dir}' fully swept ########")
    end
  end

end
