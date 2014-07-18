# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tsdatabase/version'

Gem::Specification.new do |spec|
  spec.name          = "tsdatabase"
  spec.version       = Tsdatabase::VERSION
  spec.authors       = ["Cyril"]
  spec.email         = ["cyril@tapastreet.com"]
  spec.summary       = %q{Database Manager\n Required: Postgresql:\n- pg, platform: ruby\n- pg_jruby, platform: ruby\n- orientdb4r, platform: ruby\n- oriendb, platform: jruby\n}
  spec.description   = %q{Database Manager}
  spec.homepage      = ""
  spec.license       = "Tapastreet ltd Copyright © All Rights Reserved"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "multi_json", ">= 1"
end
