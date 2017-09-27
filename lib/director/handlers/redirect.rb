module Director
  module Handler
    class Redirect < Base
      def response(*)
        res = Rack::Response.new
        res.redirect(target_path)
        res.finish
      end
    end
  end
end
