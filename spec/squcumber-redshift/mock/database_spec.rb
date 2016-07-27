require_relative '../../spec_helper'
require_relative '../../../lib/squcumber-redshift/mock/database'

module Squcumber::Redshift::Mock
  describe Database do
    let(:production_database) { double(PG::Connection) }
    let(:testing_database)    { double(PG::Connection) }

    let(:empty_result)     { double(PG::Result) }
    let(:non_empty_result) { double(PG::Result) }

    before(:each) do
      allow(ENV).to receive(:[]).with('REDSHIFT_HOST').and_return('some.db.host')
      allow(ENV).to receive(:[]).with('REDSHIFT_PORT').and_return(1234)
      allow(ENV).to receive(:[]).with('REDSHIFT_USER').and_return('some_user')
      allow(ENV).to receive(:[]).with('REDSHIFT_PASSWORD').and_return('s0m3_p4ssw0rd')
      allow(ENV).to receive(:[]).with('REDSHIFT_DB').and_return('some_db')

      allow(PG).to receive(:connect).and_return(testing_database)
      allow(production_database).to receive(:exec).with(/^\s*create\s+database\s+/)
      allow(production_database).to receive(:exec).with(/^\s*select\s+datname\s+from\s+pg_database\s+/).and_return(empty_result)
      allow(production_database).to receive(:exec).with(/^\s*set\s+search_path\s+to\s+/)
      allow(production_database).to receive(:exec).with(/^\s*drop\s+database\s+/)
      allow(testing_database).to receive(:exec)

      allow(empty_result).to receive(:num_tuples).and_return(0)
      allow(non_empty_result).to receive(:num_tuples).and_return(1)
    end

    describe '#initialize' do
      context 'when all arguments are provided' do
        context 'and the database does not exist' do
          it 'does not raise an error' do
            expect { described_class.new(production_database) }.to_not raise_error
          end

          it 'generates a testing database name with expected pattern' do
            dummy = described_class.new(production_database)
            expect(dummy.instance_variable_get(:@test_db_name)).to match(/^test_env_\d{5}$/)
          end

          it 'does not try to drop the database' do
            described_class.new(production_database)
            expect(production_database).to_not have_received(:exec).with(/^drop\s+database\s+/)
          end

          it 'creates the testing database' do
            dummy = described_class.new(production_database)
            test_db_name = dummy.instance_variable_get(:@test_db_name)
            expect(production_database).to have_received(:exec).with(/^\s*create\s+database\s+#{Regexp.quote(test_db_name)}\s*;?\s*$/)
          end

          it 'connects to testing database in correct order with correct attributes' do
            dummy = described_class.new(production_database)

            test_db_name = dummy.instance_variable_get(:@test_db_name)
            expect(production_database).to have_received(:exec).with(/^\s*create\s+database\s+#{Regexp.quote(test_db_name)}\s*;?\s*$/).ordered

            expect(PG).to have_received(:connect).with(
              host: 'some.db.host',
              port: 1234,
              dbname: test_db_name,
              user: 'some_user',
              password: 's0m3_p4ssw0rd'
            ).ordered
          end
        end

        context 'and the database name is being overridden' do
          let(:testing_db_name) { 'some_db_name' }

          before(:each) do
            stub_const("#{described_class}::TEST_DB_NAME_OVERRIDE", testing_db_name)
          end

          it 'does not raise an error' do
            expect { described_class.new(production_database) }.to_not raise_error
          end

          it 'generates a testing database name with expected pattern' do
            dummy = described_class.new(production_database)
            expect(dummy.instance_variable_get(:@test_db_name)).to match(/^test_env_#{Regexp.quote(testing_db_name)}$/)
          end

          it 'does not try to drop the database' do
            described_class.new(production_database)
            expect(production_database).to_not have_received(:exec).with(/^drop\s+database\s+/)
          end

          it 'creates the testing database' do
            described_class.new(production_database)
            expect(production_database).to have_received(:exec).with(/^\s*create\s+database\s+test_env\_#{Regexp.quote(testing_db_name)}\s*;?\s*$/)
          end

          it 'connects to testing database in correct order with correct attributes' do
            described_class.new(production_database)
            expect(production_database).to have_received(:exec).with(/^\s*create\s+database\s+test_env_#{Regexp.quote(testing_db_name)}\s*;?\s*$/).ordered

            expect(PG).to have_received(:connect).with(
              host: 'some.db.host',
              port: 1234,
              dbname: 'test_env_' + testing_db_name,
              user: 'some_user',
              password: 's0m3_p4ssw0rd'
            ).ordered
          end
        end

        context 'and the database already exists' do
          before(:each) do
            allow(production_database).to receive(:exec).with(/^select\s+datname\s+from\s+pg_database\s+/).and_return(non_empty_result)
          end

          it 'does not raise an error' do
            expect { described_class.new(production_database) }.to_not raise_error
          end

          it 'generates a testing database name with expected pattern' do
            dummy = described_class.new(production_database)
            expect(dummy.instance_variable_get(:@test_db_name)).to match(/^test_env_\d{5}$/)
          end

          it 'drops the existing testing database' do
            described_class.new(production_database)
            expect(production_database).to have_received(:exec).with(/^drop\s+database\s+/)
          end

          it 'creates the testing database' do
            dummy = described_class.new(production_database)
            test_db_name = dummy.instance_variable_get(:@test_db_name)
            expect(production_database).to have_received(:exec).with(/^\s*create\s+database\s+#{Regexp.quote(test_db_name)}\s*;?\s*$/)
          end

          it 'connects to testing database in correct order with correct attributes' do
            dummy = described_class.new(production_database)

            test_db_name = dummy.instance_variable_get(:@test_db_name)
            expect(production_database).to have_received(:exec).with(/^\s*create\s+database\s+#{Regexp.quote(test_db_name)}\s*;?\s*$/).ordered

            expect(PG).to have_received(:connect).with(
              host: 'some.db.host',
              port: 1234,
              dbname: test_db_name,
              user: 'some_user',
              password: 's0m3_p4ssw0rd'
            ).ordered
          end
        end
      end

      context 'when some arguments are missing' do
        it 'raises an error when production database is not provided' do
          expect { described_class.new(nil) }.to raise_error(ArgumentError, 'No production database provided')
        end
      end
    end

    describe '#setup' do
      let(:schemas) { ['some_schema', 'another_schema'] }

      before(:each) do
        @dummy = described_class.new(production_database)
        allow(@dummy).to receive(:exec)
        @dummy.setup(schemas)
      end

      it 'drops and creates all schemas' do
        expect(@dummy).to have_received(:exec).with('drop schema if exists some_schema cascade').ordered
        expect(@dummy).to have_received(:exec).with('create schema some_schema').ordered
        expect(@dummy).to have_received(:exec).with('drop schema if exists another_schema cascade').ordered
        expect(@dummy).to have_received(:exec).with('create schema another_schema').ordered
      end
    end

    describe '#truncate_all_tables' do
      let(:existing_tables) { ['some_schema.some_table', 'some_other_schema.some_other_table'] }

      before(:each) do
        allow(testing_database).to receive_message_chain(:exec, :map).and_return(existing_tables)
        @dummy = described_class.new(production_database)
        @dummy.truncate_all_tables()
      end

      it 'asks the testing database for currently existing tables in production schemas' do
        expect(testing_database).to have_received(:exec).with(/^\s*select\s+schemaname\s+\|\|\s+'\.'\s+\|\|\s+tablename\s+as schema\_and\_table\s+from\s+pg_tables\s+where\s+tableowner\s*=\s*'some_user'\s*;?\s*$/)
      end

      it 'truncates the returned tables in the testing database' do
        expect(testing_database).to have_received(:exec).with(/^\s*select\s+/).ordered
        expect(testing_database).to have_received(:exec).with(/^\s*truncate\s+table\s+some\_schema\.some\_table\s*;?\s*$/).ordered
        expect(testing_database).to have_received(:exec).with(/^\s*truncate\s+table\s+some\_other\_schema\.some\_other\_table\s*;?\s*$/).ordered
      end

      it 'does not truncate anything in the production database' do
        expect(production_database).to_not have_received(:exec).with(/truncate/)
      end
    end

    describe '#exec' do
      let(:some_statement) { 'some statement' }

      before(:each) do
        @dummy = described_class.new(production_database)
      end

      it 'executes the passed statement on the testing database' do
        @dummy.exec(some_statement)
        expect(testing_database).to have_received(:exec).with(some_statement)
      end

      it 'does not execute the passed statement on the production database' do
        @dummy.exec(some_statement)
        expect(production_database).to_not have_received(:exec).with(some_statement)
      end

      it 'sets an alias for \'query\'' do
        expect(@dummy).to respond_to(:query)
        @dummy.query(some_statement)
        expect(testing_database).to have_received(:exec).with(some_statement)
      end
    end

    describe '#exec_file' do
      let(:some_file_path) { 'some/file/path' }
      let(:some_file_content) { 'some file content' }

      before(:each) do
        allow(File).to receive(:read).with(some_file_path).and_return(some_file_content)
        @dummy = described_class.new(production_database)
      end

      it 'reads the statement from the path provided, relative to root' do
        @dummy.exec_file(some_file_path)
        expect(File).to have_received(:read).with(some_file_path)
      end

      it 'executes the file content on the testing database' do
        @dummy.exec_file(some_file_path)
        expect(testing_database).to have_received(:exec).with(some_file_content)
      end

      it 'does not execute file content on the production database' do
        @dummy.exec_file(some_file_path)
        expect(production_database).to_not have_received(:exec).with(some_file_content)
      end

      it 'sets an alias for \'query_file\'' do
        expect(@dummy).to respond_to(:query_file)
        @dummy.query_file(some_file_path)
        expect(testing_database).to have_received(:exec).with(some_file_content)
      end
    end

    describe '#insert_mock_values' do
      let(:table) { 'some_schema.some_table' }
      let(:mock) do
        {
          'some_column' => 'some_value',
          'some_other_column' => 1234
        }
      end

      before(:each) do
        @dummy = described_class.new(production_database)
        @dummy.insert_mock_values(table, mock)
      end

      it 'transforms a given hash to an \'insert\' statement' do
        expect(testing_database).to have_received(:exec).with(/^\s*insert\s+into\s+some\_schema\.some\_table\s+\(some\_column,some\_other\_column\)\s+values\s*\('some\_value',1234\)\s*;?\s*$/)
      end

      it 'does not try to insert anything into a production table' do
        expect(production_database).to_not have_received(:exec).with(/insert/)
      end
    end

    describe '#mock' do
      let(:mock) do
        {
          'some_schema.some_table' => [
            { 'some_column' => 'some_value', 'some_other_column' => 'some_other_value' },
            { 'some_column' => 'another_value', 'some_other_column' => 'yet_another_value' }
          ],
          'some_other_schema.some_other_table' => [
            { 'another_column' => 'some_value' }
          ]
        }
      end

      before(:each) do
        @dummy = described_class.new(production_database)
        allow(@dummy).to receive(:insert_mock_values)
        @dummy.mock(mock)
      end

      it 'inserts the mock values' do
        expect(@dummy).to have_received(:insert_mock_values).with('some_schema.some_table', { 'some_column' => 'some_value', 'some_other_column' => 'some_other_value' }).ordered
        expect(@dummy).to have_received(:insert_mock_values).with('some_schema.some_table', { 'some_column' => 'another_value', 'some_other_column' => 'yet_another_value' }).ordered
        expect(@dummy).to have_received(:insert_mock_values).with('some_other_schema.some_other_table', { 'another_column' => 'some_value'}).ordered
      end
    end

    describe '#copy_table_defs_from_prod' do
      let(:tables) { [{'some_schema' => 'some_table'}, {'some_other_schema' => 'some_other_table'}] }

      before(:each) do
        @dummy = described_class.new(production_database)
        allow(@dummy).to receive(:copy_table_def_from_prod)
        @dummy.copy_table_defs_from_prod(tables)
      end

      it 'triggers copies the individual table definitions from production' do
        expect(@dummy).to have_received(:copy_table_def_from_prod).with('some_schema', 'some_table').ordered
        expect(@dummy).to have_received(:copy_table_def_from_prod).with('some_other_schema', 'some_other_table').ordered
      end
    end

    describe '#copy_table_def_from_prod' do
      let(:schema) { 'some_schema' }
      let(:table) { 'some_table' }
      let(:some_table_definition) { 'some table definition' }

      before(:each) do
        @dummy = described_class.new(production_database)
        allow(@dummy).to receive(:_get_create_table_statement).and_return(some_table_definition)
        @dummy.copy_table_def_from_prod(schema, table)
      end

      it 'retrieves the table definition' do
        expect(@dummy).to have_received(:_get_create_table_statement).with(schema, table)
      end

      it 'executes the retrieved table definition on the testing database' do
        expect(testing_database).to have_received(:exec).with(some_table_definition)
      end
    end

    describe '#_get_create_table_statement' do
      let(:schema) { 'some_schema' }
      let(:table) { 'some_table' }
      let(:table_definition) do
        [
          {'schemaname' => 'some_schema', 'tablename' => 'some_table', 'column' => 'some_column',        'type' => 'integer',                'encoding' => 'none', 'distkey' => 't', 'sortkey' => 1, 'notnull' => 't'},
          {'schemaname' => 'some_schema', 'tablename' => 'some_table', 'column' => 'some_other_column',  'type' => 'character varying(255)', 'encoding' => 'none', 'distkey' => 'f', 'sortkey' => 0, 'notnull' => 't'},
          {'schemaname' => 'some_schema', 'tablename' => 'some_table', 'column' => 'yet_another_column', 'type' => 'character(5)',           'encoding' => 'none', 'distkey' => 'f', 'sortkey' => 2, 'notnull' => 't'}
        ]
      end

      before(:each) do
        @dummy = described_class.new(production_database)
      end

      context 'in any case' do
        before(:each) do
          allow(production_database).to receive(:query).and_return(table_definition)
          @dummy.send(:_get_create_table_statement, schema, table) rescue nil
        end

        it 'sets the search path and queries the table definition' do
          expect(production_database).to have_received(:exec).with(/^\s*set search\_path\s+to\s+'\$user',\s*some\_schema\s*;\s*$/).ordered
          expect(production_database).to have_received(:query).with(/^\s*select\s+\*\s+from\s+pg\_table\_def\s+where\s+schemaname\s*=\s*'some\_schema'\s+and\s+tablename\s*=\s*'some\_table'\s*;\s*$/).ordered
        end
      end

      context 'when there is a table definition' do
        before(:each) do
          allow(production_database).to receive(:query).and_return(table_definition)
          allow(table_definition).to receive(:num_tuples).and_return(1)
        end

        it 'does not raise an error' do
          expect { @dummy.send(:_get_create_table_statement, schema, table) }.to_not raise_error
        end

        it 'returns a correctly parsed schema' do
          expect(@dummy.send(:_get_create_table_statement, schema, table)).to match(
            /^\s*create\s+table\s+if\s+not\s+exists\s+some\_schema\.some\_table\s+\(\s*some\_column\s+integer\s+(not|default)\s+null\s*,\s*some\_other\_column\s+character\s+varying\(255\)\s+(not|default)\s+null\s*,\s*yet\_another\_column\s+character\(5\)\s+(not|default)\s+null\)\s+distkey\s*\(\s*some\_column\s*\)\s+sortkey\s*\(\s*some\_column\s*,\s*yet\_another\_column\s*\)\s*;\s*$/
          )
        end

        it 'returns the parsed schema with all columns allowing null values' do
          expect(@dummy.send(:_get_create_table_statement, schema, table)).to match(
            /^\s*create\s+table\s+if\s+not\s+exists\s+some\_schema\.some\_table\s+\(\s*some\_column\s+integer\s+default\s+null\s*,\s*some\_other\_column\s+character\s+varying\(255\)\s+default\s+null\s*,\s*yet\_another\_column\s+character\(5\)\s+default\s+null\)\s+distkey\s*\(\s*some\_column\s*\)\s+sortkey\s*\(\s*some\_column\s*,\s*yet\_another\_column\s*\)\s*;\s*$/
          )
        end
      end

      context 'when there is no table definition' do
        before(:each) do
          allow(production_database).to receive(:query).and_return(table_definition)
          allow(table_definition).to receive(:num_tuples).and_return(0)
        end

        it 'raises an error' do
          expect { @dummy.send(:_get_create_table_statement, schema, table) }.to raise_error(RuntimeError, /^Sorry, there is no table information/)
        end
      end
    end

    describe '#destroy' do
      before(:each) do
        allow(production_database).to receive(:close)
        allow(testing_database).to receive(:close)
        @dummy = described_class.new(production_database)
      end

      context 'when the db shall be kept' do
        before(:each) do
          stub_const("#{described_class}::DELETE_DB_WHEN_FINISHED", false)
          @dummy.destroy()
        end

        it 'closes the connection to the production database' do
          expect(production_database).to have_received(:close)
        end

        it 'closes the connection to the testing database' do
          expect(testing_database).to have_received(:close)
        end

        it 'does not drop the testing database' do
          expect(production_database).to_not have_received(:exec).with(/^drop\s+database/)
        end
      end

      context 'when the db may be deleted' do
        before(:each) do
          stub_const("#{described_class}::DELETE_DB_WHEN_FINISHED", true)
          @dummy.destroy()
        end

        it 'closes the connection to the production database' do
          expect(production_database).to have_received(:close)
        end

        it 'closes the connection to the testing database' do
          expect(testing_database).to have_received(:close)
        end

        it 'does not drop the testing database' do
          expect(production_database).to have_received(:exec).with(/^create\s+database\s+#{Regexp.quote(@dummy.instance_variable_get(:@test_db_name))}/).ordered
          expect(production_database).to have_received(:exec).with(/^drop\s+database\s+#{Regexp.quote(@dummy.instance_variable_get(:@test_db_name))}$/).ordered
        end
      end
    end
  end
end
