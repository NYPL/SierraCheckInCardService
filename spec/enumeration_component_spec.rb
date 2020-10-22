require_relative './spec_helper'
require_relative '../lib/enumeration_component'

describe EnumerationComponent do
    describe :initialize do
        it 'should initialize empty class instance variables' do
            test_enum = EnumerationComponent.new [1, 2, nil]

            expect(test_enum.enum_values).to eq([1, 2, nil])
            expect(test_enum.enum_string).to eq(nil)
        end
    end

    describe :generate_enumeration do
        before(:each) do
            @test_enum = EnumerationComponent.new []
        end

        it 'should return a single enum value as an issue number' do
            @test_enum.instance_variable_set(:@enum_values, [3, nil, nil, nil, nil])

            @test_enum.generate_enumeration

            expect(@test_enum.enum_string).to eq('No. 3')
        end

        it 'should return two enum values as a volume and  issue number' do
            @test_enum.instance_variable_set(:@enum_values, [6, 3, nil, nil, nil])

            @test_enum.generate_enumeration

            expect(@test_enum.enum_string).to eq('Vol. 6 No. 3')
        end

        it 'should return three or more enum values joined by colons' do
            @test_enum.instance_variable_set(:@enum_values, [3, 4, 5, 6, nil])

            @test_enum.generate_enumeration

            expect(@test_enum.enum_string).to eq('3:4:5:6')
        end

        it 'should set all nil values to nil' do
            @test_enum.instance_variable_set(:@enum_values, [nil, nil, nil, nil])

            @test_enum.generate_enumeration

            expect(@test_enum.enum_string).to eq(nil)
        end
    end
end
