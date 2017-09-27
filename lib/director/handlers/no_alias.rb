module Director
  module Handler
    class NoAlias < Base
      def response(app, env)
        app.call(env)
      end
    end
  end
end
