class SetCookieDomain
  def initialize(app, default_domain)
    @app = app
    @default_domain = default_domain
  end

  def call(env)

    host = env["HTTP_HOST"].split(':').first
    subs = host.split('.')
    correct_host = subs[subs.length-2] + '.' + subs[subs.length-1]


    env["rack.session.options"][:domain] = custom_domain?(correct_host) ? ".#{correct_host}" : "#{@default_domain}"

    if RAILS_ENV=="staging"
       env["rack.session.options"][:domain] = @default_domain
    end
    @app.call(env)
  end

  def custom_domain?(host)
    domain = @default_domain.sub(/^\./, '')
    host !~ Regexp.new("#{domain}$", Regexp::IGNORECASE)
  end
end
