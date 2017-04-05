require 'pg'

module Squcumber
  module Redshift
    module Mock
      class Database
        DELETE_DB_WHEN_FINISHED = ENV['KEEP_TEST_DB'].to_i == 1 ? false : true
        TEST_DB_NAME_OVERRIDE = ENV.fetch('TEST_DB_NAME_OVERRIDE', '')

        def initialize(production_database)
          @production_database = production_database or raise ArgumentError, 'No production database provided'

          test_db_name_postfix = TEST_DB_NAME_OVERRIDE.empty? ? rand(10000..99999) : TEST_DB_NAME_OVERRIDE
          @test_db_name = "test_env_#{test_db_name_postfix}"

          if @production_database.exec("select datname from pg_database where datname like '%#{@test_db_name}%'").num_tuples != 0
            @production_database.exec("drop database #{@test_db_name}")
          end
          @production_database.exec("create database #{@test_db_name}")

          @testing_database = PG.connect(
            host: ENV['REDSHIFT_HOST'],
            port: ENV['REDSHIFT_PORT'],
            dbname: @test_db_name,
            user: ENV['REDSHIFT_USER'],
            password: ENV['REDSHIFT_PASSWORD']
          )
        end

        def setup(schemas)
          schemas.each do |schema|
            exec("drop schema if exists #{schema} cascade")
            exec("create schema #{schema}")
          end
        end

        def truncate_all_tables
          @testing_database
            .exec("select schemaname || '.' || tablename as schema_and_table from pg_tables where tableowner = '#{ENV['REDSHIFT_USER']}'")
            .map { |row| row['schema_and_table'] }
            .each { |schema_and_table| exec("truncate table #{schema_and_table}") }
        end

        def exec(statement)
          @testing_database.exec(statement)
        end
        alias_method :query, :exec

        def exec_file(path)
          exec(File.read("#{path}"))
        end
        alias_method :query_file, :exec_file

        # Redshift does not allow to copy a table schema to another database, i.e.
        # `create table some_db.some_table (like another_db.some_table)` cannot be used.
        def copy_table_def_from_prod(schema, table)
          create_table_statement = _get_create_table_statement(schema, table)
          exec(create_table_statement)
        end

        def copy_table_defs_from_prod(tables)
          tables.each do |obj|
            obj.each { |schema, table| copy_table_def_from_prod(schema, table) }
          end
        end

        def mock(mock)
          mock.each do |schema_and_table, data|
            raise "Mock data for #{schema_and_table} is not correctly formatted: must be Array but was #{data.class}" unless data.is_a?(Array)
            data.each { |datum| insert_mock_values(schema_and_table, datum) }
          end
        end

        def insert_mock_values(schema_and_table, mock)
          schema, table = schema_and_table.split('.')
          keys = []
          vals = []
          mock.each do |key, value|
            unless value.nil?
              keys << key
              vals << (value.is_a?(String) ? "'#{value}'" : value)
            end
          end
          exec("insert into #{schema}.#{table} (#{keys.join(',')}) values (#{vals.join(',')})") unless vals.empty?
        end

        def destroy
          @testing_database.close()

          if DELETE_DB_WHEN_FINISHED
            attempts = 0
            begin
              attempts += 1
              @production_database.exec("drop database #{@test_db_name}")
            rescue PG::ObjectInUse
              sleep 5
              retry unless attempts >= 3
            end
          else
            puts "\nTest database has been kept alive: #{@test_db_name}"
          end

          @production_database.close()
        end

        private

        def _get_create_table_statement(schema, table)
          @production_database.exec("set search_path to '$user', #{schema};")
          table_schema = @production_database.query("select column_name, data_type, character_maximum_length from INFORMATION_SCHEMA.COLUMNS where table_schema = '#{schema}' and table_name = '#{table}';")

          raise "Sorry, there is no table information for #{schema}.#{table}" if table_schema.num_tuples == 0

          distkey = _get_table_distkey(table_schema)
          sortkeys = _get_table_sortkeys(table_schema).join(',')
          definitions = _get_column_definitions(table_schema).join(',')

          table_distkey  = "distkey(#{distkey})"            unless distkey.nil?
          table_sortkeys = "sortkey(#{sortkeys})" unless sortkeys.empty?

          "create table if not exists #{schema}.#{table} (#{definitions}) #{table_distkey} #{table_sortkeys};"
        end

        def _get_table_distkey(table_definition)
          table_definition.select { |definition| definition['distkey'].eql?('t') }[0]['column_name'] rescue nil
        end

        def _get_table_sortkeys(table_definition)
          table_definition.sort_by { |e| e['sortkey'].to_i }.select { |e| e['sortkey'].to_i != 0 }.map { |e| e['column_name'] } rescue nil
        end

        def _get_column_definitions(table_definition)
          table_definition.map { |definition| "#{definition['column_name']} #{definition['data_type']} default null" }
        end
      end
    end
  end
end
