module Director
  module Helpers
    extend self

    def matches_constraint?(constraint, value, coerce: :itself)
      value = value.send(coerce)
      only = Array(constraint.only).map(&coerce)
      except = Array(constraint.except).map(&coerce)

      return false if only.present? && only.none? {|matcher| matches?(matcher, value) }
      return false if except.present? && except.any? {|matcher| matches?(matcher, value) }
      return true
    end

    def matches?(matcher, value)
      case matcher
      when Regexp
        matches_regexp?(matcher, value)
      when Proc
        matches_proc?(matcher, value)
      else
        matcher == value
      end
    end

    def matches_regexp?(matcher, value)
      case value
      when matcher
        true
      else
        false
      end
    end

    def matches_proc?(matcher, value)
      matcher.call(value)
    end
  end
end
