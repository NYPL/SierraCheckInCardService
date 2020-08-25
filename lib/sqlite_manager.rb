require 'sqlite3'

require_relative './row_transformer'

# Client for creating and updating local sqlite3 database
class SQLITEClient
    def initialize
        @db = SQLite3::Database.new "/tmp/#{ENV['SQLITE_FILE']}"
    end

    def fetch_records(holding_id)
        rows = exec_query "SELECT * FROM boxes WHERE record_num = #{holding_id}"

        parse_rows rows
    end

    def exec_query(query)
        @db.execute(query)
    rescue SQLite3::Exception => e
        $logger.error 'Unable to execute query in local sqlite3 db', { code: e.code }
        $logger.debug "Failed query: #{query}"
        raise SqliteError, 'Unable to execute query in local sqlite3 db'
    end

    def parse_rows(rows)
        rows.map do |row|
            box_row = RowTransformer.new row
            box_row.transform

            box_row.formatted_row.to_h
        end
    end
end

class SqliteError < StandardError; end
