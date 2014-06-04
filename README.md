Classy Hash
===========

### Keep Your Hashes Classy (a lightweight Hash validation gem)

Classy Hash is a lightweight RubyGem for validating Ruby hashes against a
simple schema Hash that indicates what data types are expected.  Classy Hash
will make sure your data matches, providing helpful error messages if it
doesn't.

Classy Hash is fantastic for helping developers become familiar with an API, by
letting them know exactly what they did wrong.  It also guards against mistakes
by verifying that incoming data meets expectations, and can serve as a
convenient data structure documentation format.

### Why Classy Hash?

Classy Hash was created as a lightweight alternative to the other good
validation gems available.  By taking advantage of built-in Ruby language
features, Classy Hash can validate common Hashes much faster than some of the
other gems we tested, with a dead simple schema syntax.

Classy Hash doesn't modify your Hashes or patch any core classes, so it's safe
to use just about anywhere.

Classy Hash is thoroughly tested (see the **Testing** section below).

Finally, Classy Hash is blazingly fast:

```
      Serializer      |      Validator       |  Ops/sec
----------------------+----------------------+-----------
 msgpack              | no_op                | 123525
 msgpack              | classy_hash          | 67798
 msgpack              | classy_hash_strict   | 59952
 msgpack              | hash_validator       | 27578
 msgpack              | schema_hash          | 22217
 msgpack              | json_schema          | 1255
 msgpack              | json_schema_full     | 1251
 msgpack              | json_schema_strict   | 1086
```


### Examples

A Classy Hash schema can be as simple or as complex as you like.  At the most
basic level, you list each key your Hash is required to contain, with the
expected Ruby class of the value.

For more examples, see `benchmark.rb` and `lib/spec/classy_hash_spec.rb`.

#### Simple example

Let's look at a simple schema for a Hash with three members:

```ruby
schema = {
  key1: String,
  key2: Integer,
  key3: TrueClass
}
```

This specifies a Hash with a `String`, an `Integer`, and a boolean value (both
`TrueClass` and `FalseClass` will accept `true` and `false`).  Here's how we
validate a Hash against our schema:

```ruby
hash = {
  key1: 'A Hash with class',
  key2: 0,
  key3: false
}

ClassyHash.validate(hash, schema) # Okay
```

Here's what happens if we try to validate an invalid Hash:

```ruby
hash = {
  key1: 'A less classy Hash',
  key2: 1.25,
  key3: 'Also wrong, but not checked'
}

ClassyHash.validate(hash, schema) # Throws ":key2 is not a/an Integer"
```

The `validate` and `validate_strict` methods will raise an exception if
validation fails.  Validation proceeds until the first invalid value is found,
then an error is thrown for that value.  Later values are not checked.


#### Multiple choice

It's possible to specify more than one option for a key, allowing multiple
types and/or `nil` to be used as the value for a key:

```ruby
schema = {
  key1: [ NilClass, String, FalseClass ]
}

ClassyHash.validate({ key1: nil }, schema) # Okay
ClassyHash.validate({ key1: 'Hi' }, schema) # Okay
ClassyHash.validate({ key1: true }, schema) # Okay
ClassyHash.validate({ key1: 1337 }, schema) # Throws ":key1 is not one of NilClass, String, FalseClass"
```

#### Optional keys

Classy Hash will raise an error if a key from the schema is missing from the
hash being validated:

```ruby
schema = {
  key1: TrueClass
}

ClassyHash.validate({}, schema) # Throws ":key1 is not present"
```

If we want to allow a key to be omitted, we can mark it as optional by adding
the `:optional` symbol as the first element of a multiple choice array:

```ruby
schema = {
  key1: [:optional, TrueClass]
}

ClassyHash.validate({}, schema) # Doesn't throw
```

#### Ranges and lambdas

If you want to check more than just the type of a value, you can specify a
`Range` or a `Proc` as a constraint.  If your `Range` endpoints are `Integer`s,
`Numeric`s, or `String`s, then Classy Hash will also restrict the type of the
value to `Integer`, `Numeric`, or `String`.

```ruby
# An Integer range
schema = {
  key1: 1..10
}

ClassyHash.validate({ key1: 5 }, schema) # Okay
ClassyHash.validate({ key1: -5 }, schema) # Throws ":key1 is not in range 1..10"
ClassyHash.validate({ key1: 2.5 }, schema) # Throws ":key1 is not an Integer"
```

