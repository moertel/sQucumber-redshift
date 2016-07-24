# encoding: utf-8

require 'rspec/collection_matchers'
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

RSpec.configure do |config|
  config.color = true

  # Redirect stderr and stdout to get rid of info messages during execution
  # of specs.
  # Via http://stackoverflow.com/questions/15430551/suppress-console-output-during-rspec-tests
  unless ENV['SPEC_SHOW_STDOUT'] == '1'
    original_stderr = $stderr
    original_stdout = $stdout
    config.before(:all) do
      $stderr = File.new('/dev/null', 'w')
      $stdout = File.new('/dev/null', 'w')
    end
    config.after(:all) do
      $stderr = original_stderr
      $stdout = original_stdout
    end
  end
end

# Via https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-examples
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
