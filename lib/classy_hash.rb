# Classy Hash: Keep Your Hashes Classy
# Created May 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book and Contributors (see git history)
# See LICENSE and README.md for details.
# frozen_string_literal: true

require 'set'
require 'securerandom'
require 'continuation'

# This module contains the ClassyHash methods for making sure Ruby Hash objects
# match a given schema.  ClassyHash runs fast by taking advantage of Ruby
# language features and avoiding object creation during validation.
module ClassyHash
  # Raised when a validation fails.  Allows ClassyHash#validate_full to
  # continue validation and gather all errors.
  class SchemaViolationError < StandardError
    # The list of errors passed to the constructor.  Contains an Array of Hashes:
    #   [
    #     { full_path: ClassyHash.join_path(parent_path, key), message: message },
    #     ...
    #   ]
    attr_reader :entries

    # Initializes a schema violation error with the given list of schema
    # +errors+ and a continuation (+cont+) for resuming execution.
    def initialize(errors = [], cont = nil)
      @entries, @cont = errors, cont
    end

    # Resumes execution using the continuation passed to the constructor.
    def continue
      @cont.call
    end

    # Joins all errors passed to the constructor into a comma-separated String.
    def full_message
      @entries.each_with_object [] do |entry, list|
        if entry[:full_path]
          list << "#{entry[:full_path]} is not #{entry[:message]}"
        else
          list << entry[:message]
        end
      end.join(', ')
    end
    alias_method :to_s, :full_message
  end

  # Internal symbol representing the absence of a value for error message
  # generation.  Generated at runtime to prevent potential malicious use of the
  # no-value symbol.
  NO_VALUE = "__ch_no_value_#{SecureRandom.hex(10)}".to_sym

  # Validates a +value+ against a ClassyHash +constraint+.  Typically +value+
  # is a Hash and +constraint+ is a ClassyHash schema.
  #
  # Parameters:
  #   value - The Hash or other value to validate.
  #   constraint - The schema or single constraint against which to validate.
  #   :strict - If true, rejects Hashes with members not in the schema.
  #           Applies to the top level and to nested Hashes.
  #   :full - If true, gathers all invalid values.  If false, stops checking at
  #           the first invalid value.  TODO: implement
  #   :verbose - If true, the error message for failed strictness will include
  #           the names of the unexpected keys.  Note that this can be a
  #           security risk if the key names are controlled by an attacker and
  #           the result is sent via HTTPS (see e.g. the CRIME attack).
  #   :raise_errors - If true, any errors will be raised.  If false, they will
  #           be returned as a String.  Default is true.  TODO: implement
  #   :parent_path - Used internally for tracking the current validation path
  #           in error messages (e.g. :key1[:key2][0]).
  #   :key - Used internally for tracking the current validation key in error
  #           messages (e.g. :key1 or 0).
  #   :errors - Used internally for aggregating error messages.  TODO: implement
  #
  # Examples:
  #   ClassyHash.validate({a: 1}, {a: Integer})
  #   ClassyHash.validate(1, Integer)
  def self.validate(value, constraint, strict: false, full: false, verbose: false,
                    raise_errors: true, parent_path: nil, key: NO_VALUE, errors: nil)
    if full
      error_entries = []

      begin
        validate(
          value,
          constraint,
          strict: strict,
          full: false,
          verbose: verbose,
          raise_errors: true,
          parent_path: parent_path,
          key: key,
          errors: errors
        )
      rescue SchemaViolationError => error
        error_entries.concat error.entries
        error.continue
      end

      if block_given?
        error_entries.each do |e| yield e end
      elsif !error_entries.empty?
        raise SchemaViolationError.new(error_entries)
      end

      return
    end

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
      unless value.is_a?(Hash)
        self.raise_error(parent_path, key, constraint, value)
        return # FIXME: for validate_full; replace with another mechanism
      end

      if strict
        extra_keys = value.keys - constraint.keys
        if extra_keys.any?
          if verbose
            msg = "valid: contains members #{extra_keys.map(&:inspect).join(', ')} not specified in schema"
          else
            msg = 'valid: contains members not specified in schema'
          end

          raise_error(parent_path, key, msg, NO_VALUE)
        end
      end

      parent_path = join_path(parent_path, key)

      constraint.each do |k, c|
        if value.include?(k)
          # TODO: Benchmark how much slower allocating a state object is than
          # passing lots of parameters?
          self.validate(
            value[k],
            c,
            strict: strict,
            full: full,
            verbose: verbose,
            raise_errors: raise_errors,
            parent_path: parent_path,
            key: k,
            errors: errors
          )
        elsif !(c.is_a?(Array) && c.include?(:optional))
          self.raise_error(parent_path, k, "present", NO_VALUE)
        end
      end

    when Array
      # Multiple choice or array validation
      if constraint.length == 1 && constraint.first.is_a?(Array)
        # Array validation
        unless value.is_a?(Array)
          self.raise_error(parent_path, key, constraint, value)
          return # FIXME: for validate_full
        end

        constraints = constraint.first
        value.each_with_index do |v, idx|
          self.check_multi(
            v,
            constraints,
            strict: strict,
            full: full,
            verbose: verbose,
            raise_errors: raise_errors,
            parent_path: join_path(parent_path, key),
            key: idx,
            errors: errors
          )
        end
      else
        # Multiple choice
        self.check_multi(
          value,
          constraint,
          strict: strict,
          full: full,
          verbose: verbose,
          raise_errors: raise_errors,
          parent_path: parent_path,
          key: key,
          errors: errors
        )
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
        unless value.is_a?(Integer)
          self.raise_error(parent_path, key, constraint, value)
        end
      elsif constraint.min.is_a?(Numeric)
        unless value.is_a?(Numeric)
          self.raise_error(parent_path, key, constraint, value)
        end
      elsif constraint.min.is_a?(String)
        unless value.is_a?(String)
          self.raise_error(parent_path, key, constraint, value)
        end
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
          self.validate(
            value,
            c,
            strict: strict,
            full: full,
            verbose: verbose,
            raise_errors: true,
            parent_path: parent_path,
            key: key,
            errors: errors
          )

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

  # Deprecated.  Retained for compatibility with v0.1.x.  Calls .validate with
  # :strict set to true.  If +verbose+ is true, the names of unexpected keys
  # will be included in the error message.
  def self.validate_strict(hash, schema, verbose=false, parent_path=nil)
    validate(hash, schema, parent_path: parent_path, verbose: verbose, strict: true)
  end

  # Raises an error unless the given +value+ matches one of the given multiple
  # choice +constraints+.  Other parameters are used for internal state.
  def self.check_multi(value, constraints, strict: nil, full: nil, verbose: nil, raise_errors: nil,
                       parent_path: nil, key: nil, errors: nil)
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
        self.validate(
          value,
          c,
          strict: strict,
          full: full,
          verbose: verbose,
          raise_errors: raise_errors,
          parent_path: parent_path,
          key: key,
          errors: errors
        )

        return
      rescue => e
        # Throw schema and array errors immediately
        # FIXME: is this appropriate for something like [:optional, {a: Integer}, {b: Integer}, [[{c: Integer}]]]
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

  def self.join_path(parent_path, key)
    if parent_path
      "#{parent_path}[#{key.inspect}]"
    elsif key == NO_VALUE
      nil
    else
      key.inspect
    end
  end

  # Raises an error indicating that the given +key+ under the given
  # +parent_path+ fails because the value "is not #{+message+}"
  #
  # If parent_path and key are both nil, then the error message will just be
  # the given +message+.
  #
  # (TODO clarify -MB)
  def self.raise_error(parent_path, key, constraint, value)
    message = constraint.is_a?(String) ? constraint : constraint_string(constraint, value)
    callcc do |cont|
      entry = { full_path: self.join_path(parent_path, key) || 'Top level', message: message }
      raise SchemaViolationError.new([entry], cont)
    end
  end
end

require 'classy_hash/generate'

if !Kernel.const_defined?(:CH)
  CH = ClassyHash
end
