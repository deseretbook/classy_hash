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

good_hash = JSON.parse(<<-JSON, symbolize_names: true)
{
  "k1": "Value One",
  "k2": "Value Two",
  "k3": -3,
  "k4": 4.4,
  "k5": true,
  "k6": false,
  "k7": {
    "n1": "Hi there",
    "n2": "This is a nested hash",
    "n3": {
      "d1": 5
    }
  }
}
JSON

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
      ClassyHash.validate_full(hash, classy_schema)
    }
  },
  classy_hash_full_strict: {
    divisor: 1,
    validator: lambda{|hash|
      ClassyHash.validate_full(hash, classy_schema, true)
    }
  },

  hash_validator: {
    divisor: 1,
    validator: lambda{|hash|
      validator = HashValidator.validate(hash, hash_validator_schema)
      raise validator.errors.to_s unless validator.valid?
    }
  },

  schema_hash: {
    divisor: 1,
    validator: lambda{|hash|
      hash.schema = schema_hash_schema
      raise 'hash invalid' unless hash.valid?
    }
  },

  json_schema: {
    divisor: 20,
    validator: lambda{|hash|
      JSON::Validator.validate!(json_schema_schema, hash)
    }
  },
  json_schema_strict: {
    divisor: 20,
    validator: lambda{|hash|
      JSON::Validator.validate!(json_schema_schema, hash, strict: true)
    }
  },
  json_schema_full: {
    divisor: 20,
    validator: lambda{|hash|
      a = JSON::Validator.fully_validate(json_schema_schema, hash, strict: true)
      raise a.join("\n\t\t\t") unless a.empty?
    }
  }
}

# Runs the given block BENCHCOUNT times for each serializer/schema pair.
# Yields serializer name, serializer, validator name, validator
def do_test &block
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
        result = Benchmark.realtime do
          count.times do
            response = yield ser_name, serializer, val_name, validator
          end
        end

        speed = (count / result).round

        puts "\t\tResult: #{count} in #{result}s (#{speed}/s)"
        puts "\t\tReturned: #{response}" if response

        results << [ser_name, val_name, speed]
      rescue => e
        puts "\t\tException raised: #{e}\n\t\t#{e.backtrace.first(15).join("\n\t\t")}"
      end
    end
  end

  results
end

def show_results(results)
  puts " #{'Serializer'.center(20)} | #{'Validator'.center(20)} | #{'Ops/sec'.center(10)}"
  puts "-#{'-' * 20}-+-#{'-' * 20}-+-#{'-' * 10}"

  results.sort_by{|r| -r.last}.each do |serializer, validator, speed|
    puts " #{serializer.to_s.ljust(20)} | #{validator.to_s.ljust(20)} | #{speed}"
  end

  puts
end

def run_tests(valid, invalid)
  puts " Testing valid hashes ".center(50, '-')
  results = do_test do |ser_name, serializer, val_name, validator|
    validator.call(serializer.call(valid))
  end

  show_results(results)

  puts " Testing invalid hashes ".center(50, '-')
  results = do_test do |ser_name, serializer, val_name, validator|
    error = nil
    invalid.each do |h|
      begin
        validator.call(serializer.call(h))
      rescue => e
        error = e
      end
      raise "Validation should have failed for #{h}" if error.nil?
    end
    error
  end

  show_results(results)
end

run_tests good_hash, bad_hashes
