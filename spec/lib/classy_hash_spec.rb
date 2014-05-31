require 'msgpack'
require 'classy_hash'

# ClassyHash tests
RSpec.describe ClassyHash do
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
      expect{ ClassyHash.validate({a: nil}, {a: String}) }.to raise_error
      expect{ ClassyHash.validate({a: 3}, {a: String}) }.to raise_error
      expect{ ClassyHash.validate({a: false}, {a: Numeric}) }.to raise_error
      expect{ ClassyHash.validate({a: {q: :q}}, {a: Array}) }.to raise_error
      expect{ ClassyHash.validate({a: [:q, :q]}, {a: Hash}) }.to raise_error
    end

    it 'accepts fixnum, bignum, float, and rational for numeric' do
      expect{ ClassyHash.validate({a: 0}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1<<200}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 1.0123}, {a: Numeric}) }.not_to raise_error
      expect{ ClassyHash.validate({a: Rational(1, 3)}, {a: Numeric}) }.not_to raise_error
    end

    it 'rejects float, bignum, and rational for fixnum' do
      expect{ ClassyHash.validate({a: 1.0}, {a: Fixnum}) }.to raise_error
      expect{ ClassyHash.validate({a: 1<<200}, {a: Fixnum}) }.to raise_error
      expect{ ClassyHash.validate({a: Rational(1, 3)}, {a: Fixnum}) }.to raise_error
    end

    it 'accepts valid multiple choice values' do
      expect{ ClassyHash.validate({a: nil}, {a: [NilClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'hello'}, {a: [String]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: 'str'}, {a: [String, Rational, NilClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: Rational(-3, 5)}, {a: [String, Rational, NilClass]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: nil}, {a: [String, Rational, NilClass]}) }.not_to raise_error
    end

    it 'rejects invalid multiple choice values' do
      expect{ ClassyHash.validate({a: nil}, {a: [String]}) }.to raise_error
      expect{ ClassyHash.validate({a: false}, {a: [NilClass]}) }.to raise_error
      expect{ ClassyHash.validate({a: 1}, {a: [String]}) }.to raise_error
      expect{ ClassyHash.validate({a: 1}, {a: [String, Rational, NilClass]}) }.to raise_error
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
      expect{ ClassyHash.validate({a: 1}, {a: TrueClass}) }.to raise_error
      expect{ ClassyHash.validate({a: 0}, {a: FalseClass}) }.to raise_error
      expect{ ClassyHash.validate({a: 1}, {a: [TrueClass]}) }.to raise_error
      expect{ ClassyHash.validate({a: 0}, {a: [FalseClass]}) }.to raise_error
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
      expect{ ClassyHash.validate({a: [nil]}, {a: [[String]]}) }.to raise_error
      expect{ ClassyHash.validate({a: ['hi', 'hello', 'heya', :optional]}, {a: [[String]]}) }.to raise_error
      expect{ ClassyHash.validate({a: [1]}, {a: [[String]]}) }.to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3, '']}, {a: [[Integer]]}) }.to raise_error(/\[3\]/)
    end

    it 'accepts valid multiple-choice arrays' do
      expect{ ClassyHash.validate({a: []}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: ['str']}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [nil]}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3]}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: [1, nil, 'str', 4]}, {a: [[String, NilClass, Integer]]}) }.not_to raise_error
    end

    it 'rejects invalid multiple-choice arrays' do
      expect{ ClassyHash.validate({a: [nil]}, {a: [[String]]}) }.to raise_error
      expect{ ClassyHash.validate({a: ['hi', 'hello', 'heya', :optional]}, {a: [[String]]}) }.to raise_error
      expect{ ClassyHash.validate({a: [1]}, {a: [[String]]}) }.to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3, '']}, {a: [[Integer]]}) }.to raise_error(/\[3\]/)
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
      expect{ ClassyHash.validate({a: 'str', b: true}, {a: TrueClass, b: String}) }.to raise_error
    end

    it 'rejects hashes with missing keys' do
      expect{ ClassyHash.validate({}, {a: NilClass}) }.to raise_error
      expect{ ClassyHash.validate({}, {a: Integer}) }.to raise_error
      expect{ ClassyHash.validate({a: 1}, {a: Integer, b: NilClass}) }.to raise_error
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
      expect{ ClassyHash.validate({a: nil}, {a: [:optional, Integer]}) }.to raise_error
      expect{ ClassyHash.validate({a: 'str'}, {a: [:optional, Integer]}) }.to raise_error
      expect{ ClassyHash.validate({a: :sym1}, {a: [:optional, Integer, String]}) }.to raise_error
    end

    it 'rejects invalid optional arrays' do
      expect{ ClassyHash.validate({a: [5.5]}, {a: [:optional, [[Integer]] ]}) }.to raise_error
      expect{ ClassyHash.validate({a: [1, 2, 3, 'str']}, {a: [:optional, [[Integer]] ]}) }.to raise_error(/\[3\]/)
    end

    it 'accepts missing optional member with proc that would always fail' do
      # We can ensure a member is *never* present with this construct
      expect{ ClassyHash.validate({}, {a: [:optional, lambda {|v| false}]}) }.not_to raise_error
      expect{ ClassyHash.validate({a: nil}, {a: [:optional, lambda {|v| false}]}) }.to raise_error
    end

    it 'accepts or rejects hashes using a proc' do
      expect{ ClassyHash.validate({a: 1}, {a: lambda {|v| v == 1}}) }.not_to raise_error
      expect{ ClassyHash.validate({a: -1}, {a: lambda {|v| v == 1}}) }.to raise_error
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
      expect{ ClassyHash.validate({a: 0}, {a: 1..2}) }.to raise_error
      expect{ ClassyHash.validate({a: Rational(1, 2)}, {a: 1.0..2.0}) }.to raise_error
      expect{ ClassyHash.validate({a: 'spinach'}, {a: 'cabbage'..'cauliflower'}) }.to raise_error
      expect{ ClassyHash.validate({a: [2, 1]}, {a: [0]..[2]}) }.to raise_error
    end

    it 'rejects invalid types using a range' do
      expect{ ClassyHash.validate({a: 1.0}, {a: 1..2}) }.to raise_error(/Integer/)
      expect{ ClassyHash.validate({a: 1}, {a: 'a'..'z'}) }.to raise_error(/String/)
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
    context 'schema is empty' do
      let(:schema) { empty_schema }

      it 'rejects all non-empty hashes' do
        expect{ ClassyHash.validate_strict({}, {}) }.not_to raise_error
        expect{ ClassyHash.validate_strict({a: 1}, {}) }.to raise_error
        expect{ ClassyHash.validate_strict({[1] => [2]}, {}) }.to raise_error
        expect{ ClassyHash.validate_strict({ {} => {} }, {}) }.to raise_error
      end
    end
  end
end
