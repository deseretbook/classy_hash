Classy Hash
===========

[![Gem Version](https://badge.fury.io/rb/classy_hash.svg)](http://badge.fury.io/rb/classy_hash)
[![Test Coverage](https://codeclimate.com/github/deseretbook/classy_hash/badges/coverage.svg)](https://codeclimate.com/github/deseretbook/classy_hash/coverage)
[![Build Status](https://travis-ci.org/deseretbook/classy_hash.svg)](https://travis-ci.org/deseretbook/classy_hash)

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
Valid hashes:

   Serializer    |        Validator         |   Ops    |  Ops/sec   |  Alloc/op  |   Ops/GC  
-----------------+--------------------------+----------+------------+------------+-----------
 msgpack         | no_op                    |   200000 |   136844.4 |       28.0 |     1851.9
 msgpack         | classy_hash              |   200000 |    72862.9 |       31.0 |     1680.7
 msgpack         | classy_hash_strict       |   200000 |    59403.4 |       43.0 |     1234.6
 msgpack         | classy_hash_full         |   200000 |    73053.2 |       32.0 |     1639.3
 msgpack         | classy_hash_full_strict  |   200000 |    59777.6 |       44.0 |     1204.8
 msgpack         | classy_hash_no_raise     |   200000 |    73323.0 |       32.0 |     1639.3
 msgpack         | classy_hash_errors_array |   200000 |    73408.9 |       31.0 |     1680.7
 msgpack         | hash_validator           |   100000 |    33874.8 |       73.0 |      740.7
 msgpack         | schema_hash              |    50000 |    27407.0 |      118.0 |      450.5
 msgpack         | json_schema              |     8000 |     1884.7 |     1004.0 |       55.2
 msgpack         | json_schema_strict       |     8000 |     1862.1 |     1013.0 |       54.4
 msgpack         | json_schema_full         |     8000 |     1816.9 |     1013.0 |       54.4



Invalid hashes:

   Serializer    |        Validator         |   Ops    |  Ops/sec   |  Alloc/op  |   Ops/GC  
-----------------+--------------------------+----------+------------+------------+-----------
 msgpack         | classy_hash              |   500000 |    95680.0 |       28.2 |     1824.8
 msgpack         | classy_hash_strict       |   500000 |    80178.6 |       33.8 |     1543.2
 msgpack         | classy_hash_full         |   500000 |    70504.0 |       35.4 |     1474.9
 msgpack         | classy_hash_full_strict  |   500000 |    61334.0 |       41.0 |     1282.1
 msgpack         | classy_hash_no_raise     |   500000 |    70819.8 |       36.4 |     1436.8
 msgpack         | classy_hash_errors_array |   500000 |    40301.7 |       55.4 |      914.1
 msgpack         | hash_validator           |   250000 |    33720.2 |       69.0 |      778.8
 msgpack         | json_schema              |    20000 |     2153.3 |      894.6 |       61.5
 msgpack         | json_schema_strict       |    20000 |     2177.4 |      890.4 |       61.7
 msgpack         | json_schema_full         |    20000 |     1999.3 |      956.4 |       57.5
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

The `validate` method will raise an exception if validation fails.  Validation
proceeds until the first invalid value is found, then an error is thrown for
that value.  Later values are not checked unless you run a full validation with
`validate_full`.

You can pass `strict: true` as a keyword argument to `validate` to raise an
error if the input hash contains any members not specified in the schema.
Passing `verbose: true` will include the names of the unexpected hash keys in
the generated error message (a potential security risk in some settings).  See
the inline documentation in the source code for more details.  As of version
0.2.0, all nested schemas will also be checked for unexpected members.


#### Full validation

If you'd like to capture *all* errors, you can use `validate_full`. If you don't
pass a block, `validate_full` will simply raise an error that includes all the
violations in the message:

```ruby
schema = {
  key1: String,
  key2: Integer,
  key3: TrueClass
}

hash = {
  key1: 'A less classy Hash',
  key2: 1.25,
  key3: 'Also wrong'
}

ClassyHash.validate(hash, schema) # Throws ":key2 is not a/an Integer, :key3 is not a/an TrueClass"
```

However, if you pass a block, your application code can actually handle the
validation errors:

```ruby
errors = []

ClassyHash.validate(hash, schema) do |error_hash|
  errors << "#{error_hash[:full_path]}: #{error_hash[:message]}"
end

# Now, errors is [":key2: a/an Integer", ":key3: a/an TrueClass"]
```

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

#### Regular expressions

`Regexp` constraints, added in 0.1.4, will require values to be `String`s that
match a regular expression:

```ruby
schema = {
  key1: /Re.*quired/i
}

ClassyHash.validate({ key1: /required/ }, schema) # Throws ":key1 is not a String matching /re.*quired/i"
ClassyHash.validate({ key1: 'invalid' }, schema) # Throws ":key1 is not a String matching /re.*quired/i"
ClassyHash.validate({ key1: 'The regional manager inquired about ClassyHash' }, schema) # Okay
```

As with Ruby's `=~` operator, `Regexp`s can match anywhere in the `String`.  To
require the entire `String` to match, use [the standard `\A` and `\z`
anchors](http://ruby-doc.org/core-2.2.2/Regexp.html#class-Regexp-label-Anchors):

```ruby
schema = {
  key1: /\AStart.*end\z/
}

ClassyHash.validate({ key1: 'One must Start to end' }, schema) # Throws ":key1 is not a String matching /\\AStart.*end\\z/"
ClassyHash.validate({ key1: 'Start now, continue to the end' }, schema) # Okay
```

#### Ranges and lambdas

If you want to check more than just the type of a value, you can specify a
`Range` as a constraint.  If your `Range` endpoints are `Integer`s, `Numeric`s,
or `String`s, then Classy Hash will also restrict the type of the value to
`Integer`, `Numeric`, or `String`.

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

#### Procs

If nothing else will do, you can pass a `Proc`/`lambda`.  The `Proc` should
have no side effects, as it may be called more than once per value.  When using
a `Proc`, you should accept exactly one parameter and return `true` if
validation succeeds.  Any other value will be treated as a validation failure.
If the `Proc` returns a `String`, that string will be used in the error
message.

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

#### Sets

Added in version 0.2.0, `Set`s constrain a value to one of a list of values.
The `Set` constraint replaces the `enum` generator.  Note that a `Set` requires
an *exact* value match, unlike the Multiple Choice constraint or Composite
generator.

```ruby
schema = {
  key1: Set.new([1, 2, 3, 'see?'])
}

ClassyHash.validate({ key1: 1 }, schema) # Okay
ClassyHash.validate({ key1: 'see?' }, schema) # Okay
ClassyHash.validate({ key1: 4 }, schema) # Throws ":key1 is not an element of [1, 2, 3, 'see?']"
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
`ClassyHash::Generate` (or the `CH::G` alias introduced in 0.1.2) that will
generate a constraint for common tasks that are difficult to represent in the
base Classy Hash syntax.

##### Composite and negated constraints

You can combine multiple constraints in an AND or NAND fashion using the
Composite generators, `.all` and `.not`.  Because composite constraints
can be complex and confusing, they should be used only when other
approaches would be *more* complex and confusing.  Composite constraints
were added in version 0.2.0.

The `.all` generator requires all constraints to pass.

```ruby
schema = {
  key1: CH::G.all(Integer, 1.0..100.0)
}
ClassyHash.validate({ key1: 5 }, schema) # Okay
ClassyHash.validate({ key1: BigDecimal.new(5) }, schema) # Raises ":key1 is not all of [Integer, 1.0..100.0]"
```

The `.not` generator requires all constraints to fail.

```ruby
schema = {
  key1: CH::G.not(Rational, BigDecimal, 'a'..'c', 10..15)
}
ClassyHash.validate({ key1: 5 }, schema) # Okay
ClassyHash.validate({ key1: 10 }, schema) # Raises ":key1 is not none of [Rational, BigDecimal, "a".."c", 10..15]"
ClassyHash.validate({ key1: Rational(3, 5) }, schema) # Raises ":key1 is not none of [Rational, BigDecimal, "a".."c", 10..15]"
ClassyHash.validate({ key1: 'Good' }, schema) # Okay
ClassyHash.validate({ key1: 'broken' }, schema) # Raises ":key1 is not none of [Rational, BigDecimal, "a".."c", 10..15]"
```

The `.all` and `.not` generators become more useful when combined:

```ruby
schema = {
  # Note: this case could also be represented as key1: [1..9, 21..100]
  # Also note that Float ranges are used because ClassyHash only accepts
  # Integer values for Integer ranges; this is important for .not().
  key1: CH::G.all(Integer, 1.0..100.0, CH::G.not(10.0..20.0))
}
ClassyHash.validate({ key1: 9 }, schema) # Okay
ClassyHash.validate({ key1: 10 }, schema) # Raises :key1 is not all of [Integer, 1.0..100.0, none of [10.0..20.0]]
ClassyHash.validate({ key1: 25.0 }, schema) # Raises :key1 is not all of [Integer, 1.0..100.0, none of [10.0..20.0]]
```

Note that `.not` may accept a value for reasons you don't expect, since
its parameters are treated as ordinary ClassyHash constraints, and only
requires that its constraints raise some kind of error.  For example,
`CH::G.not(5..10)` will allow `6.0` but not `6`.


##### Enumeration

As of version 0.2.0, the `enum` generator is a deprecated compatibility method
that generates a `Set`.  See the above documentation for `Set` constraints.

```ruby
# Enumerator -- value must be one of the elements provided
schema = {
  key1: CH::G.enum(1, 2, 3, 4)
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
  key1: CH::G.length(5..6)
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
  key1: CH::G.string_length(0..15)
}

ClassyHash.validate({ key1: 'x' * 15 }, schema) # Okay
ClassyHash.validate({ key1: 'x' * 16 }, schema) # Throws ":key1 is not a String of length 0..15"
ClassyHash.validate({ key1: false }, schema) # Throws ":key1 is not a String of length 0..15"
```

The `Array` length constraint generator also checks the values of the array.

```ruby
# Array length generator
schema = {
  key1: CH::G.array_length(4, Integer, String)
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
  street1: /[0-9]+/,
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
      "street1": "123 Fake Street",
      "street2": null,
      "city": "",
      "state": "",
      "country": "",
      "postcode": ""
    },
    {
      "street1": "Building 53",
      "street2": "",
      "city": 5
    }
  ]
}
JSON

# ClassyHash#validate(..., strict: true) raises an error if the Hash contains
# any keys not specified by the schema.
ClassyHash.validate({ :extra_key => 0 }, user_schema, strict: true) # Throws "Top level contains members not specified in schema"
ClassyHash.validate(JSON.parse(data, symbolize_names: true), user_schema, strict: true) # Throws ":addresses[1][:city] is not a/an String
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
in internal DeseretBook.com systems, and subsequently enhanced by inside and
outside contributors.  See the git history for details.

### Alternatives

If you decide Classy Hash isn't for you, here are some of the other options we
considered before deciding to roll our own:

- [JSON Schema](http://json-schema.org/) ([json-schema gem](http://rubygems.org/gems/json-schema))
- [Hash Validator](https://github.com/JamesBrooks/hash_validator)
- [schema_hash](https://github.com/djsun/schema_hash)

### License

Classy Hash is released under the MIT license (see the `LICENSE` file for the
license text and copyright notice, and the git history for more contributors).
