module Director
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @request = Rack::Request.new(env)
      alias_entry = find_alias(request_path) unless ignored?
      return handle_alias(alias_entry, env)
    end

    private

    def find_alias(source_path)
      found = []

      # Traverse a chain of aliases
      while alias_entry = Director::Alias.find_by_source_path(source_path) do
        raise AliasLoopException, found.map(&:source_path).joins(' -> ') + source_path if found.include?(alias_entry)
        found << alias_entry
        source_path = alias_entry.target_path
      end

      return found.last
    end

    def handle_alias(alias_entry, env)
      return Handler.for(alias_entry).new(alias_entry).response(@app, env)
    end

    def ignored?
      ignored_format?(format) || ignored_path?(request_path)
    end

    def ignored_format?(format)
      !Helpers.matches_constraint?(Configuration.constraints.format, format, coerce: :to_s)
    end

    def ignored_path?(path)
      !Helpers.matches_constraint?(Configuration.constraints.source_path, path)
    end

    def format
      request_path[/\.([^.]+)$/, 1] || 'html'
    end

    def request_path
      @request.path_info
    end
  end

  # EXCEPTIONS

  class AliasLoopException < StandardError; end
end
