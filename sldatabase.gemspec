# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sldatabase/version'

Gem::Specification.new do |spec|
  spec.name          = "sldatabase"
  spec.version       = SLDatabase::VERSION
  spec.authors       = ["Cyril Bourgès"]
  spec.email         = ["cyril@tapastreet.com", "bourges.c@gmail.com"]
  spec.summary       = %q{Multiple Database Manager}
  spec.description   = %q{Multiple Database Manager Manager \n
                          Support : 
                            Postgresql with\n
                            - pg, platform: ruby\n
                            - pg_jruby, platform: ruby\n
                            Orientdb with\n
                            - joriendb, platform: ruby & jruby\n}
  spec.homepage      = "https://github.com/Sluz/SLDatabase.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.7', '>= 1.7.0'
  spec.add_development_dependency 'rake', '~> 10.0', '>= 10.0.0'
  spec.add_dependency 'multi_json', '~> 1.0', ">= 1"
  spec.add_dependency 'jorientdb', '~> 2.0', ">= 2.0.6"
end
