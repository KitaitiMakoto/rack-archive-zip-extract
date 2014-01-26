Gem::Specification.new do |spec|
  spec.name = 'rack-archive-zip-extract'
  spec.version = '0.0.4'
  spec.summary = 'Zip file server'
  spec.description = 'Rack::Archive::Zip::Extract serves files in zip archives.'
  spec.authors = ['KITAITI Makoto']
  spec.email = 'KitaitiMakoto@gmail.com'
  spec.required_ruby_version = '>= 2.0.0'
  spec.files = %w[
    lib/rack/archive/zip/extract.rb
    Rakefile
  ]
  spec.extra_rdoc_files = %w[
    README.markdown
    MIT-LICENSE
    CHANGELOG.markdown
  ]
  spec.test_files = %w[
    test/test_rack-archive-zip-extract.rb
    test/fixtures/sample-ext/sample.txt
    test/fixtures/sample-zip/sample.html
    test/fixtures/sample-zip/sample.txt
    test/fixtures/sample-zip/sample.xml
    test/fixtures/sample-zip/subdir/sample.txt
  ]
  spec.homepage = 'https://github.com/KitaitiMakoto/rack-archive-zip-extract'
  spec.license = 'MIT'

  spec.add_runtime_dependency 'rack', '~> 1'
  spec.add_runtime_dependency 'zipruby', '~> 0.3'

  spec.add_development_dependency 'test-unit', '~> 1'
  spec.add_development_dependency 'test-unit-notify', '~> 1'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'rubygems-tasks', '~> 0.2'
end
