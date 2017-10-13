# TODO: Add pattern validation to allow base app to configure path whitelist
# TODO: Add ability to limit formats so assets, json, etc. can be ignored if desired
# TEST: source_path is set if a source record is provided
# TEST: target_path is set if a target record is provided
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

    before_save :set_source_path, if: :source_changed?
    before_save :set_target_path, if: :target_changed?

    def handler_class
      handler_name = "Director::Handler::#{handler.classify}"
      handler_name.constantize
    rescue NameError
      raise MissingAliasHandler, "Handler not found '#{handler_name}'"
    end

    def blank?
      !(source_path? || target_path? || source || target)
    end

    private

    def set_source_path
      self.source_path = source.generate_canonical_path if source
    end

    def set_target_path
      self.target_path = target.generate_canonical_path if target
    end

    def source_changed?
      source_id_changed? || source_type_changed?
    end

    def target_changed?
      target_id_changed? || target_type_changed?
    end
  end

  # EXCEPTIONS

  class DirectorException < StandardError; end
  class MissingAliasHandler < DirectorException; end
end
