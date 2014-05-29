classy-hash
===========

## Keep your Hashes {classy} -- Lightweight Hash validation gem

Classy Hash is a lightweight RubyGem for validating Ruby hashes.  You provide a
simple schema Hash, and Classy Hash will make sure your data matches, providing
helpful error messages if it doesn't.

Classy Hash is fantastic for helping developers become familiar with an API, by
letting them know exactly what they did wrong.  It also guards against mistakes
by verifying that incoming data meets expectations.

### Why Classy Hash?

Classy Hash was created as a lightweight alternative to the other great
validation gems available.  By taking advantage of built-in Ruby language
features, Classy Hash can validate common Hashes up to 4x faster than some of
the other gems we tested.

Additionally, Classy Hash doesn't modify your Hashes, so it's safe to use just
about anywhere.

### Examples

```ruby
# TODO
```

### Alternatives

If you decide Classy Hash isn't for you, here are some of the other options we
considered before deciding to roll our own:

- [JSON Schema](http://json-schema.org/) ([json-schema gem](http://rubygems.org/gems/json-schema))
- [Hash Validator](https://github.com/JamesBrooks/hash_validator)
- [schema_hash](https://github.com/djsun/schema_hash)

### License

Classy Hash is released under the MIT license (see the `LICENSE` file for the
license text).
