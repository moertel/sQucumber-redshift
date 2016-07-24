require 'cucumber'
require 'cucumber/rake/task'
require 'rake'

module Squcumber
  module Redshift
    module Rake
      class Task
        include ::Rake::DSL if defined? ::Rake::DSL

        def install_tasks
          namespace :test do
            # Auto-generate Rake tasks for each feature and each of their parent directories
            @features_dir = File.join(FileUtils.pwd, 'features')
            features = Dir.glob("#{@features_dir}/**/*.feature")
            parent_directories = features.map { |f| f.split('/')[0..-2].join('/') }.uniq

            features.each do |feature|
              feature_name = feature.gsub(File.join(FileUtils.pwd, 'features/'), '').gsub('.feature', '')
              task_name = feature_name.gsub('/', ':')
              desc "Run SQL tests for feature #{feature_name}"
              task "sql:#{task_name}".to_sym, [:scenario_line_number] do |_, args|
                cucumber_task_name = "cucumber_#{task_name}".to_sym
                ::Cucumber::Rake::Task.new(cucumber_task_name) do |t|
                  line_number = args[:scenario_line_number].nil? ? '' : ":#{args[:scenario_line_number]}"
                  t.cucumber_opts = "#{feature}#{line_number} --format pretty --format html --out #{feature_name.gsub('/','_')}.html --require #{File.dirname(__FILE__)}/../support --require #{File.dirname(__FILE__)}/../step_definitions"
                end
                ::Rake::Task[cucumber_task_name].execute
              end
            end

            parent_directories.each do |feature|
              feature_name = feature.gsub(File.join(FileUtils.pwd, 'features/'), '').gsub('.feature', '')
              task_name = feature_name.gsub('/', ':')
              desc "Run SQL tests for all features in #{feature_name}"
              task "sql:#{task_name}".to_sym do
                cucumber_task_name = "cucumber_#{task_name}".to_sym
                ::Cucumber::Rake::Task.new(cucumber_task_name) do |t|
                  t.cucumber_opts = "#{feature} --format pretty --format html --out #{feature_name.gsub('/','_')}.html --require #{File.dirname(__FILE__)}/../support --require #{File.dirname(__FILE__)}/../step_definitions"
                end
                ::Rake::Task[cucumber_task_name].execute
              end
            end
          end
        end
      end
    end
  end
end

Squcumber::Redshift::Rake::Task.new.install_tasks
