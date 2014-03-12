# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pogoplug/version'

Gem::Specification.new do |spec|
  spec.name          = "pogoplug"
  spec.version       = PogoPlug::VERSION
  spec.authors       = ["Travis Truman"]
  spec.license       = "MIT"
  spec.homepage = "http://github.com/trumant/pogoplug"
  spec.licenses = ["MIT"]
  spec.summary = "A Ruby wrapper around the PogoPlug API"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 0.8.9"
  spec.add_dependency "faraday_middleware"
  spec.add_dependency "faraday_curl"

  spec.add_development_dependency "bundler", "~> 1.5"

  ['rake', 'rspec', 'shoulda', 'guard-rspec', 'guard-bundler'].each do |dep|
    spec.add_development_dependency dep
  end
end
