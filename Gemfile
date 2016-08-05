source 'https://rubygems.org'

# Other schema validation Gems for benchmark comparisons
group :benchmark do
  # https://github.com/hoxworth/json-schema
  gem 'json-schema'

  # https://github.com/JamesBrooks/hash_validator
  gem 'hash_validator'

  # https://github.com/djsun/schema_hash
  gem 'schema_hash'
end

# MessagePack for super fast serialization
# http://msgpack.org
gem 'msgpack', groups: [:benchmark, :test]

# RSpec for tests
gem 'rspec', '~> 3.5', group: :test

# SimpleCov for offline test coverage
gem 'simplecov', '~> 0.12.0', require: false, group: :test

# Code Climate for online test coverage
gem 'codeclimate-test-reporter', require: false, group: :test

# Pry for debugging while developing
gem 'pry', require: false, group: :development
gem 'pry-byebug', require: false, group: :development, platforms: :mri
