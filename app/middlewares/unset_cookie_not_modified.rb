class UnsetCookieNotModified
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)
    response[1].delete('Set-Cookie') if response[0] == 304
    response
  end 

end