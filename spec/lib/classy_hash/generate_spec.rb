# Classy Hash: Keep Your Hashes Classy (Generators RSpec test suite)
# Created June 2014 by Mike Bourgeous, DeseretBook.com
# Copyright (C)2014 Deseret Book
# See LICENSE and README.md for details.

require 'classy_hash'

RSpec.describe ClassyHash::Generate do
  describe '.enum' do
    let(:int_schema) do
      { a: ClassyHash::Generate.enum(1, 2, 3, 4, 5) }
    end

    let(:multi_schema) do
      { a: ClassyHash::Generate.enum(1, nil, false, 'test') }
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
      { a: ClassyHash::Generate.length(3) }
    end

    let(:range_schema) do
      { a: ClassyHash::Generate.length(2..4) }
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
  end

  describe '.array_length' do
    let(:int_schema) do
      { a: ClassyHash::Generate.array_length(4, Integer) }
    end

    let(:range_schema) do
      { a: ClassyHash::Generate.array_length(0..2, Integer, String, NilClass) }
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
      { a: ClassyHash::Generate.string_length(3) }
    end

    let(:range_schema) do
      { a: ClassyHash::Generate.string_length(0..2) }
    end

    it 'accepts strings with a valid length' do
      expect{ ClassyHash.validate({ a: '123' }, int_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '' }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '1' }, range_schema) }.not_to raise_error
      expect{ ClassyHash.validate({ a: '12' }, range_schema) }.not_to raise_error
    end

    it 'rejects strings with an invalid length' do
      expect{ ClassyHash.validate({ a: '' }, int_schema) }.to raise_error(/String.*length/)
      expect{ ClassyHash.validate({ a: '1234' }, int_schema) }.to raise_error(/String.*length/)

      expect{ ClassyHash.validate({ a: '123' }, range_schema) }.to raise_error(/String.*length/)
      expect{ ClassyHash.validate({ a: '123456' }, range_schema) }.to raise_error(/String.*length/)
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
    end
  end
end
