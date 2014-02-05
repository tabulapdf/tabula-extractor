#!/usr/bin/env rake
require 'bundler'
require 'rake'
#require 'rake/testtask'

Bundler::GemHelper.install_tasks

task :test do
  ruby %{-X+C -J-Xmx512m test/tests.rb}
end

task :default => [:test]
