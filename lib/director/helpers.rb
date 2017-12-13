module Director
  module Helpers
    extend self

    def matches_constraint?(constraint, value, coerce: :itself)
      value = value.send(coerce)
      only = Array(constraint.only).map(&coerce)
      except = Array(constraint.except).map(&coerce)

      return false if only.present? && only.none? {|pattern| matches?(pattern, value) }
      return false if except.present? && except.any? {|pattern| matches?(pattern, value) }
      return true
    end

    def matches?(pattern, value)
      case value
      when pattern
        true
      else
        false
      end
    end
  end
end