```ruby
# A more interesting range -- this use is not recommended :-)
schema = {
  key1: [1]..[5]
}

ClassyHash.validate({ key1: [2, 3, 4] }, schema) # Okay
ClassyHash.validate({ key1: [5, 0] }, schema) # Throws ":key1 is not in range [1]..[5]"
```

When using a `Proc`, you should accept exactly one parameter and return `true`
if validation succeeds.  Any other value will be treated as a validation
failure.  If the `Proc` returns a `String`, that string will be used in the
error message.

```ruby
# A lambda without an error message
schema = {
  key1: lambda {|v| v.is_a?(Integer) && v.odd?}
}

ClassyHash.validate({ key1: 1 }, schema) # Okay
ClassyHash.validate({ key1: 2 }, schema) # Throws ":key1 is not accepted by Proc"
```

```ruby
# A lambda with an error message
schema = {
  key1: lambda {|v| (v.is_a?(Integer) && v.odd?) || 'an odd integer'}
}

ClassyHash.validate({ key1: 1 }, schema) # Okay
ClassyHash.validate({ key1: 2 }, schema) # Throws ":key1 is not an odd integer"
```

#### Nested schemas

Classy Hash accepts nested schemas.  You can also use a schema as one of the
options in a multiple choice key.

```ruby
schema = {
  key1: {
    msg: String
  },
  key2: {
    n1: [Integer, { y: Numeric }]
  }
}

hash1 = {
  key1: { msg: 'Valid' },
  key2: { n1: { y: 1.0 } }
}

hash2 = {
  key1: { msg: 'Also valid' },
  key2: { n1: -1 }
}

hash3 = {
  key1: { msg: false },
  key2: { n1: 1 }
}

hash4 = {
  key1: { msg: 'Not valid' },
  key2: { n1: { y: false } }
}

ClassyHash.validate(hash1, schema) # Okay
ClassyHash.validate(hash2, schema) # Okay
ClassyHash.validate(hash3, schema) # Throws ":key1[:msg] is not a/an String"
ClassyHash.validate(hash4, schema) # Throws ":key2[:n1][:y] is not a/an Numeric"
ClassyHash.validate({ key1: false }, schema) # Throws ":key1 is not a Hash"
```

#### Arrays

You can use Classy Hash to validate the members of an array.  Array constraints
are specified by double-array-wrapping a multiple choice list.  Array
constraints can also themselves be part of a multiple choice list or array
constraint.  Empty arrays are always accepted by array constraints.

```ruby
# Simple array of integers
schema = {
  key1: [[Integer]]
}

ClassyHash.validate({ key1: [] }, schema) # Okay
ClassyHash.validate({ key1: [1, 2, 3, 4, 5] }, schema) # Okay
ClassyHash.validate({ key1: [1, 2, 3, 0.5] }, schema) # Throws ":key1[3] is not one of Integer"
ClassyHash.validate({ key1: false }, schema) # Throws ":key1 is not an Array"
```

```ruby
# An integer, or an array of arrays of strings
schema = {
  key1: [Integer, [[ [[ String ]] ]]]
}

ClassyHash.validate({ key1: 1 }, schema) # Okay
ClassyHash.validate({ key1: [ [], ['a'], ['b', 'c'] ] }, schema) # Okay
ClassyHash.validate({ key1: ['bad'] }, schema) # Throws ":key1[0] is not one of [[String]]"
ClassyHash.validate({ key1: [ [], ['a'], ['b', false] ] }, schema) # Throws ":key1[2][1] is not one of String"
```

If you want to check the length of an array, you can use a `Proc` (also see the
Generators section below):

```ruby
# An array of two integers
schema = {
  key1: lambda {|v|
    if v.is_a?(Array) && v.length == 2
      begin
        ClassyHash.validate({k: v}, {k: [[Integer]]})
        true
      rescue => e
        "valid: #{e}"
      end
    else
      "an array of length 2"
    end
  }
}

ClassyHash.validate({ key1: [1, 2] }, schema) # Okay
ClassyHash.validate({ key1: [1, false] }, schema) # Throws ":key1 is not valid: :k[1] is not one of Integer"
ClassyHash.validate({ key1: [1] }, schema) # Throws ":key1 is not an array of length 2"
```

#### Generators

Version 0.1.1 of Classy Hash introduces some helper methods in
`ClassyHash::Generate` that will generate a constraint for common tasks that
are difficult to represent in the base Classy Hash syntax.

##### Enumeration

