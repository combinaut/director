module Director
  module Handler
    def self.for(alias_entry)
      return Passthrough unless alias_entry
      alias_entry.handler_class
    end
  end
end
