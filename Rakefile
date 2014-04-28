#!/usr/bin/env rake
require 'bundler'
require 'rake'
require 'rake/javaextensiontask'

Bundler::GemHelper.install_tasks

task :test do
  ruby %{-X+C -J-Xmx512m test/tests.rb}
end

Rake::JavaExtensionTask.new('tabula') do |ext|
  jars = FileList['lib/jar/*.jar']
  ext.classpath = jars.map { |x| File.expand_path(x) }.join(':')
  ext.name = 'tabula-extractor'
  ext.lib_dir = 'lib/jar'
end

task :default => [:test]
