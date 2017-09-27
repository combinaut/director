module Director
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      alias_entry = find_alias(Rack::Request.new(env).path_info)
      response = handle_alias(alias_entry, env)
      return response
    end

    private

    def find_alias(source_path)
      Director::Alias.find_by_source_path(source_path)
    end

    def handle_alias(alias_entry, env)
      handler = Director::Handler::Base.for(alias_entry)
      return handler.new(alias_entry).response(@app, env)
    end
  end
end
