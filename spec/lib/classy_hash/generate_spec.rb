# Classy Hash: Keep Your Hashes Classy (Generators RSpec test suite)
# Created June 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2016 Deseret Book
# See LICENSE and README.md for details.

require 'rational'
require 'bigdecimal'

describe CH::G do
  context 'full validation' do
    let(:schema) {
      { a: CH::G.all(String, 'a'..'z') }
    }

    describe '.all' do
      it 'accepts matching values' do
        expect{ CH.validate({ a: 'a' }, schema, full: true) }.not_to raise_error
      end

      it 'rejects non-matching values' do
        expect{ CH.validate({ a: 1 }, schema, full: true) }.to raise_error(/all of.*String/)
      end
    end
  end

  describe '.all' do
    let(:schema) {
      {
        str: [:optional, CH::G.all(String, 'a'..'z', ->(v){ v.respond_to?(:length) && v.length.odd? ? true : 'odd length' })],
        int: [:optional, CH::G.all(Integer, 1..100, CH::G.not(Set.new([7, 13])))],
        nil: [:optional, CH::G.all(NilClass)],
      }
    }

    it 'accepts values matching all constraints' do
      expect{ CH.validate({ str: 'hello' }, schema) }.not_to raise_error
      expect{ CH.validate({ str: 'a' }, schema) }.not_to raise_error
      expect{ CH.validate({ str: 'z' }, schema) }.not_to raise_error

      expect{ CH.validate({ int: 1 }, schema) }.not_to raise_error
      expect{ CH.validate({ int: 10 }, schema) }.not_to raise_error
      expect{ CH.validate({ int: 100 }, schema) }.not_to raise_error

      expect{ CH.validate({ nil: nil }, schema) }.not_to raise_error
    end

    it 'rejects values not matching all constraints' do
      expect{ CH.validate({ str: 3 }, schema) }.to raise_error(/all of.*String.*/)
      expect{ CH.validate({ str: :invalid }, schema) }.to raise_error(/all of.*String.*/)
      expect{ CH.validate({ str: 'hi' }, schema) }.to raise_error(/all of.*String.*odd length/)
      expect{ CH.validate({ str: 'A' }, schema) }.to raise_error(/all of.*String.*Proc/)

      expect{ CH.validate({ int: 0 }, schema) }.to raise_error(/all of.*Integer/)
      expect{ CH.validate({ int: 10.5 }, schema) }.to raise_error(/all of.*Integer/)
      expect{ CH.validate({ int: 101 }, schema) }.to raise_error(/all of.*Integer/)
      expect{ CH.validate({ int: '50' }, schema) }.to raise_error(/all of.*Integer/)

      expect{ CH.validate({ nil: :nil }, schema) }.to raise_error(/all of.*Nil/)
    end

    it 'raises an error if no constraints are given' do
      expect{ CH::G.all }.to raise_error(/No constraints/)
    end
  end

  describe '.not' do
    let(:not_schema) { { not: CH::G.not(Rational, BigDecimal, String, 10.0..20.0) } }
    let(:single_schema) { { single: CH::G.not(String) } }

    it 'accepts values not matching any constraints' do
      expect{ CH.validate({ not: 9 }, not_schema) }.not_to raise_error
      expect{ CH.validate({ not: -5.5 }, not_schema) }.not_to raise_error
      expect{ CH.validate({ not: :symbol }, not_schema) }.not_to raise_error
      expect{ CH.validate({ not: Object }, not_schema) }.not_to raise_error
      expect{ CH.validate({ not: nil }, not_schema) }.not_to raise_error

      expect{ CH.validate({ single: String }, single_schema) }.not_to raise_error
      expect{ CH.validate({ single: :String }, single_schema) }.not_to raise_error
      expect{ CH.validate({ single: 123 }, single_schema) }.not_to raise_error
      expect{ CH.validate({ single: nil }, single_schema) }.not_to raise_error
    end

    it 'rejects values matching one or more constraints' do
      expect{ CH.validate({ not: Rational(3, 5) }, not_schema) }.to raise_error(/:not.*none of.*Rational.*BigDecimal.*String/)
      expect{ CH.validate({ not: BigDecimal('0.25') }, not_schema) }.to raise_error(/:not.*none of.*Rational.*BigDecimal.*String/)
      expect{ CH.validate({ not: 'A string' }, not_schema) }.to raise_error(/:not.*none of.*Rational.*BigDecimal.*String/)
      expect{ CH.validate({ not: 13.0 }, not_schema) }.to raise_error(/:not.*none of.*Rational.*BigDecimal.*String/)
      expect{ CH.validate({ not: 13 }, not_schema) }.to raise_error(/:not.*none of.*Rational.*BigDecimal.*String/)

      expect{ CH.validate({ single: 'valid' }, single_schema) }.to raise_error(/:single.*none of.*String/)
      expect{ CH.validate({ single: '' }, single_schema) }.to raise_error(/:single.*none of.*String/)
    end

    it 'raises an error if no constraints are given' do
      expect{ CH::G.not }.to raise_error(/No constraints/)
    end
  end

  describe '.enum' do
    let(:int_schema) do
      { a: CH::G.enum(1, 2, 3, 4, 5) }
    end

    let(:multi_schema) do
      { a: CH::G.enum(1, nil, false, 'test') }
    end

    it 'accepts values in the list' do
      expect{ ClassyHash.validate({ a: 1 }, int_schema )}.not_to raise_error
      expect{ ClassyHash.validate({ a: 5 }, int_schema )}.not_to raise_error
      expect{ ClassyHash.validate({ a: nil }, multi_schema )}.not_to raise_error
      expect{ ClassyHash.validate({ a: false }, multi_schema )}.not_to raise_error
    end

    it 'rejects values not in the list' do
      expect{ ClassyHash.validate({ a: -1 }, int_schema )}.to raise_error(/element of/)
      expect{ ClassyHash.validate({ a: 'x' }, int_schema )}.to raise_error(/element of/)
      expect{ ClassyHash.validate({ a: true }, multi_schema )}.to raise_error(/element of/)
      expect{ ClassyHash.validate({ a: 0 }, multi_schema )}.to raise_error(/element of/)
    end
  end

  describe '.length' do
    let(:int_schema) do
      { a: CH::G.length(3) }
    end

    let(:range_schema) do
      { a: CH::G.length(2..4) }
    end

    it 'accepts objects with a valid length' do
      expect{ ClassyHash.validate({ a: '123' }, int_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [1, 2, 3] }, int_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: {a: 1, b: 2, c: 3} }, int_schema) }.not_to raise_error

      expect{ ClassyHash.validate({ a: '12' }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [1, 2] }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: {a: 1, b: 2} }, range_schema) }.not_to raise_error

      expect{ ClassyHash.validate({ a: '1234' }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [1, 2, 3, 4] }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: {a: 1, b: 2, c: 3, d: 4} }, range_schema) }.not_to raise_error
    end

    it 'rejects objects with an invalid length' do
      expect{ ClassyHash.validate({ a: '' }, int_schema) }.to raise_error(/of length/)
      expect{ ClassyHash.validate({ a: [] }, int_schema) }.to raise_error(/of length/)
      expect{ ClassyHash.validate({ a: [1] }, int_schema) }.to raise_error(/of length/)
      expect{ ClassyHash.validate({ a: {} }, int_schema) }.to raise_error(/of length/)
      expect{ ClassyHash.validate({ a: {a: 1, b: 2} }, int_schema) }.to raise_error(/of length/)

      expect{ ClassyHash.validate({ a: '1' }, range_schema) }.to raise_error(/of length.*\.\./)
      expect{ ClassyHash.validate({ a: [] }, range_schema) }.to raise_error(/of length.*\.\./)
      expect{ ClassyHash.validate({ a: [1] }, range_schema) }.to raise_error(/of length.*\.\./)
      expect{ ClassyHash.validate({ a: {} }, range_schema) }.to raise_error(/of length.*\.\./)
      expect{ ClassyHash.validate({ a: {a: 1} }, range_schema) }.to raise_error(/of length.*\.\./)

      expect{ ClassyHash.validate({ a: '12345' }, range_schema) }.to raise_error(/of length.*\.\./)
      expect{ ClassyHash.validate({ a: [1, 2, 3, 4, 5] }, range_schema) }.to raise_error(/of length.*\.\./)
      expect{ ClassyHash.validate({ a: {a: 1, b: 2, c: 3, d: 4, e: 5} }, range_schema) }.to raise_error(/of length.*\.\./)
    end

    it 'rejects objects that do not have a length' do
      expect{ ClassyHash.validate({ a: 3 }, int_schema) }.to raise_error(/respond.*length/)
      expect{ ClassyHash.validate({ a: 3 }, range_schema) }.to raise_error(/respond.*length/)
    end

    it 'rejects lengths and range endpoints that are not integers' do
      expect{ CH::G.length(1.5) }.to raise_error(/Integer/)
      expect{ CH::G.length(5..9.5) }.to raise_error(/Integer/)
      expect{ CH::G.length('a'..'z') }.to raise_error(/Integer/)
    end
  end

  describe '.array_length' do
    let(:int_schema) do
      { a: CH::G.array_length(4, Integer) }
    end

    let(:range_schema) do
      { a: CH::G.array_length(0..2, Integer, String, NilClass) }
    end

    it 'accepts arrays with a valid length and values' do
      expect{ ClassyHash.validate({ a: [1, 2, 3, 4] }, int_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [0, 0, 0, 0] }, int_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: (5..8).to_a }, int_schema) }.not_to raise_error

      expect{ ClassyHash.validate({ a: [1, 'two'] }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [0] }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [nil, -1] }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: [] }, range_schema) }.not_to raise_error
    end

    it 'rejects arrays with invalid values' do
      expect{ ClassyHash.validate({ a: [1, 2, 3, 'four'] }, int_schema) }.to raise_error(/:a.*:array\[3\]/)
      expect{ ClassyHash.validate({ a: [nil, 0, 0, 0] }, int_schema) }.to raise_error(/:a.*:array\[0\]/)

      expect{ ClassyHash.validate({ a: [1.25, 'two'] }, range_schema) }.to raise_error(/:a.*:array\[0\]/)
      expect{ ClassyHash.validate({ a: [0.1] }, range_schema) }.to raise_error(/:a.*:array\[0\]/)
      expect{ ClassyHash.validate({ a: [nil, false] }, range_schema) }.to raise_error(/:a.*:array\[1\]/)
    end

    it 'rejects arrays with an invalid length' do
      expect{ ClassyHash.validate({ a: [] }, int_schema) }.to raise_error(/Array.*length/)
      expect{ ClassyHash.validate({ a: [0, 0, 0] }, int_schema) }.to raise_error(/Array.*length/)
      expect{ ClassyHash.validate({ a: (5..18).to_a }, int_schema) }.to raise_error(/Array.*length/)

      expect{ ClassyHash.validate({ a: [1, 'two', 3] }, range_schema) }.to raise_error(/Array.*length/)
      expect{ ClassyHash.validate({ a: [nil, -1, 'three', 4] }, range_schema) }.to raise_error(/Array.*length/)
    end

    it 'rejects non-arrays' do
      expect{ ClassyHash.validate({ a: 4 }, int_schema) }.to raise_error(/Array/)
      expect{ ClassyHash.validate({ a: false }, int_schema) }.to raise_error(/Array/)
      expect{ ClassyHash.validate({ a: :a }, int_schema) }.to raise_error(/Array/)
      expect{ ClassyHash.validate({ a: '1234' }, int_schema) }.to raise_error(/Array/)

      expect{ ClassyHash.validate({ a: 0 }, range_schema) }.to raise_error(/Array/)
      expect{ ClassyHash.validate({ a: false }, range_schema) }.to raise_error(/Array/)
      expect{ ClassyHash.validate({ a: nil }, range_schema) }.to raise_error(/Array/)
      expect{ ClassyHash.validate({ a: '1' }, range_schema) }.to raise_error(/Array/)
    end
  end

  describe '.string_length' do
    let(:int_schema) do
      { a: CH::G.string_length(3) }
    end

    let(:range_schema) do
      { a: CH::G.string_length(0..2) }
    end

    let(:multi_schema) do
      { a: [:optional, CH::G.string_length(0..2)] }
    end

    it 'accepts strings with a valid length' do
      expect{ ClassyHash.validate({ a: '123' }, int_schema) }.not_to raise_error

      expect{ ClassyHash.validate({ a: '' }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '1' }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '12' }, range_schema) }.not_to raise_error

      expect{ ClassyHash.validate({ a: '' }, multi_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '1' }, multi_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '12' }, multi_schema) }.not_to raise_error
    end

    it 'rejects strings with an invalid length' do
      expect{ ClassyHash.validate({ a: '' }, int_schema) }.to raise_error(/String.*length/)
      expect{ ClassyHash.validate({ a: '1234' }, int_schema) }.to raise_error(/String.*length/)

      expect{ ClassyHash.validate({ a: '123' }, range_schema) }.to raise_error(/String.*length/)
      expect{ ClassyHash.validate({ a: '123456' }, range_schema) }.to raise_error(/String.*length/)

      expect{ ClassyHash.validate({ a: '123' }, multi_schema) }.to raise_error(/String.*length/)
      expect{ ClassyHash.validate({ a: '123456' }, multi_schema) }.to raise_error(/String.*length/)
    end

    it 'rejects non-strings' do
      expect{ ClassyHash.validate({ a: 3 }, int_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: false }, int_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: :a }, int_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: ['1', '2', '3'] }, int_schema) }.to raise_error(/String/)

      expect{ ClassyHash.validate({ a: 0 }, range_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: false }, range_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: :a }, range_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: ['1', '2'] }, range_schema) }.to raise_error(/String/)

      expect{ ClassyHash.validate({ a: 0 }, multi_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: false }, multi_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: :a }, multi_schema) }.to raise_error(/String/)
      expect{ ClassyHash.validate({ a: ['1', '2'] }, multi_schema) }.to raise_error(/String/)
    end
  end
end
