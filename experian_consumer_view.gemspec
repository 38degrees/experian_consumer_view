# frozen_string_literal: true

require_relative 'lib/experian_consumer_view/version'

Gem::Specification.new do |spec|
  spec.name          = 'experian_consumer_view'
  spec.version       = ExperianConsumerView::VERSION
  spec.authors       = ['Andrew Sibley']
  spec.email         = ['andrew.s@38degrees.org.uk']
  spec.license       = 'MIT'
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.summary       = "Ruby wrapper for Experian's ConsumerView API."
  spec.description   = "
    Experian's ConsumerView API is a commercially licensed API which allows you
    to obtain various demographic data on UK consumers at the postcode, household,
    and individual level. This gem provides a simple Ruby wrapper to use the API.
  "

  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 5.2'
  spec.add_dependency 'faraday', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'codecov', '>= 0.2'
  spec.add_development_dependency 'pry', '>= 0.12'
  spec.add_development_dependency 'rake', '>= 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.91.0'
  spec.add_development_dependency 'webmock', '~> 3.9'
  spec.add_development_dependency 'yard', '~> 0.9.25'
end
