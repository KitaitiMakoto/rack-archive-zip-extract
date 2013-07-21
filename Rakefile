require 'rake/clean'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new

namespace :test do
  desc 'Build test fixtures'
  task :build do
    sh 'zip -rj test/sample.zip test/fixtures/sample-zip'
  end
end

task :test => [:clean, 'test:build']
