module Director
  module Handler
    class Proxy < Base
      def response(app, env)
        env['QUERY_STRING'] = merge_query(target_uri.query, request_uri(env).query)
        env['PATH_INFO'] = target_uri.path

        app.call(env)
      end
    end
  end
end
