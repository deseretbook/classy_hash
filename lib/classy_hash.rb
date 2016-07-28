# Classy Hash: Keep Your Hashes Classy
# Created May 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book
# See LICENSE and README.md for details.

require 'set'
require 'securerandom'

# This module contains the ClassyHash methods for making sure Ruby Hash objects
# match a given schema.  ClassyHash runs fast by taking advantage of Ruby
# language features and avoiding object creation during validation.
module ClassyHash
  # Internal symbol representing the absence of a value for error message
  # generation.  Generated at runtime to prevent potential malicious use of the
  # no-value symbol.
  NO_VALUE = "__ch_no_value_#{SecureRandom.hex(10)}".to_sym


  # Validates a +hash+ against a +schema+.  The +parent_path+ parameter is used
  # internally to generate error messages.
  def self.validate(hash, schema, parent_path=nil, verbose=false, strict=false, deep=false)
    raise 'Must validate a Hash' unless hash.is_a?(Hash) # TODO: Allow validating other types by passing to #check_one?
    raise 'Schema must be a Hash' unless schema.is_a?(Hash) # TODO: Allow individual element validations?

    if strict && (hash.keys - schema.keys).any?
      members = "(#{(hash.keys - schema.keys).inspect.delete('[]')})" if verbose
      raise "Hash contains members #{members} not specified in schema".squeeze(' ')
    end

    schema.each do |key, constraint|
      if hash.include?(key)
        self.check_one(key, hash[key], constraint, parent_path, verbose, deep)
      elsif !(constraint.is_a?(Array) && constraint.include?(:optional))
        self.raise_error(parent_path, key, "present", NO_VALUE)
      end
    end

    nil
  end

  # As with #validate, but members not specified in the +schema+ are forbidden.
  # Only the top-level schema is strictly validated.  If +verbose+ is true, the
  # names of unexpected keys will be included in the error message.
  def self.validate_strict(hash, schema, verbose=false, parent_path=nil)
    validate(hash, schema, parent_path, verbose, true, false)
  end

  # As with #validate_strict, but deep members not specified in the +schema+ are forbidden.
  def self.deep_validate_strict(hash, schema, verbose=false, parent_path=nil)
    validate(hash, schema, parent_path, verbose, true, true)
  end

  # Raises an error unless the given +value+ matches one of the given multiple
  # choice +constraints+.
  def self.check_multi(key, value, constraints, parent_path=nil, verbose=false, strict=false)
    if constraints.length == 0
      self.raise_error(
        parent_path,
        key,
        "a valid multiple choice constraint (array must not be empty)",
        NO_VALUE
      )
    end

    # Optimize the common case of a direct class match
    return if constraints.include?(value.class)

    error = nil
    constraints.each do |c|
      next if c == :optional
      begin
        self.check_one(key, value, c, parent_path, verbose, strict)
        return
      rescue => e
        # Throw schema and array errors immediately
        if (c.is_a?(Hash) && value.is_a?(Hash)) ||
          (c.is_a?(Array) && value.is_a?(Array) && c.length == 1 && c.first.is_a?(Array))
          raise e
        end
      end
    end

    self.raise_error(parent_path, key, constraints, value)
  end

  # Generates a String describing the +value+'s failure to match the
  # +constraint+.  The value itself should not be included in the string to
  # avoid attacker-controlled plaintext.  If +value+ is CH::NO_VALUE, then
  # generic error messages will be used for constraints (e.g. Procs) that would
  # otherwise have been value-dependent.
  def self.constraint_string(constraint, value)
    case constraint
    when Hash
      "a Hash matching {schema with keys #{constraint.keys.inspect}}"

    when Class
      if constraint == TrueClass || constraint == FalseClass
        'true or false'
      else
        "a/an #{constraint}"
      end

    when Array
      if constraint.length == 1 && constraint.first.is_a?(Array)
        "an Array of #{constraint_string(constraint.first, NO_VALUE)}"
      else
        "one of #{constraint.map{|c| constraint_string(c, value) }.join(', ')}"
      end

    when Regexp
      "a String matching #{constraint.inspect}"

    when Proc
      if value != NO_VALUE && (result = constraint.call(value)).is_a?(String)
        result
      else
        # TODO: does Proc#inspect give too much information about source code
        # layout to an attacker?
        "accepted by #{constraint.inspect}"
      end

    when Range
      base = "in range #{constraint.inspect}"

      if constraint.min.is_a?(Integer) && constraint.max.is_a?(Integer)
        "an Integer #{base}"
      elsif constraint.min.is_a?(Numeric)
        "a Numeric #{base}"
      elsif constraint.min.is_a?(String)
        "a String #{base}"
      else
        base
      end

    when Set
      "an element of #{constraint.to_a.inspect}"

    when CH::G::Composite
      constraint.describe(value)

    else
      "a valid schema constraint: #{constraint.inspect}"

    end
  end

  # Checks a single value against a single constraint.
  def self.check_one(key, value, constraint, parent_path=nil, verbose=false, strict=false)
    case constraint
    when Class
      # Constrain value to be a specific class
      if constraint == TrueClass || constraint == FalseClass
        unless value == true || value == false
          self.raise_error(parent_path, key, constraint, value)
        end
      elsif !value.is_a?(constraint)
        self.raise_error(parent_path, key, constraint, value)
      end

    when Hash
      # Recursively check nested Hashes
      self.raise_error(parent_path, key, constraint, value) unless value.is_a?(Hash)
      self.validate(value, constraint, self.join_path(parent_path, key), verbose, strict, strict)

    when Array
      # Multiple choice or array validation
      if constraint.length == 1 && constraint.first.is_a?(Array)
        # Array validation
        self.raise_error(parent_path, key, constraint, value) unless value.is_a?(Array)

        constraints = constraint.first
        value.each_with_index do |v, idx|
          self.check_multi(idx, v, constraints, self.join_path(parent_path, key), verbose, strict)
        end
      else
        # Multiple choice
        self.check_multi(key, value, constraint, parent_path, verbose, strict)
      end

    when Regexp
      # Constrain value to be a String matching a Regexp
      unless value.is_a?(String) && value =~ constraint
        self.raise_error(parent_path, key, constraint, value)
      end

    when Proc
      # User-specified validator
      result = constraint.call(value)
      if result != true
        self.raise_error(parent_path, key, constraint, value)
      end

    when Range
      # Range (with type checking for common classes)
      if constraint.min.is_a?(Integer) && constraint.max.is_a?(Integer)
        self.raise_error(parent_path, key, constraint, value) unless value.is_a?(Integer)
      elsif constraint.min.is_a?(Numeric)
        self.raise_error(parent_path, key, constraint, value) unless value.is_a?(Numeric)
      elsif constraint.min.is_a?(String)
        self.raise_error(parent_path, key, constraint, value) unless value.is_a?(String)
      end

      unless constraint.cover?(value)
        self.raise_error(parent_path, key, constraint, value)
      end

    when Set
      # Set/enumeration
      unless constraint.include?(value)
        self.raise_error(parent_path, key, constraint, value)
      end

    when CH::G::Composite
      constraint.constraints.each do |c|
        # TODO: don't use exceptions internally; they are slow
        negfail = false
        begin
          self.check_one(key, value, c, parent_path)

          if constraint.negate
            negfail = true
            self.raise_error(parent_path, key, constraint, value)
          end
        rescue => e
          unless constraint.negate && !negfail
            self.raise_error(parent_path, key, constraint, value)
          end
        end
      end

    when :optional
      # Optional key marker in multiple choice validators
      nil

    else
      # Unknown schema constraint
      self.raise_error(parent_path, key, constraint, value)
    end

    nil
  end

  def self.join_path(parent_path, key)
    parent_path ? "#{parent_path}[#{key.inspect}]" : key.inspect
  end

  # Raises an error indicating that the given +key+ under the given
  # +parent_path+ fails because the value "is not #{+message+}".
  def self.raise_error(parent_path, key, constraint, value)
    # TODO: Ability to validate all keys
    message = constraint.is_a?(String) ? constraint : constraint_string(constraint, value)
    raise "#{self.join_path(parent_path, key)} is not #{message}"
  end
end

require 'classy_hash/generate'

if !Kernel.const_defined?(:CH)
  CH = ClassyHash
end
