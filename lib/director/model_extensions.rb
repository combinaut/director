# TEST: updates aliases after saving
#       doesn't update paths of aliases with blank corresponding path
#       incoming and outgoing alias associations work
#       path_alias is used to update the source and target path

module Director
  module ModelExtensions
    module ActMethod
      def has_aliased_paths(canonical_path: )
        extend ClassMethods
        include Associations
        include Callbacks
        include InstanceMethods

        self.aliased_paths_options = { canonical_path: canonical_path }
      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

    module Associations
      def self.included(base)
        base.has_many :incoming_aliases, class_name: 'Director::Alias', foreign_key: :target, dependent: :delete_all
        base.has_many :outgoing_aliases, class_name: 'Director::Alias', foreign_key: :source, dependent: :delete_all

        class_attribute :aliased_paths_options
      end
    end

    module Callbacks
      def self.included(base)
        base.after_save :update_aliased_paths
      end

      private

      def update_aliased_paths
        path = HelperMethods.generate_canonical_path(self, aliased_paths_options[:canonical_path])
        update_incoming_alias_paths(path)
        update_outgoing_alias_paths(path)
      end

      def update_incoming_alias_paths(path)
        incoming_aliases.with_target_path.update_all(target_path: path)
      end

      def update_outgoing_alias_paths(path)
        outgoing_aliases.with_source_path.update_all(source_path: path)
      end
    end

    module HelperMethods
      def self.generate_canonical_path(record, canonical_path)
        case canonical_path
        when Symbol
          record.send(canonical_path)
        when Proc
          canonical_path.call(record)
        when String
          canonical_path
        else # Assume it's an object that responds to canonical_path
          canonical_path.send(:canonical_path)
        end
      end
    end
  end
end
