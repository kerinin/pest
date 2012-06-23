# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pest/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ryan Michael", "Ben Hamill"]
  gem.email         = ["git-commits@benhamill.com"]
  gem.description   = %q{Email clients are not web browsers. They render html all funny, to put it politely. In general, the best practices for writing HTML that will look good in an email are the exact inverse from those that you should use for a web page. Remembering all those differences sucks.}
  gem.summary       = %q{Never type all the annoying markup that emails demand again.}
  gem.homepage      = "http://github.com/otherinbox/pest"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pest"
  gem.require_paths = ["lib"]
  gem.version       = Pest::VERSION

  gem.add_dependency 'narray'
  gem.add_dependency 'uuidtools'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rspec'
end
