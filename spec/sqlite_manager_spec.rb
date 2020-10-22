require_relative '../lib/sqlite_manager'
require_relative './spec_helper'

describe SQLITEClient do
    before(:each) do
        @db_mock = mock
        SQLite3::Database.stubs(:new).once.with('/tmp/testdb.sql').returns(@db_mock)

        @test_client = SQLITEClient.new
    end

    describe :initialize do
        it 'should initialize a database in the /tmp directory' do
            expect(@test_client.instance_variable_get(:@db)).to eq(@db_mock)
        end
    end

    describe :fetch_records do
        it 'should execute a query with the provided holding_id' do
            @test_client.stubs(:exec_query).once.with('SELECT * FROM boxes WHERE record_num = 1').returns([1, 2, 3])
            @test_client.stubs(:parse_rows).once.with([1, 2, 3])

            @test_client.fetch_records 1
        end
    end

    describe :exec_query do
        it 'should return matching rows for the specified query' do
            @db_mock.stubs(:execute).once.with('test query').returns(['row1', 'row2', 'row3'])

            out_rows = @test_client.exec_query 'test query'

            expect(out_rows).to eq(['row1', 'row2', 'row3'])
        end

        it 'should raise a sqlite error if unable to execute the query' do
            @db_mock.stubs(:execute).once.with('test query').raises(SQLite3::Exception.new('test error'))

            expect {
                @test_client.send(:exec_query, 'test query')
            }.to raise_error(SqliteError, 'Unable to execute query in local sqlite3 db')
        end
    end

    describe :parse_rows do
        let(:mock_struct) { Struct.new(:id) }

        it 'should invoke RowTransformer for each row and return a hash' do
            mock_row = mock
            RowTransformer.stubs(:new).once.with(1).returns(mock_row)
            RowTransformer.stubs(:new).once.with(2).returns(mock_row)
            RowTransformer.stubs(:new).once.with(3).returns(mock_row)
            mock_row.stubs(:transform).times(3)
            mock_row.stubs(:formatted_row).times(3).returns(mock_struct.new(1))

            out_arr = @test_client.parse_rows([1, 2, 3])

            expect(out_arr).to eq([{ id: 1 }, { id: 1 }, { id: 1 }])
        end
    end
end
