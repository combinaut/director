module Director
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @request = Rack::Request.new(env)
      alias_entry = find_alias(@request.path_info) unless ignored_format?(format)
      return handle_alias(alias_entry, env)
    end

    private

    def find_alias(source_path)
      Director::Alias.find_by_source_path(source_path)
    end

    def handle_alias(alias_entry, env)
      return Handler.for(alias_entry).new(alias_entry).response(@app, env)
    end

    def ignored_format?(format)
      !Helpers.matches_constraint?(Configuration.constraints.format, format)
    end

    def format
      @request.path_info[/\.([^.]+)$/] || 'html'
    end
  end
end
