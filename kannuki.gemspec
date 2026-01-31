# frozen_string_literal: true

require_relative 'lib/kannuki/version'

Gem::Specification.new do |spec|
  spec.name = 'kannuki'
  spec.version = Kannuki::VERSION
  spec.authors = ['Yudai Takada']
  spec.email = ['t.yudai92@gmail.com']

  spec.summary = 'Advisory locking for ActiveRecord with modern Rails conventions'
  spec.description = 'Kannuki provides database-agnostic advisory locking for ActiveRecord ' \
                     'with support for PostgreSQL and MySQL, offering blocking/non-blocking ' \
                     'strategies, instrumentation, and ActiveJob integration.'
  spec.homepage = 'https://github.com/ydah/kannuki'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 7.0'
  spec.add_dependency 'activesupport', '>= 7.0'
end
