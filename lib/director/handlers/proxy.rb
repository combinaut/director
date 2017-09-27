module Director
  module Handler
    class Proxy < Base
      def response(app, env)
        Rack::Request.new(env).path_info = target_path
        app.call(env)
      end
    end
  end
end
