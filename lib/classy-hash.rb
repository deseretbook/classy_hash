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
      self.raise_error(parent_path, key, "present") unless hash.include?(key)

      self.check_one(key, hash[key], constraint, parent_path)
    end

    nil
  end

  # Raises an error unless the given +value+ matches one of the given multiple
  # choice +constraints+.
  def self.check_multi(key, value, constraints, parent_path=nil)
    # Optimize the common case of a direct class match
    return if constraints.include?(value.class)

    error = nil
    constraints.each do |c|
      begin
        self.check_one(key, value, c, parent_path)
        return
      rescue => e
        if c.is_a?(Hash) && value.is_a?(Hash)
          raise e # Throw schema errors immediately
        end

        error = e
      end
    end

    self.raise_error(parent_path, key, "one of #{multiconstraint_string(constraints)}")
  end

  # Generates a semi-compact String describing the given +constraints+.
  def self.multiconstraint_string constraints
    constraints.map{|c|
      if c.is_a?(Hash)
        "{...schema...}"
      elsif c.is_a?(Array)
        "[#{self.multiconstraint_string(c)}]"
      else
        c.inspect
      end
    }.join(', ')
  end

  # Checks a single value against a single constraint.
  def self.check_one(key, value, constraint, parent_path=nil)
    case constraint
    when Class
      # Constrain value to be a specific class
      if constraint == TrueClass || constraint == FalseClass
        unless value == true || value == false
          self.raise_error(parent_path, key, "true or false")
        end
      elsif !value.is_a?(constraint)
        self.raise_error(parent_path, key, "a/an #{constraint}")
      end

    when Hash
      # Recursively check nested Hashes
      self.raise_error(parent_path, key, "a Hash") unless value.is_a?(Hash)
      self.validate(value, constraint, self.join_path(parent_path, key))

    when Array
      # Multiple choice or array validation
      if constraint.length == 1 && constraint.first.is_a?(Array)
        # Array validation
        self.raise_error(parent_path, key, "an Array") unless value.is_a?(Array)

        constraints = constraint.first
        value.each_with_index do |v, idx|
          self.check_multi(idx, v, constraints, self.join_path(parent_path, key))
        end
      else
        # Multiple choice
        self.check_multi(key, value, constraint, parent_path)
      end

    when Proc
      # User-specified validator
      result = constraint.call(value)
      if result != true
        self.raise_error(parent_path, key, result.is_a?(String) ? result : "accepted by Proc")
      end

    when Range
      # Range (with type checking for common classes)
      if constraint.min.is_a?(Integer) && constraint.max.is_a?(Integer)
        self.raise_error(parent_path, key, "an Integer") unless value.is_a?(Integer)
      elsif constraint.min.is_a?(Numeric)
        self.raise_error(parent_path, key, "a Numeric") unless value.is_a?(Numeric)
      elsif constraint.min.is_a?(String)
        self.raise_error(parent_path, key, "a String") unless value.is_a?(String)
      end

      unless constraint.cover?(value)
        self.raise_error(parent_path, key, "in range #{constraint.inspect}")
      end

      # TODO: Ability to validate all keys

    else
      # Unknown schema constraint
      self.raise_error(parent_path, key, "a valid schema constraint: #{constraint.inspect}")
    end

    nil
  end

  def self.join_path(parent_path, key)
    parent_path ? "#{parent_path}[#{key.inspect}]" : key.inspect
  end

  # Raises an error indicating that the given +key+ under the given
  # +parent_path+ fails because the value "is not #{+message+}".
  def self.raise_error(parent_path, key, message)
    raise "#{self.join_path(parent_path, key)} is not #{message}"
  end
end
