require 'rake/clean'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |test|
  test.options = '--no-show-detail-immediately --verbose'
end

namespace :test do
  desc 'Build test fixtures'
  task :build do
    sh 'cd test/fixtures/sample-zip && zip -r ../../sample.zip .'
    sh 'cd test/fixtures/sample-ext && zip -r ../../sample.ext .'
  end
end

task :test => [:clean, 'test:build']
