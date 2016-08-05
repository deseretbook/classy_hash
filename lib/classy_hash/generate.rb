# Classy Hash extended validation generators
# Copyright (C)2014 Deseret Book

module ClassyHash
  # This module contains helpers that generate constraints for common
  # ClassyHash validation tasks.
  module Generate
    # Used by the .all and .not generators.  Do not use directly.
    class Composite
      # Array of constraints to apply together.
      attr_reader :constraints

      # True if the constraints must all not match, false if they must all
      # match.
      attr_reader :negate

      # Initializes a composite constraint with the given Array of
      # +constraints+.  If +negate+ is true, then the constraints must all fail
      # for the value to pass.
      def initialize(constraints, negate = false)
        raise 'No constraints were given' if constraints.empty?

        @constraints = constraints
        @negate = negate
      end

      # Returns a String describing the composite constraint failing against
      # the given +value+.
      def describe(value)
        "#{negate ? 'none' : 'all'} of [#{CH.multiconstraint_string(constraints, value)}]"
      end
    end

    # Generates a constraint that requires a value to match *all* of the given
    # constraints.  If no constraints are given, always passes.
    #
    # Raises an error if no constraints are given.
    #
    # Example:
    #     schema = {
    #       a: CH::G.all(Integer, 1..100, CH::G.not(Set.new([7, 13])))
    #     }
    #     ClassyHash.validate({ a: 25 }, schema)
    def self.all(*constraints)
      Composite.new(constraints.freeze)
    end

    # Generates a constraint that requires a value to match *none* of the given
    # constraints.
    #
    # Raises an error if no constraints are given.
    #
    # Example:
    #     schema = {
    #       a: CH::G.not(Rational, BigDecimal)
    #     }
    #     ClassyHash.validate({ a: 1.25 }, schema)
    def self.not(*constraints)
      Composite.new(constraints.freeze, true)
    end

    # Deprecated.  Generates a ClassyHash constraint that ensures a value is
    # equal to one of the arguments in +args+.
    #
    # For new schemas, consider creating a Set with the enumeration elements.
    #
    # Example:
    #     schema = {
    #       a: ClassyHash::Generate.enum(1, 2, 3, 4)
    #     }
    #     ClassyHash.validate({ a: 1 }, schema)
    def self.enum(*args)
      Set.new(args)
    end

    # Generates a constraint that imposes a length limitation (an exact length
    # or a range) on any type that responds to the :length method (e.g. String,
    # Array, Hash).
    #
    # Example:
    #     schema = {
    #       a: ClassyHash::Generate.length(0..5)
    #     }
    #     ClassyHash.validate({a: '12345'}, schema)
    #     ClassyHash.validate({a: [1, 2, 3, 4, 5]}, schema)
    def self.length(length)
      raise "length must be an Integer or a Range" unless length.is_a?(Integer) || length.is_a?(Range)

      if length.is_a?(Range) && !(length.min.is_a?(Integer) && length.max.is_a?(Integer))
        raise "Range length endpoints must be Integers"
      end

      lambda {|v|
        if v.respond_to?(:length)
          if v.length == length || (length.is_a?(Range) && length.cover?(v.length))
            true
          else
            "of length #{length}"
          end
        else
          "a type that responds to :length"
        end
      }
    end

    # Generates a constraint that validates an Array's +length+ and contents
    # using one or more +constraints+.
    #
    # Example:
    #     schema = {
    #       a: ClassyHash::Generate.array_length(4..5, Integer, String)
    #     }
    #     ClassyHash.validate({ a: [ 1, 2, 3, 'four', 5 ] }, schema)
    def self.array_length(length, *constraints)
      raise 'one or more constraints must be provided' if constraints.empty?

      length_lambda = self.length(length)
      msg = "an Array of length #{length}"

      lambda {|v|
        if v.is_a?(Array)
          result = length_lambda.call(v)
          if result == true
            begin
              ClassyHash.validate({array: v}, {array: [constraints]})
              true
            rescue => e
              "valid: #{e}"
            end
          else
            msg
          end
        else
          msg
        end
      }
    end

    # Generates a constraint that validates the +length+ of a String.
    #
    # Example:
    #     schema = {
    #       a: ClassyHash::Generate.string_length(3)
    #     }
    #     ClassyHash.validate({a: '123'}, schema)
    def self.string_length(length)
      length_lambda = self.length(length)
      msg = "a String of length #{length}"

      lambda {|v|
        if v.is_a?(String)
          length_lambda.call(v) == true || msg
        else
          msg
        end
      }
    end
  end

  # Shortcut to ClassyHash::Generate
  G = Generate
end
