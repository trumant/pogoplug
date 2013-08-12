# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pogoplug/version'

Gem::Specification.new do |spec|
  spec.name          = "pogoplug"
  spec.version       = PogoPlug::VERSION
  spec.authors       = ["Travis Truman"]
  spec.email         = ["trumant@gmail.com"]
  spec.description   = %q{Client for the PogoPlug API}
  spec.summary       = spec.description
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "jeweler", "~> 1.8.4"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rdoc", "~> 3.12"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-test"
  spec.add_development_dependency "ruby_gntp"


  spec.add_dependency 'httparty'
end
