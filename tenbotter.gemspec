# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "tenbotter"
  spec.version = "1.0.0"
  spec.authors = ["Joel Warrington"]
  spec.required_ruby_version = ">= 2.6.0"
  spec.summary = "A Discord bot for managing and starting CSGO matches with friends."

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
