require 'rake/clean'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new

namespace :test do
  desc 'Build test fixtures'
  task :build do
    sh 'zip -rj test/fixtures.zip test/fixtures'
  end
end

task :test => [:clean, 'test:build']
