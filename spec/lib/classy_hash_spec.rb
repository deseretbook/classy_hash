require 'msgpack'
require 'classy_hash'

# ClassyHash tests
RSpec.describe ClassyHash do
  let(:empty_schema) { {} }
  let(:simple_schema) { {} }
  let(:simple_data) {
    {
      :good => [
        # TODO: Good hashes for simple schema
      ],
      :bad => [
        # TODO: Bad hashes for simple schema
      ],
    }
  }

  describe '.validate' do
    context 'schema is empty' do
      let(:schema) { empty_schema }

      pending 'accepts all hashes'
    end

    # TODO: simple schema tests
  end

  describe '.validate_strict' do
    context 'schema is empty' do
      let(:schema) { empty_schema }

      pending 'rejects all hashes'
    end

    # TODO: simple schema tests
  end
end
