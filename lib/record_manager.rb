require_relative './row_transformer'

# Manages fetching and parsing records
class RecordManager
    def fetch_records(holding_id)
        $logger.info "Querying sierra for record #{holding_id}"
        box_rows = $pg_client.exec_query(ENV['DB_QUERY'], holding_id, offset: 0, limit: 100_000)
        parse_rows box_rows.to_a
    end

    def parse_rows(rows)
        rows.reject { |row| row['id'].nil? }.map do |row|
            box_row = RowTransformer.new row
            box_row.transform

            box_row.formatted_row.to_h
        end
    end
end
