#!/usr/bin/env ruby
# Quick and dirty test for Classy Hash, to be replaced by rspec later
# Created May 28, 2014 by Mike Bourgeous, DeseretBook.com

require './lib/classy_hash'
require 'benchmark'

BENCHCOUNT=50000

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
  },
  :k8 => [1, 2, 3, 4, 5],
  :k9 => {
    :opt1 => "opt1",
    :opt2 => 35,
    :opt3 => [ {:a => -5}, {:a => 6}, 'str3' ],
    :opt4 => [
      [1, 2, 3, 4, 5],
      (6..10).to_a,
      [],
      [-5, -10, -15],
    ]
  },
  :k10 => 7
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
    :k3 => -600,
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
        :d1 => 333
      }
    },
    :k8 => [1],
    :k9 => {
      :opt1 => "opt1",
      :opt2 => 35,
      :opt3 => [
        {:a => 5},
        {:a => nil},
        {:a => 3.35},
        7
      ]
    }
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
        :d1 => 333
      }
    },
    :k8 => [1],
    :k9 => {
      :opt1 => "opt1",
      :opt2 => 35,
      :opt3 => [
        {:a => 5},
        {:a => nil},
        '7'
      ],
      :opt4 => []
    },
    :k10 => 1.7
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
        :d1 => 333
      }
    },
    :k8 => [1],
    :k9 => {
      :opt1 => "opt1",
      :opt2 => 35,
      :opt3 => [
        {:a => 5},
        {:a => nil},
        '7'
      ],
      :opt4 => []
    },
    :k10 => 1,
    :k11 => nil
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
        :d1 => 333
      }
    },
    :k8 => [1, nil, 'str'],
    :k9 => {
      :opt1 => "opt1",
      :opt2 => 35,
      :opt3 => nil
    }
  },
  {
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
    },
    :k8 => [1, 2, 3, 4, 5],
    :k9 => {
      :opt1 => "opt1",
      :opt2 => 35,
      :opt3 => [ {:a => -5}, {:a => 6}, 'str3' ],
      :opt4 => [
        [1, 2, 3, 4, 5],
        (6..10).to_a,
        [],
        [-5, -10, -15],
      ]
    },
    :k10 => 7,
    :k11 => 'Valid string',
    :extra_member => 'Not welcome'
  }
]

nested_schema = {
  :opt1 => [NilClass, String],
  :opt2 => [Numeric, Symbol],
  :opt3 => [[ { :a => [NilClass, Integer] }, String ]],
  :opt4 => [[ [[ Integer ]] ]], # Array of arrays of integers
}

schema = {
  :k1 => String,
  :k2 => String,
  :k3 => -10..10000,
  :k4 => Numeric,
  :k5 => FalseClass,
  :k6 => TrueClass,
  :k7 => {
    :n1 => String,
    :n2 => String,
    :n3 => {
      :d1 => Numeric
    }
  },
  :k8 => [[Integer]],
  :k9 => [NilClass, nested_schema],
  :k10 => lambda {|value| (value.is_a?(Integer) && value.odd?) ? true : 'an odd integer'},
  :k11 => [:optional, String]
}

bad_schema = {
  :k1 => :oops
}

# Test good hash
result = Benchmark.realtime do
  BENCHCOUNT.times do
    ClassyHash.validate(good_hash, schema)
  end
end
puts "Good hash test: #{result}s (#{BENCHCOUNT / result} per second)"

# Test bad hashes
bad_hashes.each do |h|
  begin
    ClassyHash.validate_strict(h, schema)
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
