require_relative './row_transformer'

# Manages fetching and parsing records
class SQLITEClient
    def fetch_records(holding_id)
        rows = []
        offset = 0
        limit = 100_000
        loop do
            $logger.info "Querying sierra for record batch #{offset}:#{limit}"
            box_rows = $pg_client.exec_query(ENV['DB_QUERY'], holding_id, offset: offset, limit: limit)

            break unless box_rows.ntuples > 0

            rows += box_rows.to_a
            offset += limit
        end
        parse_rows rows
    end

    def parse_rows(rows)
        rows.reject { |row| row['id'].nil? }.map do |row|
            box_row = RowTransformer.new row
            box_row.transform

            box_row.formatted_row.to_h
        end
    end
end

class SqliteError < StandardError; end
