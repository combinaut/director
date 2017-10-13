# TEST: updates aliases after saving
#       doesn't update paths of aliases with blank corresponding path
#       incoming and outgoing alias associations work
#       path_alias is used to update the source and target path
#       blank aliases are ignored when saving

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
      BLANK_ALIAS = ->(attributes) { Director::Alias.new(attributes).blank? }

      def self.included(base)
        base.has_many :incoming_aliases, class_name: 'Director::Alias', as: :target, dependent: :delete_all
        base.has_one :outgoing_alias, class_name: 'Director::Alias', as: :source, dependent: :delete

        base.class_attribute :aliased_paths_options
        base.accepts_nested_attributes_for :incoming_aliases, reject_if: BLANK_ALIAS, allow_destroy: true
        base.accepts_nested_attributes_for :outgoing_alias, reject_if: BLANK_ALIAS, allow_destroy: true
      end
    end

    module Callbacks
      def self.included(base)
        base.after_save :update_aliased_paths
      end

      def generate_canonical_path
        generator = aliased_paths_options[:canonical_path]
        case generator
        when Symbol
          send(generator)
        when Proc
          generator.call(self)
        when String
          generator
        else # Assume it's an object that responds to canonical_path
          generator.send(:canonical_path)
        end
      end

      private

      def update_aliased_paths
        path = generate_canonical_path
        update_incoming_alias_paths(path)
        update_outgoing_alias_paths(path)
      end

      def update_incoming_alias_paths(path)
        Alias.where(target: self).update_all(target_path: path)
      end

      def update_outgoing_alias_paths(path)
        Alias.where(source: self).update_all(source_path: path)
      end
    end
  end
end
