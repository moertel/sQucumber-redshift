Gem::Specification.new do |s|
  s.name               = 'squcumber-redshift'
  s.version            = '0.1.4'
  s.default_executable = 'squcumber-redshift'

  s.licenses = ['MIT']
  s.required_ruby_version = '>= 2.0'
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Stefanie Grunwald']
  s.date = %q{2016-07-01}
  s.email = %q{steffi@physics.org}
  s.files = [
    'Rakefile',
    'lib/squcumber-redshift.rb',
    'lib/squcumber-redshift/mock/database.rb',
    'lib/squcumber-redshift/step_definitions/common_steps.rb',
    'lib/squcumber-redshift/support/database.rb',
    'lib/squcumber-redshift/support/matchers.rb',
    'lib/squcumber-redshift/support/output.rb',
    'lib/squcumber-redshift/rake/task.rb'
  ]
  s.test_files = [
    'spec/spec_helper.rb',
    'spec/squcumber-redshift/mock/database_spec.rb'
  ]
  s.homepage = %q{https://github.com/moertel/sQucumber-redshift}
  s.require_paths = ['lib']
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Define and execute SQL integration tests for AWS Redshift}

  s.add_runtime_dependency 'pg', ['>= 0.16', '< 1.0']
  s.add_runtime_dependency 'cucumber', ['>= 2.0', '< 3.0']
  s.add_runtime_dependency 'rake', ['>= 10.1', '< 13.0']

  s.add_development_dependency 'rspec', ['>= 3.1', '< 4.0']
  s.add_development_dependency 'rspec-collection_matchers', ['>= 1.1.2', '< 2.0']
  s.add_development_dependency 'codeclimate-test-reporter', ['>= 0.4.3', '< 1.0']

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.0.0') then
    else
    end
  else
  end
end
