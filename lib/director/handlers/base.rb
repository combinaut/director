# TEST: individual handlers work when a target_path is present
# TEST: individual handlers work when only a target is present
# TEST: individual handlers can redirect to "" without looping indefinitely
require 'uri'

module Director
  module Handler
    class Base
      attr_reader :alias_entry

      def initialize(alias_entry)
        @alias_entry = alias_entry
      end

      def response(app, env)
        raise NotImplementedError
      end

      private

      def request_uri(env)
        URI(Rack::Request.new(env).url).freeze
      end

      def target_uri
        URI(alias_entry.target_path).freeze
      end

      def merge_query(query1, query2)
        [query1, query2].select(&:present?).join('&').presence
      end
    end
  end
end
