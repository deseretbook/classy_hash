#!/usr/bin/env ruby
# Quick and dirty test for Classy Hash, to be replaced by rspec later
# Created May 28, 2014 by Mike Bourgeous, DeseretBook.com

require './lib/classy-hash'
require 'benchmark'

BENCHCOUNT=1000000

good_hash = {
  :k1 => 'Value One',
  :k2 => 'Value Two',
  :k3 => -3,
  :k4 => 4.4,
  :k5 => true,
  :k6 => false,
  :k7 => {
    :n1 => 'Hi there',
    :n2 => 'This is a nested hash',
    :n3 => {
      :d1 => 5
    }
  }
}

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

schema = {
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

bad_schema = {
  :k1 => :oops
}

# Test good hash
result = Benchmark.measure do
  BENCHCOUNT.times do
    ClassyHash.validate(good_hash, schema)
  end
end
puts "Good hash test: #{result}"

# Test bad hashes
bad_hashes.each do |h|
  begin
    ClassyHash.validate(h, schema)
    raise "ERROR: No error raised for bad hash #{h.inspect}"
  rescue => e
    puts "Bad hash test: #{e} on #{h.inspect}"
  end
end

# Test bad schema
begin
  ClassyHash.validate(good_hash, bad_schema)
  raise "ERROR: No error raised for bad schema #{bad_schema.inspect}"
rescue => e
  puts "Bad schema test: #{e} on #{bad_schema}"
end
