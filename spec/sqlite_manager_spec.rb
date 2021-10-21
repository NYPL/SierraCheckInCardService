require_relative '../lib/sqlite_manager'
require_relative './spec_helper'

describe SQLITEClient do
    before(:each) do
        @test_client = SQLITEClient.new
    end

    describe :fetch_records do
        it 'should execute a query with the provided holding_id' do
            @mock_resp_one = mock
            @mock_resp_one.stubs(:ntuples).returns(1)
            @mock_resp_one.stubs(:to_a).returns([{ 'id' => 1, 'record_num' => 2, 'box_count' => 3 }])
            @mock_resp_two = mock
            @mock_resp_two.stubs(:ntuples).returns(0)
            $pg_client.stubs(:exec_query).once.with(ENV['DB_QUERY'], 1, { offset: 0, limit: 100_000 })
                .returns(@mock_resp_one)
            $pg_client.stubs(:exec_query).once.with(ENV['DB_QUERY'], 1, { offset: 100_000, limit: 100_000 })
                .returns(@mock_resp_two)
            @test_client.stubs(:parse_rows).once.with([{ 'id' => 1, 'record_num' => 2, 'box_count' => 3 }])

            @test_client.fetch_records 1
        end
    end

    describe :parse_rows do
        let(:mock_struct) { Struct.new(:id, :box_id) }

        it 'should invoke RowTransformer for each row and return a hash' do
            mock_row = mock
            sample_rows = [{ id: 1 }, { id: 2 }, { id: 3 }]
            RowTransformer.stubs(:new).once.with(sample_rows[0]).returns(mock_row)
            RowTransformer.stubs(:new).once.with(sample_rows[1]).returns(mock_row)
            RowTransformer.stubs(:new).once.with(sample_rows[2]).returns(mock_row)
            mock_row.stubs(:transform).times(3)
            mock_row.stubs(:formatted_row).times(3).returns(mock_struct.new(1, 2))

            out_arr = @test_client.parse_rows(sample_rows)

            expect(out_arr).to eq([{ box_id: 2, id: 1 }, { box_id: 2, id: 1 }, { box_id: 2, id: 1 }])
        end
    end
end
