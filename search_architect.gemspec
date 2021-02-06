require_relative 'lib/search_architect/version'

Gem::Specification.new do |s|
  s.name          = "search_architect"
  s.version       = SearchArchitect::VERSION
  s.authors       = ["Weston Ganger"]
  s.email         = ["weston@westonganger.com"]

  s.summary       = "Dead simple, fully customizable searching for your ActiveRecord models and associations."
  s.description   = s.summary
  s.homepage      = "https://github.com/westonganger/search_architect"
  s.license       = "MIT"

  s.metadata["source_code_uri"] = s.homepage
  s.metadata["changelog_uri"] = File.join(s.homepage, "blob/master/CHANGELOG.md")

  s.files = Dir.glob("{lib/**/*}") + %w{ LICENSE README.md Rakefile CHANGELOG.md }
  s.test_files  = Dir.glob("{test/**/*}")
  s.require_path = 'lib'

  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  s.add_runtime_dependency "activerecord"
  s.add_runtime_dependency "railties"

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-reporters"

  if RUBY_VERSION.to_f >= 2.4
    s.add_development_dependency "warning"
  end

end
