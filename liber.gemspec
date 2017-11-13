# coding: utf-8
source = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(source) unless $LOAD_PATH.include?(source)
require 'Liber/version'

Gem::Specification.new do |spec|
  spec.name          = 'liber'
  spec.version       = Liber::VERSION
  spec.authors       = ['Flavio Heleno']
  spec.email         = ['flavio@libercapital.com.br']
  spec.summary       = %q{Write a short summary. Required.}
  spec.description   = %q{Write a longer description. Optional.}
  spec.homepage      = 'https://www.libercapital.com.br/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'rest-client', '~> 2.0'
  spec.add_dependency 'multi_json', '~> 1.12'
end
