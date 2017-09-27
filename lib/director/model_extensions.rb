# TEST: updates aliases after saving
#       doesn't update paths of aliases with blank corresponding path
#       incoming and outgoing alias associations work
#       path_alias is used to update the source and target path

module Director
  module ModelExtensions
    module ActMethod
      def has_aliases
        extend ClassMethods
        include Associations
        include Callbacks
        include InstanceMethods
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
      end
    end

    module Callbacks
      def self.included(base)
        base.after_save :update_aliased_paths
      end

      def path_alias
        raise NotImplementedError, "Should return a string representing the path alias that would route to this record"
      end

      private

      def update_aliased_paths
        path = path_alias
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
  end
end
