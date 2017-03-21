# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sensu-extensions-statsd"
  spec.version       = "0.0.1"
  spec.authors       = ["Sensu-Extensions and contributors"]
  spec.email         = ["<sensu-users@googlegroups.com>"]

  spec.summary       = "Check extension to run a StatsD implementation"
  spec.description   = "Check extension to run a StatsD implementation"
  spec.homepage      = "https://github.com/sensu-extensions/sensu-extensions-statsd"

  spec.files         = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md)
  spec.require_paths = ["lib"]

  spec.add_dependency "sensu-extension"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sensu-logger"
  spec.add_development_dependency "sensu-settings"
  spec.add_development_dependency "github_changelog_generator"
end
