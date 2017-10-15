module Director
  module Helpers
    extend self

    def matches_constraint?(constraint, value, coerce = :to_s)
      value = value.send(coerce)
      only = Array(Configuration.constraints.format.only).map(&coerce)
      except = Array(Configuration.constraints.format.except).map(&coerce)

      return false if only.present? && only.exclude?(value)
      return false if except.present? && except.include?(value)
      return true
    end
  end
end
