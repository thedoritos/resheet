module Resheet
  class Authenticator
    def initialize(app)
      @app = app
    end

    def call(env)
      api_key = ENV['RESHEET_API_KEY']
      return @app.call(env) if api_key.nil?

      return [403, {}, []] unless env['HTTP_X_API_KEY'] == api_key

      @app.call(env)
    end
  end
end
