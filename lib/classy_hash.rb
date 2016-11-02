# Classy Hash: Keep Your Hashes Classy
# Created May 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book and Contributors (see git history)
# See LICENSE and README.md for details.
# frozen_string_literal: true

require 'set'
require 'securerandom'

# This module contains the ClassyHash methods for making sure Ruby Hash objects
# match a given schema.  ClassyHash runs fast by taking advantage of Ruby
# language features and avoiding object creation during validation.
module ClassyHash
  # Raised when a validation fails.  Allows ClassyHash#validate_full to
  # continue validation and gather all errors.
  class SchemaViolationError < StandardError
    # The list of errors passed to the constructor.  Contains an Array of Hashes:
    #   [
    #     { full_path: ClassyHash.join_path(parent_path, key), message: "something the full_path was supposed to be" },
    #     ...
    #   ]
    attr_reader :entries

    # Initializes a schema violation error with the given list of schema
    # +errors+.
    def initialize(errors = [])
      @entries = errors
    end

    # Joins all errors passed to the constructor into a comma-separated String.
    def to_s
      @msg ||= @entries.map{|e|
        "#{e[:full_path]} is not #{e[:message]}"
      }.join(', ')
    end
  end

  # Internal symbol representing the absence of a value for error message
  # generation.  Generated at runtime to prevent potential malicious use of the
  # no-value symbol.
  NO_VALUE = "__ch_no_value_#{SecureRandom.hex(10)}".to_sym

  # Validates a +value+ against a ClassyHash +constraint+.  Typically +value+
  # is a Hash and +constraint+ is a ClassyHash schema.
  #
  # Returns false if validation fails and errors were not raised.
  #
  # Parameters:
  #   value - The Hash or other value to validate.
  #   constraint - The schema or single constraint against which to validate.
  #   :strict - If true, rejects Hashes with members not in the schema.
  #           Applies to the top level and to nested Hashes.
  #   :full - If true, gathers all invalid values.  If false, stops checking at
  #           the first invalid value.
  #   :verbose - If true, the error message for failed strictness will include
  #           the names of the unexpected keys.  Note that this can be a
  #           security risk if the key names are controlled by an attacker and
  #           the result is sent via HTTPS (see e.g. the CRIME attack).
  #   :raise_errors - If true, any errors will be raised.  If false, they will
  #           be returned as a String.  Default is true.
  #   :errors - Used internally for aggregating error messages.  You can also
  #           pass in an Array here to collect any errors (useful if
  #           raise_errors is false).
  #   :parent_path - Used internally for tracking the current validation path
  #           in error messages (e.g. :key1[:key2][0]).
  #   :key - Used internally for tracking the current validation key in error
  #           messages (e.g. :key1 or 0).
  #
  # Examples:
  #   ClassyHash.validate({a: 1}, {a: Integer})
  #   ClassyHash.validate(1, Integer)
  def self.validate(value, constraint, strict: false, full: false, verbose: false,
                    raise_errors: true, errors: nil, parent_path: nil, key: NO_VALUE)
    errors = [] if errors.nil? && (full || !raise_errors)
    raise_below = raise_errors && !full

    case constraint
    when Class
      # Constrain value to be a specific class
      if constraint == TrueClass || constraint == FalseClass
        unless value == true || value == false
          add_error(raise_below, errors, parent_path, key, constraint, value)
          return false unless full
        end
      elsif !value.is_a?(constraint)
        add_error(raise_below, errors, parent_path, key, constraint, value)
        return false unless full
      end

    when Hash
      # Recursively check nested Hashes
      if !value.is_a?(Hash)
        add_error(raise_below, errors, parent_path, key, constraint, value)
        return false unless full
      else
        if strict
          extra_keys = value.keys - constraint.keys
          if extra_keys.any?
            if verbose
              msg = "valid: contains members #{extra_keys.map(&:inspect).join(', ')} not specified in schema"
            else
              msg = 'valid: contains members not specified in schema'
            end

            add_error(raise_below, errors, parent_path, key, msg, NO_VALUE)
            return false unless full
          end
        end

        parent_path = join_path(parent_path, key)

        constraint.each do |k, c|
          if value.include?(k)
            # TODO: Benchmark how much slower allocating a state object is than
            # passing lots of parameters?
            res = self.validate(
              value[k],
              c,
              strict: strict,
              full: full,
              verbose: verbose,
              raise_errors: raise_below,
              parent_path: parent_path,
              key: k,
              errors: errors
            )
            return false unless res || full
          elsif !(c.is_a?(Array) && c.first == :optional)
            add_error(raise_below, errors, parent_path, k, "present", NO_VALUE)
            return false unless full
          end
        end
      end

    when Array
      # Multiple choice or array validation
      if constraint.length == 1 && constraint.first.is_a?(Array)
        # Array validation
        if !value.is_a?(Array)
          add_error(raise_below, errors, parent_path, key, constraint, value)
          return false unless full
        else
          constraints = constraint.first
          value.each_with_index do |v, idx|
            res = self.check_multi(
              v,
              constraints,
              strict: strict,
              full: full,
              verbose: verbose,
              raise_errors: raise_below,
              parent_path: join_path(parent_path, key),
              key: idx,
              errors: errors
            )
            return false unless res || full
          end
        end
      else
        # Multiple choice
        res = self.check_multi(
          value,
          constraint,
          strict: strict,
          full: full,
          verbose: verbose,
          raise_errors: raise_below,
          parent_path: parent_path,
          key: key,
          errors: errors
        )
        return false unless res || full
      end

    when Regexp
      # Constrain value to be a String matching a Regexp
      unless value.is_a?(String) && value =~ constraint
        add_error(raise_below, errors, parent_path, key, constraint, value)
        return false unless full
      end

    when Proc
      # User-specified validator
      result = constraint.call(value)
      if result != true
        if result.is_a?(String)
          add_error(raise_below, errors, parent_path, key, result, NO_VALUE)
        else
          add_error(raise_below, errors, parent_path, key, constraint, value)
        end
        return false unless full
      end

    when Range
      # Range (with type checking for common classes)
      range_type_valid = true

      if constraint.min.is_a?(Integer) && constraint.max.is_a?(Integer)
        unless value.is_a?(Integer)
          add_error(raise_below, errors, parent_path, key, constraint, value)
          return false unless full
          range_type_valid = false
        end
      elsif constraint.min.is_a?(Numeric)
        unless value.is_a?(Numeric)
          add_error(raise_below, errors, parent_path, key, constraint, value)
          return false unless full
          range_type_valid = false
        end
      elsif constraint.min.is_a?(String)
        unless value.is_a?(String)
          add_error(raise_below, errors, parent_path, key, constraint, value)
          return false unless full
          range_type_valid = false
        end
      end

      if range_type_valid && !constraint.cover?(value)
        add_error(raise_below, errors, parent_path, key, constraint, value)
        return false unless full
      end

    when Set
      # Set/enumeration
      unless constraint.include?(value)
        add_error(raise_below, errors, parent_path, key, constraint, value)
        return false unless full
      end

    when CH::G::Composite
      constraint.constraints.each do |c|
        result = self.validate(
          value,
          c,
          strict: strict,
          full: full,
          verbose: verbose,
          raise_errors: false,
          parent_path: parent_path,
          key: key,
          errors: nil
        )

        if constraint.negate == result
          add_error(raise_below, errors, parent_path, key, constraint, value)
          return false unless full
          break
        end
      end

    when :optional
      # Optional key marker in multiple choice validators (do nothing)

    else
      # Unknown schema constraint
      add_error(raise_below, errors, parent_path, key, constraint, value)
      return false unless full
    end

    if raise_errors && errors && errors.any?
      raise SchemaViolationError, errors
    end

    errors.nil? || errors.empty?
  end

  # Deprecated.  Retained for compatibility with v0.1.x.  Calls .validate with
  # :strict set to true.  If +verbose+ is true, the names of unexpected keys
  # will be included in the error message.
  def self.validate_strict(hash, schema, verbose=false, parent_path=nil)
    validate(hash, schema, parent_path: parent_path, verbose: verbose, strict: true)
  end

  # Raises an error unless the given +value+ matches one of the given multiple
  # choice +constraints+.  Other parameters are used for internal state.  If
  # +full+ is true, the error message for an invalid value will include the
  # errors for all of the failing components of the multiple choice constraint.
  def self.check_multi(value, constraints, strict: nil, full: nil, verbose: nil, raise_errors: nil,
                       parent_path: nil, key: nil, errors: nil)
    if constraints.length == 0 || constraints.length == 1 && constraints.first == :optional
      return add_error(raise_errors, errors,
        parent_path,
        key,
        "a valid multiple choice constraint (array must not be empty)",
        NO_VALUE
      )
    end

    # Optimize the common case of a direct class match
    return true if constraints.include?(value.class)

    local_errors = []
    constraints.each do |c|
      next if c == :optional

      constraint_errors = []

      # Only need one match to accept the value, so return if one is found
      return true if self.validate(
        value,
        c,
        strict: strict,
        full: full,
        verbose: verbose,
        raise_errors: false,
        parent_path: parent_path,
        key: key,
        errors: constraint_errors
      )

      local_errors << { constraint: c, errors: constraint_errors }
    end

    # Accumulate all errors if full, the constraint with the most similar keys
    # and fewest errors if a Hash or Array, or just the constraint with the
    # fewest errors otherwise.  This doesn't always choose the intended
    # constraint for error reporting, which would require a more complex
    # algorithm.
    #
    # See https://github.com/deseretbook/classy_hash/pull/16#issuecomment-257484267
    if full
      local_errors.map!{|e| e[:errors] }
      local_errors.flatten!
    elsif value.is_a?(Hash)
      # Prefer error messages from similar-looking hash constraints for hashes
      local_errors = local_errors.min_by{|err|
        c = err[:constraint]
        e = err[:errors]

        if c.is_a?(Hash)
          keydiff = (c.keys | value.keys) - (c.keys & value.keys)
          [ keydiff.length, e.length ]
        else
          [ 1<<30, e.length ] # Put non-hashes after hashes
        end
      }[:errors]
    elsif value.is_a?(Array)
      # Prefer error messages from array constraints for arrays
      local_errors = local_errors.min_by{|err|
        c = err[:constraint]
        [
          c.is_a?(Array) ? (c.first.is_a?(Array) ? 0 : 1) : 2,
          err[:errors].length
        ]
      }[:errors]
    else
      local_errors = local_errors.min_by{|e| e[:errors].length }[:errors]
    end

    errors.concat(local_errors) if errors
    add_error(raise_errors, errors || local_errors, parent_path, key, constraints, value)
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

    when :optional
      "absent (marked as :optional)"

    else
      "a valid schema constraint: #{constraint.inspect}"

    end
  end

  # Joins parent_path and key for display in error messages.
  def self.join_path(parent_path, key)
    if parent_path
      "#{parent_path}[#{key.inspect}]"
    elsif key == NO_VALUE
      nil
    else
      key.inspect
    end
  end

  # Raises or adds to +errors+ an error indicating that the given +key+ under
  # the given +parent_path+ fails because the value is not valid.  If
  # +constraint+ is a String, then it will be used as the error message.
  # Otherwise
  #
  # If +raise_errors+ is true, raises an error immediately.  Otherwise adds an
  # error to +errors+.
  #
  # See .constraint_string.
  def self.add_error(raise_errors, errors, parent_path, key, constraint, value)
    message = constraint.is_a?(String) ? constraint : constraint_string(constraint, value)
    entry = { full_path: self.join_path(parent_path, key) || 'Top level', message: message }

    if raise_errors
      errors ||= []
      errors << entry
      raise SchemaViolationError, errors
    else
      errors << entry if errors
      return false
    end
  end
end

require 'classy_hash/generate'

if !Kernel.const_defined?(:CH)
  CH = ClassyHash
end
