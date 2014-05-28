#!/usr/bin/env rake
require 'bundler'
require 'rake'

Bundler::GemHelper.install_tasks

task :test do
  ruby %{-X+C -J-Xmx512m test/tests.rb}
end

task :compile do
  Dir.chdir(File.join(File.dirname(__FILE__), 'ext/tabula')) do
    system("mvn", "clean",  "compile", "assembly:single", out: $stdout, err: $stderr)
  end
end

task :default => [:test]
