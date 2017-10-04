module Director
  module Handler
    class Passthrough < Base
      def response(app, env)
        app.call(env)
      end
    end
  end
end
