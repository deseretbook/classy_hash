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
 msgpack              | no_op                | 127560
 msgpack              | classy_hash          | 71201
 msgpack              | classy_hash_strict   | 61102
 msgpack              | hash_validator       | 27950
 msgpack              | schema_hash          | 22227
 msgpack              | json_schema          | 1302
 msgpack              | json_schema_strict   | 1301
 msgpack              | json_schema_full     | 1280
```


### Examples

For now, see `test.rb` and `benchmark.rb`.

```ruby
# TODO - inline examples
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
