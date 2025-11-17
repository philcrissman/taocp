require_relative "lib/taocp/version"

Gem::Specification.new do |spec|
  spec.name          = "taocp"
  spec.version       = Taocp::VERSION
  spec.authors       = ["Phil Crissman"]
  spec.email         = ["phil@example.com"]

  spec.summary       = "MIX/MIXAL interpreter from Knuth's TAOCP"
  spec.description   = "A complete implementation of Donald Knuth's MIX computer and MIXAL assembly language from The Art of Computer Programming (TAOCP)"
  spec.homepage      = "https://github.com/philcrissman/quack"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/philcrissman/quack"
  spec.metadata["changelog_uri"] = "https://github.com/philcrissman/quack/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
