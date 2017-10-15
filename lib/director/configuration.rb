require 'ostruct'

module Director
  module Configuration
    mattr_reader :constraints

    Constraint = Struct.new(:only, :except)

    # Defaults
    @@constraints = OpenStruct.new({
      source_path: Constraint.new,
      target_path: Constraint.new,
      format: Constraint.new
    }).freeze
  end
end
