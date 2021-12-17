require_relative './row_transformer'

# Manages fetching and parsing records
class RecordManager
    @@DB_QUERY = <<~SQL
    SELECT sierra_view.holding_record_card.id, sierra_view.holding_record_card.holding_record_id,
    sierra_view.holding_view.record_num, sierra_view.holding_record_box.*
    FROM sierra_view.holding_record_card
    LEFT OUTER JOIN sierra_view.holding_view ON sierra_view.holding_view.id=sierra_view.holding_record_card.holding_record_id
    LEFT OUTER JOIN sierra_view.holding_record_cardlink ON sierra_view.holding_record_card.id=sierra_view.holding_record_cardlink.holding_record_card_id
    LEFT OUTER JOIN sierra_view.holding_record_box ON sierra_view.holding_record_box.holding_record_cardlink_id=sierra_view.holding_record_cardlink.id
    WHERE sierra_view.holding_view.record_num = $1
    SQL

    def fetch_records(holding_id)
        $logger.info "Querying sierra for record #{holding_id}"
        box_rows = $pg_client.exec_query(@@DB_QUERY, holding_id, offset: 0, limit: 100_000)
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
