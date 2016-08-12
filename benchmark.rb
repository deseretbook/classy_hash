#!/usr/bin/env ruby
# Benchmarks of different serialization and validation approaches, including
# Classy Hash.  Created May 2014 by Mike Bourgeous of DeseretBook.com.
# (C)2014 Deseret Book (see README.md and LICENSE for details)

require 'benchmark'
require 'msgpack'
require 'json'
require 'json-schema'
require 'schema_hash'
require 'hash_validator'

$: << File.join(File.dirname(__FILE__), 'lib')
require 'classy_hash'

good_hashes = [
  {
    k1: 'Value One',
    k2: 'Value Two',
    k3: -3,
    k4: 4.4,
    k5: true,
    k6: false,
    k7: {
      n1: 'Hi there',
      n2: 'This is a nested hash',
      n3: {
        d1: 5
      }
    }
  },
  {
    k1: 'Another Value One',
    k2: 'Another Value Two',
    k3: 3,
    k4: -4,
    k5: false,
    k6: true,
    k7: {
      n1: 'Hello again',
      n2: 'This is a second nested hash',
      n3: {
        d1: 31.5
      }
    }
  },
]

bad_hashes = [
  {
    :k1 => :v1,
    :k2 => 2,
  },
  {
    :k2 => 5,
  },
  {
    :k1 => 'V1',
    :k2 => 'V2',
    :k3 => 5.1,
    :k4 => nil,
    :k5 => 'true',
    :k6 => 'false'
  },
  {
    :k1 => '1',
    :k2 => '2',
    :k3 => 3,
    :k4 => 4,
    :k5 => false,
    :k6 => true,
    :k7 => 'x'
  },
  {
    :k1 => '1',
    :k2 => '2',
    :k3 => 3,
    :k4 => 4,
    :k5 => false,
    :k6 => true,
    :k7 => {
      :n1 => 'N1',
      :n2 => 'N2',
      :n3 => {
        :d1 => 'No'
      }
    }
  }
]

# ClassyHash schema
# https://github.com/deseretbook/classy_hash
classy_schema = {
  :k1 => String,
  :k2 => String,
  :k3 => Integer,
  :k4 => Numeric,
  :k5 => FalseClass,
  :k6 => TrueClass,
  :k7 => {
    :n1 => String,
    :n2 => String,
    :n3 => {
      :d1 => Numeric
    }
  }
}


# JSON Schema schema
# http://json-schema.org/example1.html
# https://github.com/hoxworth/json-schema
json_schema_schema = {
  '$schema' => 'http://json-schema.org/draft-04/schema#',
  'title' => 'Test Schema',
  'description' => 'Test Schema',
  'type' => 'object',
  'properties' => {
    :k1 => {
      'description' => 'Key one',
      'type' => 'string'
    },
    :k2 => {
      'description' => 'Key two',
      'type' => 'string',
    },
    :k3 => {
      'description' => 'Key three',
      'type' => 'integer'
    },
    :k4 => {
      'description' => 'Key four',
      'type' => 'number'
    },
    :k5 => {
      'description' => 'Key five',
      'type' => 'boolean'
    },
    :k6 => {
      'description' => 'The item type (a string with business-specific meaning)',
      'type' => 'boolean'
    },
    :k7 => {
      'description' => 'Whether the item can be shipped via media mail',
      'type' => 'object',
      'properties' => {
        :n1 => {
          'description' => 'Nested key one',
          'type' => 'string'
        },
        :n2 => {
          'description' => 'Nested key two',
          'type' => 'string'
        },
        :n3 => {
          'description' => 'Nested key three',
          'type' => 'object',
          'properties' => {
            :d1 => {
              'description' => 'Deeply nested key one',
              'type' => 'number'
            }
          }
        }
      }
    }
  },
  'additionalProperties' => false
}


# schema_hash schema
# https://github.com/djsun/schema_hash
schema_hash_schema = {
  :k1 => true,
  :k2 => true,
  :k3 => true,
  :k4 => true,
  :k5 => true,
  :k6 => true,
  :k7 => {
    :n1 => true,
    :n2 => true,
    :n3 => {
      :d1 => true
    }
  }
}


# Hash Validator schema
# https://github.com/JamesBrooks/hash_validator
hash_validator_schema = {
  :k1 => 'string',
  :k2 => 'string',
  :k3 => 'integer',
  :k4 => 'numeric',
  :k5 => 'boolean',
  :k6 => 'boolean',
  :k7 => {
    :n1 => 'string',
    :n2 => 'string',
    :n3 => {
      :d1 => 'numeric'
    }
  }
}


# Number of benchmark iterations (divided by the divisors listed below for each
# validator and serializer)
BENCHCOUNT=200000

# A list of serialization/deserialization lambdas for testing performance and
# data mangling.
SERIALIZERS = {
  no_op: {
    divisor: 1,
    serializer: lambda{|hash| hash},
  },
  msgpack: {
    divisor: 2,
    serializer: lambda{|hash| MessagePack.unpack(hash.to_msgpack, symbolize_keys: true)},
  },
  json: {
    divisor: 4,
    serializer: lambda{|hash| JSON.parse(hash.to_json, symbolize_names: true)},
  },
  yaml: {
    divisor: 16,
    serializer: lambda{|hash| YAML.load(hash.to_yaml)},
  }
}

