Gem::Specification.new do |spec|
  spec.name = 'rack-zip'
  spec.version = '0.0.1'
  spec.summary = 'Zip file server'
  spec.description = 'Rack::Zip serves files in zip archives.'
  spec.authors = ['KITAITI Makoto']
  spec.email = 'KitaitiMakoto@gmail.com'
  spec.files = ['lib/rack/zip.rb']

  spec.add_runtime_dependency 'rack'
  spec.add_runtime_dependency 'zipruby'
end
