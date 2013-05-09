# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require 'tabula/version'


Gem::Specification.new do |s|
  s.name        = "tabula-extractor"
  s.version     = Tabula::VERSION
  s.authors     = ["Manuel Aristarán"]
  s.email       = ["manuel@jazzido.com"]
  s.homepage    = "https://github.com/jazzido/tabula-extractor"
  s.summary     = %q{extract tables from PDF files}
  s.description = %q{extract tables from PDF files}

  s.platform = 'java'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'minitest'
  s.add_runtime_dependency "trollop", ["~> 2.0"]
end
