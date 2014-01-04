Gem::Specification.new do |spec|
  spec.name = 'rack-archive-zip-extract'
  spec.version = '0.0.1'
  spec.summary = 'Zip file server'
  spec.description = 'Rack::Archive::Zip::Extract serves files in zip archives.'
  spec.authors = ['KITAITI Makoto']
  spec.email = 'KitaitiMakoto@gmail.com'
  spec.required_ruby_version = '>= 2.0.0'
  spec.files = ['lib/rack/archive/zip/extract.rb']
  spec.homepage = 'https://github.com/KitaitiMakoto/rack-archive-zip-extract'
  spec.license = 'MIT'

  spec.add_runtime_dependency 'rack', '~> 1'
  spec.add_runtime_dependency 'zipruby', '~> 0.3'

  spec.add_development_dependency 'test-unit', '~> 1'
  spec.add_development_dependency 'test-unit-notify', '~> 1'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'rubygems-tasks', '~> 0.2'
end
