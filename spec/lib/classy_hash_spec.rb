# Classy Hash: Keep Your Hashes Classy (RSpec test suite)
# Created May 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

describe ClassyHash do
  # A list of test data and expected values for automated integration test creation
  classy_data = [
    {
      # Name of the data category
      name: 'simple',

      # Schema for this data category
      schema: {
        k1: String,
        k2: Numeric,
        k3: Fixnum,
        k4: TrueClass,
        k5: /\Ah.*d\z/i,
        k6: /H.*d/,
      },

      # Good hashes for this schema
      good: [
        { k1: 'V1', k2: 2, k3: 3, k4: true, k5: 'Hello, World', k6: 'I say, Hello, World!' },
        { k1: 'Val1', k2: 2.2, k3: -3, k4: false, k5: 'HOLD', k6: 'Hold' },
        { k1: 'V1', k2: Rational(-2, 7), k3: 0, k4: true, k5: 'hi world', k6: 'Hola, World' },
      ],

      # Bad hashes for this schema, with expected error message (string or regex)
      bad: [
        [ /^:k1.*present/, { } ],
        [ /^:k1/, { k1: :optional, k2: 2, k3: 3, k4: true, k5: 'hd', k6: 'Hd' } ],
        [ /^:k2/, { k1: '', k2: nil, k3: 3, k4: true, k5: 'hd', k6: 'Hd' } ],
        [ /^:k3/, { k1: '', k2: 0, k3: 3.3, k4: true, k5: 'hd', k6: 'Hd' } ],
        [ /^:k3/, { k1: '', k2: 0, k3: 1<<200, k4: true, k5: 'hd', k6: 'Hd' } ],
        [ /^:k4/, { k1: '', k2: 0, k3: 3, k4: 'invalid', k5: 'hd', k6: 'Hd' } ],
        [ /^:k5.*String.*match/, { k1: '', k2: 0, k3: 3, k4: true, k5: nil, k6: 'Hd' } ],
        [ /^:k5.*String.*match/, { k1: '', k2: 0, k3: 3, k4: true, k5: 'Not hd', k6: 'Hd' } ],
        [ /^:k6.*String.*match/, { k1: '', k2: 0, k3: 3, k4: true, k5: 'HD', k6: 'hD' } ],
      ],
    },
    {
      name: 'complex',

      schema: {
        k1: String,
        k2: String,
        k3: -10..10000,
        k4: Numeric,
        k5: FalseClass,
        k6: TrueClass,

        # :k7 must be a hash with this schema
        k7: {
          n1: String,
          n2: String,
          n3: {
            d1: Numeric
          }
        },

        # :k8 must be an array of integers or a String matching /ints/
        k8: [ [[Integer]], /ints/ ],

        # :k9 can be either nil or a hash with the specified schema
        k9: [
          NilClass,
          {
            opt1: [NilClass, String],
            opt2: [:optional, Numeric, Symbol, [[Integer]]],
            opt3: [[ { a: [NilClass, Integer] }, String ]], # Array of hashes or strings
            opt4: [[ [[ Integer ]] ]], # Array of arrays of integers
          }
        ],

        # :k10 must be an odd integer
        k10: lambda {|value| (value.is_a?(Integer) && value.odd?) ? true : 'an odd integer'},

        # :k11 can be missing, a string, or an array of integers, nils, and booleans
        k11: [:optional, String, [[Integer, NilClass, FalseClass]]]
      },

      good: [
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
          },
          k8: [1, 2, 3, 4, 5],
          k9: {
            opt1: "opt1",
            opt2: 35,
            opt3: [
              {a: -5},
              {a: 6},
              'str3'
            ],
            opt4: [
              [1, 2, 3, 4, 5],
              (6..10).to_a,
              [],
              [-5, -10, -15],
            ]
          },
          k10: 7
          # :k11 is optional
        },
        {
          k1: 'V1',
          k2: 'V2',
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
          },
          k8: [1, 2, 3, 4, 5],
          k9: {
            opt1: nil,
            opt2: :sym1,
            opt3: [
              {a: -5},
              {a: nil},
              'str3'
            ],
            opt4: []
          },
          k10: -3,
          k11: 'K11 can be a string'
        },
        {
          k1: 'V1',
          k2: 'V2',
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
          },
          k8: [1, 2, 3, 4, 5],
          k9: {
            opt1: "opt1",
            opt3: [
              {a: -5},
              {a: nil},
              'str3'
            ],
            opt4: [
              [1, 2, 3, 4, 5],
              (6..10).to_a,
              [],
              [-5, -10, -15],
            ]
          },
          k10: -3,
          k11: 'K11 is a string here'
        },
        {
          k1: 'V1',
          k2: 'V2',
          k3: -3,
          k4: 4.4,
          k5: true,
          k6: false,
          k7: {
            n1: 'Hi there',
            n2: 'This is a nested hash',
            n3: {
              d1: 0.35
            }
          },
          k8: [1, 2, 3, 4, 5],
          k9: {
            opt1: "opt1",
            opt2: [1, 2, 3],
            opt3: [
              {a: -5},
              {a: nil},
              'str3'
            ],
            opt4: [
              [1, 2, 3, 4, 5],
              (6..10).to_a,
              [],
              [-5, -10, -15],
            ]
          },
          k10: -3,
          k11: [
            3,
            4,
            5,
            nil,
            true,
            false,
            1<<150
          ]
        },
        {
          k1: 'V1',
          k2: 'V2',
          k3: -3,
          k4: 4.4,
          k5: true,
          k6: false,
          k7: {
            n1: 'Hi there',
            n2: 'This is a nested hash',
            n3: {
              d1: 0.35
            }
          },
          k8: 'some ints would normally be here',
          k9: {
            opt1: "opt1",
            opt2: [1, 2, 3],
            opt3: [
              {a: -5},
              {a: nil},
              'str3'
            ],
            opt4: [
              [1, 2, 3, 4, 5],
              (6..10).to_a,
              [],
              [-5, -10, -15],
            ]
          },
          k10: -3,
          k11: [
            3,
            4,
            5,
            nil,
            true,
            false,
            1<<150
          ]
        },
      ],

      bad: [
        [ /^:k1/, { k1: :v1 } ],
        [ /^:k1/, { k2: 5 } ],
        [ /^:k3.*range/, { k1: 'V1', k2: 'V2', k3: -600, } ],
        [ /^:k5/, { k1: 'V1', k2: 'V2', k3: 5, k4: 1.0, k5: 'true' } ],
        [ /^:k7.*hash/i, { k1: '1', k2: '2', k3: 3, k4: 4, k5: false, k6: true, k7: 'x' } ],
        [
          /^:k7\[:n3\]\[:d1\]/,
          {
            k1: '1',
            k2: '2',
            k3: 3,
            k4: 4,
            k5: false,
            k6: true,
            k7: {
              n1: 'N1',
              n2: 'N2',
              n3: {
                d1: 'No'
              }
            }
          }
        ],
        [
          /^:k9\[:opt2\].*one of/,
          {
            k1: '1',
            k2: '2',
            k3: 3,
            k4: 4,
            k5: false,
            k6: true,
            k7: {
              n1: 'N1',
              n2: 'N2',
              n3: {
                d1: 333
              }
            },
            k8: [1],
            k9: {
              opt1: "opt1",
              opt2: nil,
              opt3: [
                {a: 5},
                {a: nil},
                {a: 3.35},
                7
              ]
            }
          }
        ],
        [
          /^:k9\[:opt3\]\[2\]\[:a\].*one of/,
          {
            k1: '1',
            k2: '2',
            k3: 3,
            k4: 4,
            k5: false,
            k6: true,
            k7: {
              n1: 'N1',
              n2: 'N2',
              n3: {
                d1: 333
              }
            },
            k8: [1],
            k9: {
              opt1: "opt1",
              opt2: 35,
              opt3: [
                {a: 5},
                {a: nil},
                {a: 3.35},
                7
              ]
            }
          }
        ],
        [
          /^:k10.*odd/,
          {
            k1: '1',
            k2: '2',
            k3: 3,
            k4: 4,
            k5: false,
            k6: true,
            k7: {
              n1: 'N1',
              n2: 'N2',
              n3: {
                d1: 333
              }
            },
            k8: [1],
            k9: {
              opt1: "opt1",
              opt2: 35,
              opt3: [
                {a: 5},
                {a: nil},
                '7'
              ],
              opt4: []
            },
            k10: 1.7
          }
        ],
        [
          /^:k9\[:opt4\]\[1\]\[3\]/,
          {
            k1: 'V1',
            k2: 'V2',
            k3: -3,
            k4: 4.4,
            k5: true,
            k6: false,
            k7: {
              n1: 'Hi there',
              n2: 'This is a nested hash',
              n3: {
                d1: 0.35
              }
            },
            k8: [1, 2, 3, 4, 5],
            k9: {
              opt1: "opt1",
              opt3: [
                {a: -5},
                {a: nil},
                'str3'
              ],
              opt4: [
                [1],
                [3, 5, 9, 10.0],
                [],
                [-10, -15],
              ]
            },
            k10: -3,
            k11: [
              3,
              4,
              5,
              nil,
              true,
              false,
              1
            ]
          }
        ],
        [
          /^:k11\[6\]/,
          {
            k1: 'V1',
            k2: 'V2',
            k3: -3,
            k4: 4.4,
            k5: true,
            k6: false,
            k7: {
              n1: 'Hi there',
              n2: 'This is a nested hash',
              n3: {
                d1: 0.35
              }
            },
            k8: [1, 2, 3, 4, 5],
            k9: {
              opt1: "opt1",
              opt3: [
                {a: -5},
                {a: nil},
                'str3'
              ],
              opt4: [
                [1, 2, 3, 4, 5],
                (6..10).to_a,
                [],
                [-5, -10, -15],
              ]
            },
            k10: -3,
            k11: [
              3,
              4,
              5,
              nil,
              true,
              false,
              1.5
            ]
          }
        ],
        [
          /^:k8.*\/ints\//,
          {
            k1: 'V1',
            k2: 'V2',
            k3: -3,
            k4: 4.4,
            k5: true,
            k6: false,
            k7: {
              n1: 'Hi there',
              n2: 'This is a nested hash',
              n3: {
                d1: 0.35
              }
            },
            k8: 'There are no integers here',
            k9: {
              opt1: "opt1",
              opt3: [
                {a: -5},
                {a: nil},
                'str3'
              ],
              opt4: [
                [1, 2, 3, 4, 5],
                (6..10).to_a,
                [],
                [-5, -10, -15],
              ]
            },
            k10: -3,
            k11: [
              3,
              4,
              5,
              nil,
              true,
              false,
              1<<150
            ]
          }
        ],
      ]
    }
  ]

  # Granular tests
  describe '.validate' do
    it 'accepts basic valid values' do
      expect{ ClassyHash.validate({a: 'hi'}, {a: String}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 3}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: :sym1}, {a: Symbol}) }.not_to raise_error
      expect{ ClassyHash.validate({a: {q: :q}}, {a: Hash}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [:q, :q]}, {a: Array}) }.not_to raise_error
    end

    it 'rejects basic invalid values' do
      expect{ ClassyHash.validate({a: nil}, {a: String}) }.to raise_error(/not.*String/)
      expect{ ClassyHash.validate({a: 3}, {a: String}) }.to raise_error(/not.*String/)
      expect{ ClassyHash.validate({a: false}, {a: Numeric}) }.to raise_error(/not.*Numeric/)
      expect{ ClassyHash.validate({a: {q: :q}}, {a: Array}) }.to raise_error(/not.*Array/)
      expect{ ClassyHash.validate({a: [:q, :q]}, {a: Hash}) }.to raise_error(/not.*Hash/)
    end

    it 'accepts fixnum, bignum, float, and rational for numeric' do
      expect{ ClassyHash.validate({a: 0}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1<<200}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1.0123}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: Rational(1, 3)}, {a: Numeric}) }.not_to raise_error
    end

    it 'rejects float, bignum, and rational for fixnum' do
      # TODO: Ruby 2.4 merges Bignum and Fixnum into Integer
      expect{ ClassyHash.validate({a: 1.0}, {a: Fixnum}) }.to raise_error(/not.*(Integer|Fixnum)/)
      expect{ ClassyHash.validate({a: 1<<200}, {a: Fixnum}) }.to raise_error(/not.*(Integer|Fixnum)/)
      expect{ ClassyHash.validate({a: Rational(1, 3)}, {a: Fixnum}) }.to raise_error(/not.*(Integer|Fixnum)/)
    end

    it 'accepts valid multiple choice values' do
      expect{ ClassyHash.validate({a: nil}, {a: [NilClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'hello'}, {a: [String]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'str'}, {a: [String, Rational, NilClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: Rational(-3, 5)}, {a: [String, Rational, NilClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: nil}, {a: [String, Rational, NilClass]}) }.not_to raise_error
    end

    it 'rejects invalid multiple choice values' do
      expect{ ClassyHash.validate({a: nil}, {a: [String]}) }.to raise_error(/one of.*String/)
      expect{ ClassyHash.validate({a: false}, {a: [NilClass]}) }.to raise_error(/one of.*Nil/)
      expect{ ClassyHash.validate({a: 1}, {a: [String]}) }.to raise_error(/one of.*String/)
      expect{ ClassyHash.validate({a: 1}, {a: [String, Rational, NilClass]}) }.to raise_error(/one of.*String.*Rational.*Nil/)
    end

    it 'accepts both true and false for just TrueClass or just FalseClass' do
      expect{ ClassyHash.validate({a: true}, {a: TrueClass}) }.not_to raise_error
      expect{ ClassyHash.validate({a: false}, {a: TrueClass}) }.not_to raise_error
      expect{ ClassyHash.validate({a: true}, {a: FalseClass}) }.not_to raise_error
      expect{ ClassyHash.validate({a: false}, {a: FalseClass}) }.not_to raise_error

      expect{ ClassyHash.validate({a: true}, {a: [FalseClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: false}, {a: [TrueClass]}) }.not_to raise_error
    end

    it 'rejects invalid values for TrueClass and FalseClass' do
      expect{ ClassyHash.validate({a: 1}, {a: TrueClass}) }.to raise_error(/true or false/)
      expect{ ClassyHash.validate({a: 0}, {a: FalseClass}) }.to raise_error(/true or false/)
      expect{ ClassyHash.validate({a: 1}, {a: [TrueClass]}) }.to raise_error(/one of.*true or false/)
      expect{ ClassyHash.validate({a: 0}, {a: [FalseClass]}) }.to raise_error(/one of.*true or false/)
    end

    it 'requires both TrueClass and FalseClass for true or false in multiple choices' do
      expect{ ClassyHash.validate({a: true}, {a: [TrueClass, FalseClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: false}, {a: [TrueClass, FalseClass]}) }.not_to raise_error
    end

    it 'accepts valid single-choice arrays' do
      expect{ ClassyHash.validate({a: []}, {a: [[String]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: ['hi']}, {a: [[String]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1]}, {a: [[Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3, 4, 5]}, {a: [[Integer]]}) }.not_to raise_error
    end

    it 'rejects invalid single-choice arrays' do
      expect{ ClassyHash.validate({a: [nil]}, {a: [[String]]}) }.to raise_error(/\[0\].*String/)
      expect{ ClassyHash.validate({a: ['hi', 'hello', 'heya', :optional]}, {a: [[String]]}) }.to raise_error(/\[3\].*String/)
      expect{ ClassyHash.validate({a: [1]}, {a: [[String]]}) }.to raise_error(/\[0\].*String/)
      expect{ ClassyHash.validate({a: [1, 2, 3, '']}, {a: [[Integer]]}) }.to raise_error(/\[3\].*Integer/)
    end

    it 'accepts valid multiple-choice arrays' do
      expect{ ClassyHash.validate({a: []}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: ['str']}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [nil]}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3]}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, nil, 'str', 4]}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
    end

    it 'rejects invalid multiple-choice arrays' do
      schema = { a: [[String, TrueClass, Float]] }
      expect{ ClassyHash.validate({a: [nil]}, schema) }.to raise_error(/\[0\].*String.*true or false.*Float/)
      expect{ ClassyHash.validate({a: ['hi', 'hello', 'heya', :optional]}, schema) }.to raise_error(/\[3\].*String.*true or false.*Float/)
      expect{ ClassyHash.validate({a: [1]}, schema) }.to raise_error(/\[0\].*String.*true or false.*Float/)
      expect{ ClassyHash.validate({a: [1, 2, 3, '']}, {a: [[Integer, Float]]}) }.to raise_error(/\[3\].*Integer.*Float/)
    end

    it 'accepts valid arrays with schemas' do
      expect { ClassyHash.validate({a: [{b: 1}, {b: 2.1}, 5]}, {a: [[{b: Numeric}, Integer]]}) }.not_to raise_error
    end

    it 'rejects invalid arrays with schemas' do
      expect { ClassyHash.validate({a: [{c: 1}, {b: 2.1}, 5]}, {a: [[{b: Numeric}, Integer]]}) }.to raise_error(/present/)
      expect { ClassyHash.validate({a: [{b: 1}, {b: 2.1}, 5.0]}, {a: [[{b: Numeric}, Integer]]}) }.to raise_error(/\[2\]/)
    end

    it 'handles more than one key' do
      expect{ ClassyHash.validate({a: true, b: 'str'}, {a: TrueClass, b: String}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'str', b: true}, {a: TrueClass, b: String}) }.to raise_error(/:a.*true or false/)
    end

    it 'rejects hashes with missing keys' do
      expect{ ClassyHash.validate({}, {a: NilClass}) }.to raise_error(/:a.*present/)
      expect{ ClassyHash.validate({}, {a: Integer}) }.to raise_error(/:a.*present/)
      expect{ ClassyHash.validate({a: 1}, {a: Integer, b: NilClass}) }.to raise_error(/:b.*present/)
    end

    it 'accepts valid or missing optional keys' do
      expect{ ClassyHash.validate({}, {a: [:optional, Integer]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1}, {a: [:optional, Integer]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1<<200}, {a: [:optional, Integer]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'str'}, {a: [:optional, Integer, String]}) }.not_to raise_error
    end

    it 'accepts valid or missing optional arrays' do
      expect{ ClassyHash.validate({}, {a: [:optional, [[Integer]] ]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: []}, {a: [:optional, [[Integer]] ]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3]}, {a: [:optional, [[Integer]] ]}) }.not_to raise_error
    end

    it 'rejects invalid optional keys' do
      expect{ ClassyHash.validate({a: nil}, {a: [:optional, Integer]}) }.to raise_error(/:a.*Integer/)
      expect{ ClassyHash.validate({a: 'str'}, {a: [:optional, Integer]}) }.to raise_error(/:a.*Integer/)
      expect{ ClassyHash.validate({a: :sym1}, {a: [:optional, Integer, String]}) }.to raise_error(/:a.*one of.*Integer.*String/)
    end

    it 'rejects invalid optional arrays' do
      expect{ ClassyHash.validate({a: [5.5]}, {a: [:optional, [[Integer]] ]}) }.to raise_error(/\[0\].*Integer/)
      expect{ ClassyHash.validate({a: [1, 2, 3, 'str']}, {a: [:optional, [[Integer]] ]}) }.to raise_error(/\[3\]/)
    end

    it 'accepts missing optional member with proc that would always fail' do
      # We can ensure a member is *never* present with this construct
      expect{ ClassyHash.validate({}, {a: [:optional, lambda {|v| false}]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: nil}, {a: [:optional, lambda {|v| false}]}) }.to raise_error(/accepted by/)
    end

    it 'accepts or rejects hashes using a proc' do
      expect{ ClassyHash.validate({a: 1}, {a: lambda {|v| v == 1}}) }.not_to raise_error
      expect{ ClassyHash.validate({a: -1}, {a: lambda {|v| v == 1}}) }.to raise_error(/accepted by Proc/)
    end

    it 'uses error messages returned by a proc' do
      expect{ ClassyHash.validate({a: 1}, {a: lambda {|v| 'no way'}}) }.to raise_error(/no way/)
    end

    it 'accepts valid values using a range' do
      expect{ ClassyHash.validate({a: 1}, {a: 1..2}) }.not_to raise_error
      expect{ ClassyHash.validate({a: Rational(3, 2)}, {a: 1.0..2.0}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'carrot'}, {a: 'cabbage'..'cauliflower'}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, 1]}, {a: [0]..[2]}) }.not_to raise_error
    end

    it 'rejects out-of-range values using a range' do
      expect{ ClassyHash.validate({a: 0}, {a: 1..2}) }.to raise_error(/in range/)
      expect{ ClassyHash.validate({a: Rational(1, 2)}, {a: 1.0..2.0}) }.to raise_error(/in range/)
      expect{ ClassyHash.validate({a: 'spinach'}, {a: 'cabbage'..'cauliflower'}) }.to raise_error(/in range/)
      expect{ ClassyHash.validate({a: [2, 1]}, {a: [0]..[2]}) }.to raise_error(/in range/)
    end

    it 'rejects invalid types using a range' do
      expect{ ClassyHash.validate({a: 1.0}, {a: 1..2}) }.to raise_error(/Integer/)
      expect{ ClassyHash.validate({a: 1}, {a: 'a'..'z'}) }.to raise_error(/String/)
    end

    it 'rejects non-hashes' do
      expect{ ClassyHash.validate(false, {}) }.to raise_error(/hash/i)
      expect{ ClassyHash.validate({}, false) }.to raise_error(/hash/i)
    end

    it 'rejects invalid schema elements' do
      expect{ ClassyHash.validate({a: 1}, {a: :invalid}) }.to raise_error(/valid.*constraint/)
    end

    it 'rejects empty multiple choice constraints' do
      expect{ ClassyHash.validate({a: nil}, {a: []}) }.to raise_error(/choice.*empty/)
      expect{ ClassyHash.validate({a: [1]}, {a: [[]]}) }.to raise_error(/choice.*empty/)
    end

    it 'accepts or rejects Strings using a partial-string regex' do
      schema = { a: /(in)?[1-9]{1,3}/ }
      expect{ ClassyHash.validate({a: 3}, schema) }.to raise_error(/String.*match/)
      expect{ ClassyHash.validate({a: 3.to_s}, schema) }.not_to raise_error
      expect{ ClassyHash.validate({a: nil}, schema) }.to raise_error(/String.*match/)
      expect{ ClassyHash.validate({a: 'in0'}, schema) }.to raise_error(/String.*match/)
      expect{ ClassyHash.validate({a: 'in1'}, schema) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'the middle can be in923 ok'}, schema) }.not_to raise_error
    end

    it 'accepts or rejects Strings using a whole-string regex' do
      schema = { a: /\Athe.*string\z/i }
      expect{ ClassyHash.validate({a: /the string/}, schema) }.to raise_error(/String.*match/)
      expect{ ClassyHash.validate({a: 'not the string'}, schema) }.to raise_error(/String.*match/)
      expect{ ClassyHash.validate({a: 'The WHOLE String'}, schema) }.not_to raise_error
    end

    it 'accepts any value for :optional (undocumented)' do
      expect{ ClassyHash.validate({a: nil}, {a: :optional}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1}, {a: :optional}) }.not_to raise_error
      expect{ ClassyHash.validate({a: ['a', 'b']}, {a: :optional}) }.not_to raise_error
      expect{ ClassyHash.validate({a: {}}, {a: :optional}) }.not_to raise_error
    end

    context 'schema is empty' do
      it 'accepts all hashes' do
        expect{ ClassyHash.validate({}, {}) }.not_to raise_error
        expect{ ClassyHash.validate({a: 1}, {}) }.not_to raise_error
        expect{ ClassyHash.validate({[1] => [2]}, {}) }.not_to raise_error
        expect{ ClassyHash.validate({ {} => {} }, {}) }.not_to raise_error
      end
    end
  end

  describe '.validate_strict' do
    it 'rejects non-hashes' do
      expect{ ClassyHash.validate_strict(false, {}) }.to raise_error(/hash/i)
      expect{ ClassyHash.validate_strict({}, false) }.to raise_error(/hash/i)
    end

    context 'schema is empty' do
      it 'rejects all non-empty hashes' do
        expect{ ClassyHash.validate_strict({}, {}) }.not_to raise_error
        expect{ ClassyHash.validate_strict({a: 1}, {}) }.to raise_error(/not specified/)
        expect{ ClassyHash.validate_strict({[1] => [2]}, {}) }.to raise_error(/not specified/)
        expect{ ClassyHash.validate_strict({ {} => {} }, {}) }.to raise_error(/not specified/)
      end
    end
  end

  describe '.validate_full' do
    it 'collects all errors' do
      schema = {a: String, b: { c: String }}
      expect{ ClassyHash.validate_full({a: 1, b: {} }, schema) }.to raise_error(%r{:a is not a\/an String, :b\[:c\] is not present})
      expect{ ClassyHash.validate_full({a: 'hey', b: { c: 'hello' }}, schema) }.not_to raise_error
    end

    it 'accepts a block for application level validation error handling' do
      entries = []

      # The actual SchemaValidationError is suppressed, since passing a block
      # implies that you want to do something else with validation errors.
      ClassyHash.validate_full({a: 1, b: {} }, {a: String, b: { c: String }}) do |error_entry|
        entries << error_entry
      end

      expect(entries).to eq [
        { full_path: ':a', message: 'a/an String' },
        { full_path: ':b[:c]', message: 'present' }
      ]
    end
  end

  # Integrated tests (see test data at the top of the file)
  classy_data.each do |d|
    describe '.validate' do
      context "schema is #{d[:name]}" do
        d[:good].each_with_index do |h, idx|
          it "accepts good hash #{idx}" do
            expect{ ClassyHash.validate(h, d[:schema]) }.not_to raise_error
          end

          it "accepts good hash #{idx} with extra members" do
            expect{ ClassyHash.validate(h.merge({k999: 'a', k000: :b}), d[:schema]) }.not_to raise_error
          end
        end

        d[:bad].each_with_index do |info, idx|
          it "rejects bad hash #{idx}" do
            expect{ ClassyHash.validate(info[1], d[:schema]) }.to raise_error(info[0])
          end
        end
      end
    end

    describe '.validate_strict' do
      context "schema is #{d[:name]}" do
        d[:good].each_with_index do |h, idx|
          it "accepts good hash #{idx}" do
            expect{ ClassyHash.validate_strict(h, d[:schema]) }.not_to raise_error
          end

          it "rejects good hash #{idx} with extra members" do
            expect{ ClassyHash.validate_strict(h.merge({k999: 'a', k000: :b}), d[:schema]) }.to raise_error(/contains members/)
          end

          it "includes unexpected hash #{idx} keys in error message if verbose is set" do
            expect {
              ClassyHash.validate_strict(h.merge(k999: 'a', k000: :b), d[:schema], true)
            }.to raise_error(/k999.*schema/)
          end
        end

        d[:bad].each_with_index do |info, idx|
          it "rejects bad hash #{idx}" do
            expect{ ClassyHash.validate_strict(info[1], d[:schema]) }.to raise_error(info[0])
          end
        end
      end
    end
  end
end
