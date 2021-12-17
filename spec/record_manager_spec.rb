require_relative '../lib/record_manager'
require_relative './spec_helper'

describe RecordManager do
    before(:each) do
        @test_client = RecordManager.new
        @db_query = <<~SQL
        SELECT sierra_view.holding_record_card.id, sierra_view.holding_record_card.holding_record_id,
        sierra_view.holding_view.record_num, sierra_view.holding_record_box.*
        FROM sierra_view.holding_record_card
        LEFT OUTER JOIN sierra_view.holding_view ON sierra_view.holding_view.id=sierra_view.holding_record_card.holding_record_id
        LEFT OUTER JOIN sierra_view.holding_record_cardlink ON sierra_view.holding_record_card.id=sierra_view.holding_record_cardlink.holding_record_card_id
        LEFT OUTER JOIN sierra_view.holding_record_box ON sierra_view.holding_record_box.holding_record_cardlink_id=sierra_view.holding_record_cardlink.id
        WHERE sierra_view.holding_view.record_num = $1
        SQL
    end

    describe :fetch_records do
        it 'should execute a query with the provided holding_id' do
            @mock_resp_one = mock
            @mock_resp_one.stubs(:ntuples).returns(1)
            @mock_resp_one.stubs(:to_a).returns([{ 'id' => 1, 'record_num' => 2, 'box_count' => 3 }])
            @mock_resp_two = mock
            @mock_resp_two.stubs(:ntuples).returns(0)
            $pg_client.stubs(:exec_query).once.with(@db_query, 1, { offset: 0, limit: 100_000 })
                .returns(@mock_resp_one)
            @test_client.stubs(:parse_rows).once.with([{ 'id' => 1, 'record_num' => 2, 'box_count' => 3 }])

            @test_client.fetch_records 1
        end
    end

    describe :parse_rows do
        let(:mock_struct) { Struct.new(:id, :box_id) }

        it 'should invoke RowTransformer for each row and return a hash' do
            mock_row = mock
            sample_rows = [{ 'id' => 1 }, { 'id' => 2 }, { 'id' => 3 }]
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
