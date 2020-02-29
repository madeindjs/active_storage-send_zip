# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_storage/send_zip/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_storage-send_zip'
  spec.version       = ActiveStorage::SendZip::VERSION
  spec.authors       = ['Alexandre Rousseau']
  spec.email         = ['contact@rousseau-alexandre.fr']

  spec.summary       = 'Create a zip from one or more Active Storage objects'
  spec.description   = 'Add a `send_zip` method in your Rails controller to send a `.zip` file containing one (or many) ActiveStorage object(s)'
  spec.homepage      = 'https://github.com/madeindjs/active_storage-send_zip'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/madeindjs/active_storage-send_zip'
    # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_dependency 'rails', '> 5.2'
  spec.add_dependency 'rubyzip', '< 3.0'
end