The simplest generator checks for a set of exact values.

```ruby
# Enumerator -- value must be one of the elements provided
schema = {
  key1: ClassyHash::Generate.enum(1, 2, 3, 4)
}

ClassyHash.validate({ key1: 1 }, schema) # Okay
ClassyHash.validate({ key1: -1 }, schema) # Throws ":key1 is not an element of [1, 2, 3, 4]"
```

##### Arbitrary length

The arbitrary length generator checks the length of any type that responds to
`:length`.

```ruby
# Simple length generator -- length of value must be equal to a value, or
# within a range
schema = {
  key1: ClassyHash::Generate.length(5..6)
}

ClassyHash.validate({ key1: '123456' }, schema) # Okay
ClassyHash.validate({ key1: {a: 1, b: 2, c: 3, d: 4, e: 5} }, schema) # Okay
ClassyHash.validate({ key1: [1, 2] }, schema) # Throws ":key1 is not of length 5..6"
ClassyHash.validate({ key1: 5 }, schema) # Throws ":key1 is not a type that responds to :length"
```

##### String or Array length

Since checking the length of a `String` or an `Array` is very common, there are
generators that will verify a value is the correct type *and* the correct
length.

```ruby
# String length generator
schema = {
  key1: ClassyHash::Generate.string_length(0..15)
}

ClassyHash.validate({ key1: 'x' * 15 }, schema) # Okay
ClassyHash.validate({ key1: 'x' * 16 }, schema) # Throws ":key1 is not a String of length 0..15"
ClassyHash.validate({ key1: false }, schema) # Throws ":key1 is not a String of length 0..15"
```

The `Array` length constraint generator also checks the values of the array.

```ruby
# Array length generator
schema = {
  key1: ClassyHash::Generate.array_length(4, Integer, String)
}

ClassyHash.validate({ key1: [1, 'two', 3, 4] }, schema) # Okay
ClassyHash.validate({ key1: [1, 2, false, 4] }, schema) # Throws ":key1 is not valid: :array[2] is not one of Integer, String"
ClassyHash.validate({ key1: false }, schema) # Throws ":key1 is not an Array of length 4"
```

#### A practical example (user and address)

Here's a more practical application of Classy Hash.  Suppose you have an API
that accepts POSTs containing JSON user data, that you convert to a Ruby
Hash with something like `JSON.parse(data, symbolize_names: true)`.  The user
should have some basic fields, an array of addresses, and no extra fields.

Here's how you might use Classy Hash to validate your user objects and generate
helpful error messages:

```ruby
# Note: this is not guaranteed to be a useful address checking schema.
address_schema = {
  street1: String,
  street2: [NilClass, String],
  city: String,
  state: [NilClass, String],
  country: String,
  postcode: [NilClass, Integer, String]
}
user_schema = {
  id: Integer,
  name: String,
  email: lambda {|v| (v.is_a?(String) && v.include?('@')) || 'an e-mail address'},
  addresses: [[ address_schema ]]
}

data = <<JSON
{
  "id": 1,
  "name": "",
  "email": "@",
  "addresses": [
    {
      "street1": "",
      "street2": null,
      "city": "",
      "state": "",
      "country": "",
      "postcode": ""
    },
    {
      "street1": "",
      "street2": "",
      "city": 5
    }
  ]
}
JSON

# ClassyHash#validate_strict raises an error if the Hash contains any keys not
# specified by the schema.
ClassyHash.validate_strict({ :extra_key => 0 }, user_schema) # Throws "Hash contains members not specified in schema"
ClassyHash.validate_strict(JSON.parse(data, symbolize_names: true), user_schema) # Throws ":addresses[1][:city] is not a/an String
```

### Testing

Classy Hash includes extremely thorough [RSpec](http://rspec.info) tests:

```bash
# Execute within a clone of the classy_hash Git repository:
bundle install
rspec
```

### Who wrote it?

Classy Hash was written by Mike Bourgeous for API validation and documentation
in internal DeseretBook.com systems.

### Alternatives

If you decide Classy Hash isn't for you, here are some of the other options we
considered before deciding to roll our own:

- [JSON Schema](http://json-schema.org/) ([json-schema gem](http://rubygems.org/gems/json-schema))
- [Hash Validator](https://github.com/JamesBrooks/hash_validator)
- [schema_hash](https://github.com/djsun/schema_hash)

### License

Classy Hash is released under the MIT license (see the `LICENSE` file for the
license text and copyright notice).
