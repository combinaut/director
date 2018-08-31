module Director
  class Alias < ActiveRecord::Base
    belongs_to :source, polymorphic: true
    belongs_to :target, polymorphic: true

    before_validation :sanitize_path
    validates_presence_of :source_path, unless: :source
    validates_presence_of :target_path, unless: :target
    validates_format_of :source_path, with: Configuration.constraints.source_path.only
    validates_format_of :target_path, with: Configuration.constraints.target_path.only
    validates_format_of :source_path, without: Configuration.constraints.source_path.except
    validates_format_of :target_path, without: Configuration.constraints.target_path.except
    validates_format_of :source_path, with: %r{\A/}, if: :source_path_relative?, message: 'is a relative path so it must start with a slash'
    validates_format_of :target_path, with: %r{\A/}, if: :target_path_relative?, message: 'is a relative path so it must start with a slash'
    validate :valid_paths
    validate :valid_handler

    scope :with_source_path, -> { where.not(source_path: nil) }
    scope :with_target_path, -> { where.not(target_path: nil) }

    before_save :set_source_path, if: :source_changed?
    before_save :set_target_path, if: :target_changed?

    def self.resolve_with_constraint(source_path, request)
      merge(Configuration.constraints.lookup_scope.call(request)).resolve(source_path)
    end

    # Returns the alias matching the source_path, traversing any chained aliases and returning the last one
    def self.resolve(source_path)
      source_path = sanitize_path(source_path)
      found = []

      # Traverse a chain of aliases
      while alias_entry = find_by_source_path(source_path) do
        raise AliasChainLoop, [*found.map(&:source_path), source_path].join(' -> ') if found.include?(alias_entry)
        break if alias_entry.passthrough? # Stop if we reach a passthrough since the app will handle this
        found << alias_entry
        break if alias_entry.redirect? # Stop if we reach a redirect since the browser will need to change url at that point
        source_path = alias_entry.target_path
      end

      return found.last
    end

    def self.valid_uri?(url)
      !!URI(url)
    rescue URI::InvalidURIError
      false
    end

    def self.relative?(url)
      URI(url).relative?
    rescue URI::InvalidURIError
      false
    end

    def self.sanitize_path(path = nil, &block)
      path = block.call if block_given?
      path = path.to_s
      path = path.strip
      path = path.remove(%r{/$})
      return path
    end

    def redirect?
      handler_class <= Handler::Redirect
    end

    def passthrough?
      handler_class <= Handler::Passthrough
    end

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

    def sanitize_path
      self.source_path = self.class.sanitize_path(source_path)
      self.target_path = self.class.sanitize_path(target_path)
    end

    def set_source_path
      self.source_path = source.generate_canonical_path if source
    end

    def set_target_path
      self.target_path = target.generate_canonical_path if target
    end

    def source_changed?
      source_path_changed? || source_id_changed? || source_type_changed?
    end

    def target_changed?
      target_path_changed? || target_id_changed? || target_type_changed?
    end

    def source_path_relative?
      self.class.relative?(source_path) if source_path?
    end

    def target_path_relative?
      self.class.relative?(target_path) if target_path?
    end

    def valid_handler
      handler_class
    rescue MissingAliasHandler
      errors.add(:handler, 'not defined')
    end

    def valid_paths
      errors.add(:source_path, 'is not a valid') unless self.class.valid_uri?(source_path)
      errors.add(:target_path, 'is not a valid') unless self.class.valid_uri?(target_path)
    end
  end

  # EXCEPTIONS

  class DirectorException < StandardError; end
  class MissingAliasHandler < DirectorException; end
  class AliasChainLoop < DirectorException; end
end
