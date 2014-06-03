Gem::Specification.new do |s|
  s.name = 'classy_hash'
  s.version = '0.1.2'
  s.license = 'MIT'
  s.files = ['lib/classy_hash.rb', 'lib/classy_hash/generate.rb']
  s.summary = 'Classy Hash: Keep your Hashes classy; a Hash schema validator'
  s.description = <<-DESC
    Classy Hash is a schema validator for Ruby Hashes.  You provide a simple
    schema Hash, and Classy Hash will make sure your data matches, providing
    helpful error messages if it doesn't.
    DESC
  s.authors = ['Deseret Book', 'Mike Bourgeous']
  s.email = 'mike@mikebourgeous.com'
  s.homepage = 'https://github.com/deseretbook/classy_hash'
end
