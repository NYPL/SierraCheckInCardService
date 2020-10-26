require_relative './spec_helper'
require_relative '../lib/row_transformer'

describe RowTransformer do
    before(:each) do
        @test_row = RowTransformer.new 'test_row'
    end

    describe :initialize do
        it 'should initialize with row data' do
            expect(@test_row.instance_variable_get(:@db_row)).to eq('test_row')
            expect(@test_row.instance_variable_get(:@transformed_row)).to eq(nil)
            expect(@test_row.instance_variable_get(:@formatted_row).class).to eq(BoxRow)
        end
    end

    describe :transform do
        it 'should invoke all transformation methods' do
            @test_row.stubs(:transform_row).once
            @test_row.stubs(:load_simple_fields).once
            @test_row.stubs(:load_status_field).once
            @test_row.stubs(:load_enumeration_field).once
            @test_row.stubs(:load_date_fields).once

            @test_row.transform
        end
    end

    describe :transform_row do
        it 'should turn arrays of field keys and values into a hash' do
            test_val = Array.new(30)
            test_val[0] = 1
            test_val[1] = 2
            test_val[2] = 3
            test_val[4] = 120
            test_val[5] = 15
            test_val[29] = 'testing'
            @test_row.instance_variable_set(:@db_row, test_val)

            @test_row.transform_row

            expect(@test_row.instance_variable_get(:@transformed_row)['id']).to eq(1)
            expect(@test_row.instance_variable_get(:@transformed_row)['holding_record_id']).to eq(2)
            expect(@test_row.instance_variable_get(:@transformed_row)['record_num']).to eq(3)
            expect(@test_row.instance_variable_get(:@transformed_row)['box_count']).to eq(120)
            expect(@test_row.instance_variable_get(:@transformed_row)['enum_level_a']).to eq(15)
            expect(@test_row.instance_variable_get(:@transformed_row)['staff_note']).to eq('testing')
        end
    end

    describe :load_simple_fields do
        it 'should load data from transformed hash to formatted struct' do
            test_hash = {
                'id' => 1,
                'record_num' => 2,
                'box_count' => 120,
                'claim_cnt' => 0,
                'copy_cnt' => 1,
                'url' => nil,
                'is_suppressed' => 'f',
                'note' => 'test record',
                'staff_note' => 'internal note'
            }
            @test_row.instance_variable_set(:@transformed_row, test_hash)

            @test_row.load_simple_fields

            expect(@test_row.instance_variable_get(:@formatted_row).box_id).to eq(1)
            expect(@test_row.instance_variable_get(:@formatted_row).holding_id).to eq(2)
            expect(@test_row.instance_variable_get(:@formatted_row).box_count).to eq(120)
            expect(@test_row.instance_variable_get(:@formatted_row).claim_count).to eq(0)
            expect(@test_row.instance_variable_get(:@formatted_row).copy_count).to eq(1)
            expect(@test_row.instance_variable_get(:@formatted_row).url).to eq(nil)
            expect(@test_row.instance_variable_get(:@formatted_row).suppressed).to eq('f')
            expect(@test_row.instance_variable_get(:@formatted_row).note).to eq('test record')
            expect(@test_row.instance_variable_get(:@formatted_row).staff_note).to eq('internal note')
        end
    end

    describe :load_status_field do
        it 'should return a hash with code and value on success' do
            @test_row.instance_variable_set(:@transformed_row, { 'box_status_code' => 'A' })

            @test_row.load_status_field

            expect(@test_row.instance_variable_get(:@formatted_row).status[:code]).to eq('A')
            expect(@test_row.instance_variable_get(:@formatted_row).status[:label]).to eq('Arrived')
        end

        it 'should return nil for a label if an unexpected code is received' do
            @test_row.instance_variable_set(:@transformed_row, { 'box_status_code' => 'X' })

            @test_row.load_status_field

            expect(@test_row.instance_variable_get(:@formatted_row).status[:code]).to eq('X')
            expect(@test_row.instance_variable_get(:@formatted_row).status[:label]).to eq(nil)
        end

        it 'should return nil for both values if no status code is present' do
            @test_row.instance_variable_set(:@transformed_row, { 'box_status_code' => nil })

            @test_row.load_status_field

            expect(@test_row.instance_variable_get(:@formatted_row).status[:code]).to eq(nil)
            expect(@test_row.instance_variable_get(:@formatted_row).status[:label]).to eq(nil)
        end
    end

    describe :load_enumeration_field do
        it 'should create enumeration value delimited by colons for all values' do
            @test_row.instance_variable_set(:@transformed_row, {
                'enum_level_a' => 1, 'enum_level_b' => 2, 'enum_level_c' => nil,
                'enum_level_d' => 4, 'enum_level_e' => nil
            })

            enum_mock = mock
            EnumerationComponent.stubs(:new).once.with([1, 2, nil, 4, nil]).returns(enum_mock)
            enum_mock.stubs(:generate_enumeration).once
            enum_mock.stubs(:enum_string).once.returns('1:2:4')
            enum_mock.stubs(:enum_values).once.returns([1, 2, nil, 4, nil])

            @test_row.load_enumeration_field

            expect(@test_row.instance_variable_get(:@formatted_row).enumeration[:enumeration]).to eq('1:2:4')
            expect(@test_row.instance_variable_get(:@formatted_row).enumeration[:levels]).to eq([1, 2, nil, 4, nil])
        end
    end

    describe :load_date_fields do
        it 'should set dates for both coverage and transaction fields' do
            chron_mock = mock
            chron_mock.stubs(:date_strs).returns({ start: 'start', end: 'end' })
            @test_row.stubs(:parse_date_fields).once\
                .with(/chron_level_([a-z]{1})$/).returns(chron_mock)

            trans_mock = mock
            trans_mock.stubs(:date_strs).returns({ start: 'trans_start', end: 'trans_end' })
            @test_row.stubs(:parse_date_fields).once\
                .with(/chron_level_([a-z]{1})_trans_date$/).returns(trans_mock)

            @test_row.load_date_fields

            expect(@test_row.instance_variable_get(:@formatted_row).start_date).to eq('start')
            expect(@test_row.instance_variable_get(:@formatted_row).end_date).to eq('end')
            expect(@test_row.instance_variable_get(:@formatted_row).trans_start_date).to eq('trans_start')
            expect(@test_row.instance_variable_get(:@formatted_row).trans_end_date).to eq('trans_end')
        end
    end

    describe :parse_date_fields do
        it 'should return formatted strings from provided components' do
            @test_row.instance_variable_set(:@transformed_row, {
                'chron_level_i' => '2020', 'chron_level_j' => '01', 'chron_level_k' => '01'
            })

            date_mock = mock
            DateComponent.stubs(:new).once.with(['2020', '01', '01']).returns(date_mock)
            date_mock.stubs(:create_strs).once

            date_comp = @test_row.parse_date_fields(/chron_level_([a-z]{1})$/)

            expect(date_comp).to eq(date_mock)
        end
    end
end
