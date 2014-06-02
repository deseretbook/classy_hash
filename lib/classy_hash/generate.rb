
module ClassyHash
  # This module contains helpers that generate constraints for common
  # ClassyHash validation tasks.
  module Generate
    # Generates a ClassyHash constraint that ensures a value is equal to one of
    # the arguments in +args+.
    #
    # Example:
    #     schema = {
    #       a: ClassyHash::Generate.enum(1, 2, 3, 4)
    #     }
    #     ClassyHash.validate({ a: 1 }, schema)
    def self.enum *args
      lambda {|v|
        args.include?(v) || "an element of #{args.inspect}"
      }
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
    def self.length length
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
    def self.array_length length, *constraints
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
    def self.string_length length
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
end
