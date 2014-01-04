Gem::Specification.new do |spec|
  spec.name = 'rack-archive-zip-extract'
  spec.version = '0.0.1'
  spec.summary = 'Zip file server'
  spec.description = 'Rack::Archive::Zip::Extract serves files in zip archives.'
  spec.authors = ['KITAITI Makoto']
  spec.email = 'KitaitiMakoto@gmail.com'
  spec.required_ruby_version = '>= 2.0.0'
  spec.files = ['lib/rack/archive/zip/extract.rb']

  spec.add_runtime_dependency 'rack'
  spec.add_runtime_dependency 'zipruby'

  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'test-unit-notify'
  spec.add_development_dependency 'yard'
end
