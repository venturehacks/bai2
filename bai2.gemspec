# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bai2/version'

Gem::Specification.new do |spec|
  spec.name          = 'bai2'
  spec.version       = Bai2::VERSION
  spec.authors       = ['Kenneth Ballenegger']
  spec.email         = ['kenneth@ballenegger.com']
  spec.summary       = %q{Parse BAI2 files.}
  spec.description   = %q{Parse BAI2 files.}
  spec.homepage      = 'https://github/venturehacks/bai2_file'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',  '~> 1.7'
  spec.add_development_dependency 'rake',     '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.5'
  spec.add_development_dependency 'minitest-reporters', '~> 1.0'
end
