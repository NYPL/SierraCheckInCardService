require_relative '../app'
require_relative './spec_helper'

describe 'handler' do
    describe :init do
        before(:each) do
            @kms_mock = mock
            NYPLRubyUtil::KmsClient.stubs(:new).returns(@kms_mock)
            @record_manager_mock = mock
            RecordManager.stubs(:new).returns(@record_manager_mock)
            @pg_mock = mock
            PSQLClient.stubs(:new).returns(@pg_mock)
        end

        after(:each) do
            @kms_mock.unstub(:decrypt)
            $initialized = false
        end

        it 'should invoke clients and logger from the ruby utils gem' do
            init

            expect($kms_client).to eq(@kms_mock)
            expect($record_manager).to eq(@record_manager_mock)
            expect($initialized).to eq(true)
        end
    end

    describe :handle_event do
        before(:each) do
            stubs(:init).once
        end

        it 'should return 501 error response if method is not GET' do
            stubs(:create_response).once\
                .with(501, 'sierraCheckInCardService only implements GET endpoints').returns(501)

            res = handle_event(
                event: { 'path' => '/test/path', 'httpMethod' => 'POST', 'queryStringParameters' => 'params' },
                context: {}
            )

            expect(res).to eq(501)
        end

        it 'should return a 200 response with swagger documentation path' do
            stubs(:load_swagger_docs).once.returns(200)

            res = handle_event(
                event: { 'path' => '/docs/check-in-cards', 'httpMethod' => 'GET', 'queryStringParameters' => 'params' },
                context: {}
            )

            expect(res).to eq(200)
        end

        it 'should return a 404 if an unrecognized path is received' do
            stubs(:create_response).once.with(404, '/bad/path not found').returns(404)

            res = handle_event(
                event: { 'path' => '/bad/path', 'httpMethod' => 'GET', 'queryStringParameters' => 'params' },
                context: {}
            )

            expect(res).to eq(404)
        end

        it 'should invoke fetch_record_and_respond if successful' do
            stubs(:create_response).never
            stubs(:fetch_records_and_respond).once.with('params').returns('success')

            res = handle_event(
                event: {
                    'path' => '/api/v0.1/holdings/check-in-cards',
                    'httpMethod' => 'GET',
                    'queryStringParameters' => 'params'
                },
                context: {}
            )

            expect(res).to eq('success')
        end
    end

    describe :fetch_records_and_response do
        before(:each) do
            $record_manager = mock
        end

        it 'should return 200 status on successful retrieval of records' do
            $record_manager.stubs(:fetch_records).once.with(1).returns('test_records')
            stubs(:create_response).once.with(200, 'test_records').returns(200)

            resp = fetch_records_and_respond({ 'holding_id' => 1 })

            expect(resp).to eq(200)
        end

        it 'should return 500 status if record retrieval fails' do
            $record_manager.stubs(:fetch_records).once.with(1).raises(PSQLError.new('test_error'))
            stubs(:create_response).once.with(500, 'Failed to execute sql query').returns(500)

            resp = fetch_records_and_respond({ 'holding_id' => 1 })

            expect(resp).to eq(500)
        end
    end

    describe :create_response do
        it 'should return a hash with the arguments' do
            test_hash = create_response(200, 'test_body')

            expect(test_hash[:statusCode]).to eq(200)
            expect(test_hash[:body]).to eq(JSON.dump('test_body'))
        end
    end

    describe :load_swagger_docs do
        it 'should return swagger JSON object on success' do
            File.stubs(:read).once.with('./swagger.json').returns('{"test": "documentation"}')
            stubs(:create_response).once.with(200, { 'test' => 'documentation' }).returns(200)

            test_resp = load_swagger_docs

            expect(test_resp).to eq(200)
        end

        it 'should return 500 if JSON parsing fails' do
            File.stubs(:read).once.with('./swagger.json').returns('{test": "documentation"}')
            stubs(:create_response).once.with(500, 'Unable to load Swagger docs from JSON').returns(500)

            test_resp = load_swagger_docs

            expect(test_resp).to eq(500)
        end

        it 'should return 500 if swagger file loading fails' do
            File.stubs(:read).once.with('./swagger.json').raises(IOError.new('test error'))
            stubs(:create_response).once.with(500, 'Unable to load Swagger docs from JSON').returns(500)

            test_resp = load_swagger_docs

            expect(test_resp).to eq(500)
        end
    end
end
