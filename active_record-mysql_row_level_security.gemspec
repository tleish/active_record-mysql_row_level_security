
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/mysql_row_level_security/version"

Gem::Specification.new do |spec|
  spec.name          = "active_record-mysql_row_level_security"
  spec.version       = ActiveRecord::MysqlRowLevelSecurity::VERSION
  spec.authors       = ["tleish"]
  spec.email         = ["tleish@hotmail.com"]

  spec.summary       = %q{MySQL Row Security for ActiveRecord.}
  spec.description   = %q{MySQL Row Security for ActiveRecord using MySQL views and MySQL variables.}
  spec.homepage      = "https://github.com/tleish/active_record-mysql_row_level_security"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = 'http://mygemserver.com'

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = 'https://github.com/tleish/active_record-mysql_row_level_security'
    spec.metadata["changelog_uri"] = 'https://github.com/tleish/active_record-mysql_row_level_security'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", "> 4.0"
  spec.add_runtime_dependency "parslet", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.3"
  spec.add_development_dependency "ruby-prof-flamegraph"
  spec.add_development_dependency "simplecov"
end
