I18n.load_path += Dir[ File.join(RAILS_ROOT, 'lib', 'locale', '*.{rb,yml}') ]
I18n.default_locale = "en-CA"

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

#All country translations will fall
#back to en.yml or fr.yml
["CA","US"].each do |country|
  I18n.fallbacks.map("en-#{country}" => :en)
  I18n.fallbacks.map("fr-#{country}" => :fr)
end

