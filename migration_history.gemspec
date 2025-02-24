# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "migration_history/version"

Gem::Specification.new do |spec|
  spec.name          = "migration_history"
  spec.version       = MigrationHistory::VERSION
  spec.authors       = ["a5-stable"]
  spec.email         = ["sh07e1916@gmail.com"]

  spec.summary       = "A Gem to track and collect migration history in Rails projects, including when tables and columns were added, with details available in various formats"
  spec.description   = "Track and collect detailed migration history in Rails, including table/column changes, with flexible output formats such as HTML, CLI, and more."
  spec.homepage      = "https://github.com/a5-stable"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/a5-stable/migration_history"
    spec.metadata["changelog_uri"] = "https://github.com/a5-stable/migration_history"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.2"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "thor", "~> 1.0"
end