# A list of schema validators to test.  Lambdas should validate against their
# corresponding schema and raise an error if validation fails.
VALIDATORS = {
  no_op: {
    divisor: 1,
    validator: lambda{|hash|
      nil
    }
  },

  classy_hash: {
    divisor: 1,
    validator: lambda{|hash|
      ClassyHash.validate(hash, classy_schema)
    }
  },
  classy_hash_strict: {
    divisor: 1,
    validator: lambda{|hash|
      ClassyHash.validate_strict(hash, classy_schema)
    }
  },
  classy_hash_full: {
    divisor: 1,
    validator: lambda{|hash|
      ClassyHash.validate(hash, classy_schema, full: true)
    }
  },
  classy_hash_full_strict: {
    divisor: 1,
    validator: lambda{|hash|
      ClassyHash.validate(hash, classy_schema, strict: true, full: true)
    }
  },

  hash_validator: {
    divisor: 2,
    validator: lambda{|hash|
      validator = HashValidator.validate(hash, hash_validator_schema)
      raise validator.errors.to_s unless validator.valid?
    }
  },

  schema_hash: {
    divisor: 4,
    validator: lambda{|hash|
      hash.schema = schema_hash_schema
      raise 'hash invalid' unless hash.valid?
    }
  },

  json_schema: {
    divisor: 25,
    validator: lambda{|hash|
      JSON::Validator.validate!(json_schema_schema, hash)
    }
  },
  json_schema_strict: {
    divisor: 25,
    validator: lambda{|hash|
      JSON::Validator.validate!(json_schema_schema, hash, strict: true)
    }
  },
  json_schema_full: {
    divisor: 25,
    validator: lambda{|hash|
      a = JSON::Validator.fully_validate(json_schema_schema, hash, strict: true)
      raise a.join("\n\t\t\t") unless a.empty?
    }
  }
}

# Yields once and returns a hash with GC and elapsed time stats
def gc_bench
  asym = :total_allocated_objects
  csym = :count

  GC.start

  start = Time.now
  before = GC.stat
  ba = before[asym]
  bc = before[:count]

  yield

  after = GC.stat
  aa = after[asym]
  ac = after[:count]
  elapsed = Time.now - start

  { alloc: aa - ba, gc: ac - bc, elapsed: elapsed }
end

# Runs the given block BENCHCOUNT times for each serializer/schema pair.
# Yields serializer name, serializer, validator name, validator
def do_test(hashes, expect_fail)
  results = []

  SERIALIZERS.each do |ser_name, ser_info|
    puts "Serializing with #{ser_name}"

    VALIDATORS.each do |val_name, val_info|
      puts "\tValidating with #{val_name}"

      count = BENCHCOUNT / (val_info[:divisor] * ser_info[:divisor])

      begin
        puts "\t\tTesting #{count} iterations of #{ser_name}+#{val_name}"

        serializer = ser_info[:serializer]
        validator = val_info[:validator]

        response = nil
        result = gc_bench do
          hashes.each do |h|
            count.times do
              response = validator.call(serializer.call(h)) rescue $!
            end

            if expect_fail != response.is_a?(StandardError)
              raise "Validation should #{expect_fail ? '' : 'not '}have failed for #{h}"
            end
          end
        end

        total = count * hashes.count
        speed = total.to_f / result[:elapsed]

        puts "\t\tResult: #{total} in #{result[:elapsed]}s (#{speed}/s #{result[:alloc]} allocations #{result[:gc]} GC runs)"
        puts "\t\tReturned: #{response}" if response

        results << [ser_name, val_name, total, speed, result[:alloc].to_f / total, total.to_f / result[:gc]]
      rescue => e
        puts "\t\tException raised: #{e}\n\t\t#{e.backtrace.first(15).join("\n\t\t")}"
      end
    end
  end

  results
end

def show_results(results)
  puts " #{'Serializer'.center(15)} | #{'Validator'.center(24)} | #{'Ops'.center(8)} | #{'Ops/sec'.center(10)} | #{'Alloc/op'.center(10)} | #{'Ops/GC'.center(10)}"
  puts "-#{'-' * 15}-+-#{'-' * 24}-+-#{'-' * 8}-+-#{'-' * 10}-+-#{'-' * 10}-+-#{'-' * 10}"

  results.sort_by{|r| -r[2]}.each do |serializer, validator, total, speed, alloc, gc_count|
    puts " #{serializer.to_s.ljust(15)} | #{validator.to_s.ljust(24)} | #{total.to_s.rjust(8)} | " \
      "#{('%.1f' % speed).rjust(10)} | #{('%.1f' % alloc).rjust(10)} | #{('%.1f' % gc_count).rjust(10)}"
  end

  puts
end

def run_tests(valid, invalid)
  puts " Testing valid hashes ".center(50, '-')
  results = do_test(valid, false)
  show_results(results)

  puts " Testing invalid hashes ".center(50, '-')
  results = do_test(invalid, true)
  show_results(results)
end

run_tests good_hashes, bad_hashes
