module Director
  module Handler
    class Redirect < Base
      def response(app, env)
        res = Rack::Response.new
        redirect_uri = target_uri.dup
        redirect_uri.query = merge_query(target_uri.query, request_uri(env).query)

        res.redirect(redirect_uri.to_s || '/')
        res.finish
      end
    end
  end
end
