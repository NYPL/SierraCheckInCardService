require_relative './spec_helper'
require_relative './handler_spec'
require_relative '../lib/date_component'

describe DateComponent do
    describe :initialize do
        it 'should initialize empty class instance variables' do
            test_date = DateComponent.new ['2020', '01', '01']

            expect(test_date.instance_variable_get(:@date_values)).to eq(['2020', '01', '01'])
            expect(test_date.date_strs[:start]).to eq(nil)
            expect(test_date.date_strs[:end]).to eq(nil)
        end
    end

    describe :create_strs do
        before(:each) do
            @test_date = DateComponent.new []
        end

        it 'should return a hash containing start and end dates if they are different' do
            @test_date.instance_variable_set(:@date_values, [2020, '01-12', '1-31'])

            @test_date.create_strs

            expect(@test_date.date_strs[:start]).to eq('Jan. 1, 2020')
            expect(@test_date.date_strs[:end]).to eq('Dec. 31, 2020')
        end

        it 'should return a hash containing only a start value if dates are equal' do
            @test_date.instance_variable_set(:@date_values, ['2020', '01', '01'])

            @test_date.create_strs

            expect(@test_date.date_strs[:start]).to eq('Jan. 1, 2020')
            expect(@test_date.date_strs[:end]).to eq(nil)
        end

        it 'should handle a Date::Error and leave date_strs set to nil' do
            @test_date.instance_variable_set(:@date_values, ['2020', '01', '01'])

            @test_date.stubs(:_transform_date_components_to_str).raises(Date::Error)

            @test_date.create_strs

            expect(@test_date.date_strs[:start]).to eq(nil)
            expect(@test_date.date_strs[:end]).to eq(nil)
        end
    end

    describe :_extract_date_components do
        before(:each) do
            @test_date = DateComponent.new []
        end

        it 'should return an array of split values if value contains a hyphen' do
            out_array = @test_date.send(:_extract_date_components, '2019-2020')

            expect(out_array[0]).to eq('2019')
            expect(out_array[1]).to eq('2020')
        end

        it 'should return an array of duplicate values if a single date is provided' do
            out_array = @test_date.send(:_extract_date_components, '2020')

            expect(out_array[0]).to eq('2020')
            expect(out_array[1]).to eq('2020')
        end
    end

    describe :_transform_date_array do
        before(:each) do
            @test_date = DateComponent.new []
        end

        it 'should return an ISO-8601 date with year month and day if all are available' do
            out_date = @test_date.send(:_transform_date_components_to_str, ['2020', '01', '01'])

            expect(out_date).to eq('Jan. 1, 2020')
        end

        it 'should return an ISO-8601 with year and month only if day is missing' do
            out_date = @test_date.send(:_transform_date_components_to_str, ['2020', '01', nil])

            expect(out_date).to eq('Jan. 2020')
        end

        it 'should return an ISO-8601 with year and day if month is missing' do
            out_date = @test_date.send(:_transform_date_components_to_str, ['2020', nil, '01'])

            expect(out_date).to eq('Day 1 of 2020')
        end

        it 'should return an ISO-8601 Season Year date if season code received' do
            out_date = @test_date.send(:_transform_date_components_to_str, ['2020', '23', nil])

            expect(out_date).to eq('Fall 2020')
        end

        it 'should return an ISO-8601 year if day and month are missing' do
            out_date = @test_date.send(:_transform_date_components_to_str, ['2020', nil, nil])

            expect(out_date).to eq('2020')
        end
    end
end
