# TODO: Add pattern validation to allow base app to configure path whitelist
# TODO: Add ability to limit formats so assets, json, etc. can be ignored if desired
# TEST: source_path is set if only a source record is provided
# TEST: can't create cycle

module Director
  class Alias < ActiveRecord::Base
    belongs_to :source, polymorphic: true
    belongs_to :target, polymorphic: true

    validates_presence_of :source_path, unless: :source
    validates_presence_of :target_path, unless: :target
    validates_presence_of :handler

    scope :with_source_path, -> { where.not(source_path: nil) }
    scope :with_target_path, -> { where.not(target_path: nil) }

    before_save :set_source_path, unless: :source_path?


    def handler_class
      "Director::Handler::#{handler.classify}".constantize
    end

    def effective_target_path
      target_path || generate_canonical_path(source, source.aliased_paths_options[]) .path_alias
    end

    def blank?
      !(source_path? || target_path? || source || target)
    end

    private

    def set_source_path
      self.source_path = source.generate_canonical_path if source
    end
  end
end
