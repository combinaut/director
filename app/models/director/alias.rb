# TODO: Add pattern validation to allow base app to configure path whitelist
# TODO: Add ability to limit formats so assets, json, etc. can be ignored if desired

module Director
  class Alias < ActiveRecord::Base
    belongs_to :source
    belongs_to :target

    validates_presence_of :source_path, unless: :source
    validates_presence_of :target_path, unless: :target
    validates_presence_of :handler

    scope :with_source_path, -> { where.not(source_path: nil) }
    scope :with_target_path, -> { where.not(target_path: nil) }

    def handler_class
      "Director::Handler::#{handler.classify}".constantize
    end

    def effective_target_path
      alias_entry.target_path || alias_entry.record.path_alias
    end
  end
end
