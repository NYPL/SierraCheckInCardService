require_relative './row_transformer'

class SQLITEClient
    def initialize
    end

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
        rows.map do |row|
            box_row = RowTransformer.new row
            box_row.transform

            box_row.formatted_row.to_h
        end.reject do |row|
          row[:box_id].nil?
        end
    end
end

class SqliteError < StandardError; end
