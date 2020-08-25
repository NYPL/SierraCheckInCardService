require_relative '../app'
require_relative '../lib/date_component'

describe DateComponent do
    describe :initialize do
        it 'should initialize empty class instance variables' do
            test_date = DateComponent.new

            expect(test_date.date_str).to eq('')
            expect(test_date.instance_variable_get(:@start_year)).to eq(nil)
            expect(test_date.instance_variable_get(:@start_month)).to eq(nil)
            expect(test_date.instance_variable_get(:@start_day)).to eq(nil)
            expect(test_date.instance_variable_get(:@end_year)).to eq(nil)
            expect(test_date.instance_variable_get(:@end_month)).to eq(nil)
            expect(test_date.instance_variable_get(:@end_day)).to eq(nil)
        end
    end

    describe :set_field do
        before(:each) do
            @test_date = DateComponent.new
        end

        it 'should set start and end to the same value if only single value is received' do
            @test_date.set_field('year', '2020')

            expect(@test_date.instance_variable_get(:@start_year)).to eq('2020')
            expect(@test_date.instance_variable_get(:@end_year)).to eq('2020')
        end

        it 'should set start and end to different values if delimited with a dash' do
            @test_date.set_field('month', '5-7')

            expect(@test_date.instance_variable_get(:@start_month)).to eq('5')
            expect(@test_date.instance_variable_get(:@end_month)).to eq('7')
        end

        it 'should do nothing if value received is 0 or a variation thereof' do
            @test_date.set_field('day', '0-')

            expect(@test_date.instance_variable_get(:@start_day)).to eq(nil)
            expect(@test_date.instance_variable_get(:@end_day)).to eq(nil)
        end
    end

    describe :create_strs do
        before(:each) do
            @test_date = DateComponent.new
        end

        it 'should return a hash containing start and end ISO-8601 dates if they are different' do
            @test_date.stubs(:_format_str).once.with('start').returns('2020-01-01')
            @test_date.stubs(:_format_str).once.with('end').returns('2020-12-31')

            out_hash = @test_date.create_strs

            expect(out_hash[:start]).to eq('2020-01-01')
            expect(out_hash[:end]).to eq('2020-12-31')
        end

        it 'should return a hash containing only a start value if dates are equal' do
            @test_date.stubs(:_format_str).once.with('start').returns('2020-01-01')
            @test_date.stubs(:_format_str).once.with('end').returns('2020-01-01')

            out_hash = @test_date.create_strs

            expect(out_hash[:start]).to eq('2020-01-01')
            expect(out_hash[:end]).to eq(nil)
        end
    end

    describe :_format_str do
        before(:each) do
            @test_date = DateComponent.new
        end

        it 'should return an ISO-8601 date with year month and day if all are available' do
            @test_date.instance_variable_set(:@start_year, '2020')
            @test_date.instance_variable_set(:@start_month, '01')
            @test_date.instance_variable_set(:@start_day, '01')

            out_date = @test_date.send(:_format_str, 'start')

            expect(out_date).to eq('2020-01-01')
        end

        it 'should return an ISO-8601 with year and month only if day is missing' do
            @test_date.instance_variable_set(:@start_year, '2020')
            @test_date.instance_variable_set(:@start_month, '01')

            out_date = @test_date.send(:_format_str, 'start')

            expect(out_date).to eq('2020-01')
        end

        it 'should return an ISO-8601 with year and day if month is missing' do
            @test_date.instance_variable_set(:@start_year, '2020')
            @test_date.instance_variable_set(:@start_day, '01')

            out_date = @test_date.send(:_format_str, 'start')

            expect(out_date).to eq('2020---01')
        end
    end
end
