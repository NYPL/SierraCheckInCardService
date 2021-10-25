require 'nypl_ruby_util'

require_relative 'lib/record_manager'
require_relative 'lib/pg_manager'

def init
    return if $initialized

    $logger = NYPLRubyUtil::NyplLogFormatter.new($stdout, level: ENV['LOG_LEVEL'])
    $kms_client = ENV['PROFILE'] ?
      NYPLRubyUtil::KmsClient.new({ profile: ENV['PROFILE'] }) :
      NYPLRubyUtil::KmsClient.new

    $record_manager = RecordManager.new
    $pg_client = PSQLClient.new

    $logger.debug 'Initialized function'
    $initialized = true
end

# rubocop:disable Lint/UnusedMethodArgument
def handle_event(event:, context:)
    init

    path = event['path']
    method = event['httpMethod']
    params = event['queryStringParameters']

    $logger.info('handling event', event)

    return create_response(501, 'sierraCheckInCardService only implements GET endpoints') unless method == 'GET'

    if path == '/docs/check-in-cards'
        load_swagger_docs
    elsif /\S+\/holdings\/check\-in\-cards/.match? path
        fetch_records_and_respond params
    else
        create_response(404, "#{path} not found")
    end
end
# rubocop:enable Lint/UnusedMethodArgument

def fetch_records_and_respond(params)
    records = $record_manager.fetch_records params['holding_id']
rescue PSQLError
    $logger.info 'Received pg error'
    create_response(500, 'Failed to execute sql query')
else
    create_response(200, records)
end

def create_response(status_code = 200, body = nil)
    $logger.info "Responding with #{status_code}"

    {
        statusCode: status_code,
        body: JSON.dump(body),
        isBase64Encoded: false,
        headers: { 'Content-type': 'application/json' }
    }
end

def load_swagger_docs
    swagger_docs = JSON.parse(File.read('./swagger.json'))
    create_response(200, swagger_docs)
rescue JSON::JSONError => e
    $logger.error 'Failed to parse Swagger documentation'
    $logger.debug e.message
    create_response(500, 'Unable to load Swagger docs from JSON')
rescue IOError => e
    $logger.error 'Unable to load swagger documentation from file'
    $logger.debug e.message
    create_response(500, 'Unable to load Swagger docs from JSON')
end
