# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-pt/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-pt'
  spec.version       = CocoapodsPt::VERSION
  spec.authors       = ['nidong']
  spec.email         = ['nidong@baidu.com']
  spec.description   = %q{A short description of cocoapods-pt.}
  spec.summary       = %q{A longer description of cocoapods-pt.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-pt'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
