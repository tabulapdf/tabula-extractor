#!/usr/bin/env rake
require 'bundler'
require 'rake'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

task :test do
  Rake::TestTask.new do |t|
    t.test_files = Dir.glob('test/*.rb')
    t.verbose = true
  end
end
