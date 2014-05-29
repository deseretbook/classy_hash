# Classy Hash: Keep Your Hashes Classy
# Created May 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

# This module contains the ClassyHash methods for making sure Ruby Hash objects
# match a given schema.  ClassyHash runs fast by taking advantage of Ruby
# language features and avoiding object creation during validation.
module ClassyHash
  # Validates a +hash+ against a +schema+.  The +parent_path+ parameter is used
  # internally to generate error messages.
  def self.validate(hash, schema, parent_path=nil)
    schema.each do |key, constraint|
      # TODO: option to allow missing, or a separate strict method (could use array subtraction)
      raise "Missing key #{parent_path}#{key.inspect}" unless hash.include?(key)

      value = hash[key]

      case constraint
      when Class
        # Constrain value to be a specific class
        if constraint == TrueClass || constraint == FalseClass
          unless value == true || value == false
            raise "#{parent_path}#{key.inspect} is not true or false"
          end
        elsif !value.is_a?(constraint)
          raise "#{parent_path}#{key.inspect} is not a #{constraint}"
        end

      when Hash
        # Recursively check nested Hashes
        raise "#{parent_path}#{key.inspect} is not a Hash" unless value.is_a?(Hash)
        self.validate(value, constraint, "#{parent_path}#{key.inspect}.")

      else
        # Unknown schema constraint
        raise "Invalid schema constraint on #{parent_path}#{key.inspect}: #{constraint.inspect}"
      end

      # TODO: Ability to validate arrays, allow nil, allow multiple types, allow procs, validate all keys
    end

    nil
  end
end
