module Director
  class Middleware
    def self.handled_request?(request)
      request.env['director.original_url'].present?
    end

    def self.original_request_url(request)
      request.env['director.original_url'] || request.url
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      @request = Rack::Request.new(env)

      unless ignored?
        env['director.original_url'] = @request.url
        alias_entry = Director::Alias.resolve_with_constraint(request_path, @request)
      end

      return handle_alias(alias_entry, env)
    end

    private

    def handle_alias(alias_entry, env)
      return Handler.for(alias_entry).new(alias_entry).response(@app, env)
    end

    def ignored?
      ignored_format?(format) || ignored_path?(request_path) || ignored_request?(@request)
    end

    def ignored_format?(format)
      !Helpers.matches_constraint?(Configuration.constraints.format, format, coerce: :to_s)
    end

    def ignored_path?(path)
      !Helpers.matches_constraint?(Configuration.constraints.source_path, path)
    end

    def ignored_request?(request)
      !Helpers.matches_constraint?(Configuration.constraints.request, request)
    end

    def format
      request_path[/\.([^.]+)$/, 1] || 'html'
    end

    def request_path
      @request.path_info
    end
  end
end
