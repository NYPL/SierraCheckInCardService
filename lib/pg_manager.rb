require 'pg'

# Client for managing connections to the PostgreSQL database
# Currently exposes a single method that allows executing an arbitraty query
class PSQLClient
    def initialize
        @conn = PG.connect(
            host: ENV['DB_HOST'],
            port: ENV['DB_PORT'],
            dbname: ENV['DB_NAME'],
            user: $kms_client.decrypt(ENV['DB_USER']),
            password: $kms_client.decrypt(ENV['DB_PSWD'])
        )
    end

    def exec_query(query, holding_id, offset: nil, limit: nil)
        $logger.info 'Querying Sierra db for check-in boxes'
        $logger.debug "Executing query: #{query}"

        query = "#{query} OFFSET #{offset}" if offset
        query = "#{query} LIMIT #{limit}" if limit

        begin
            @conn.exec_params query, [holding_id]
        rescue StandardError => e
            $logger.error 'Unable to query Sierra db for check-in rows', { message: e.message }
            raise PSQLError, 'Cannot execute query against Sierra db, no rows retrieved'
        end
    end
end

class PSQLError < StandardError; end
