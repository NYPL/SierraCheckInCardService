require_relative './date_component'
require_relative './enumeration_component'

# Transforms a row of sql data representing a check-in box into a simplified JSON representation
class RowTransformer
    attr_reader :formatted_row

    @@box_columns = [
        'id', 'holding_record_id', 'record_num', 'holding_record_cardlink_id', 'box_count', 'enum_level_a',
        'enum_level_b', 'enum_level_c', 'enum_level_d', 'enum_level_e', 'enum_level_f', 'enum_level_g', 'enum_level_h',
        'chron_level_i', 'chron_level_j', 'chron_level_k', 'chron_level_l', 'chron_level_m', 'chron_level_i_trans_date',
        'chron_level_j_trans_date', 'chron_level_k_trans_date', 'chron_level_l_trans_date', 'chron_level_m_trans_date',
        'note', 'box_status_code', 'claim_cnt', 'copies_cnt', 'url', 'is_suppressed', 'staff_note'
    ]

    @@box_codes = {
        'A' => 'Arrived',
        'B' => 'Bound',
        'E' => 'Expected',
        'L' => 'Not Published',
        'M' => 'Missing',
        'N' => 'Blank',
        'O' => 'Out of Print',
        'P' => 'Partial',
        'R' => 'Removed',
        'S' => 'Bind Prep',
        'T' => 'To Bind',
        'U' => 'Unavailable'
    }

    @@chron_fields = {
        'i' => 'year',
        'j' => 'month',
        'k' => 'day'
    }

    def initialize(row)
        @db_row = row
        @transformed_row = nil
        @formatted_row = BoxRow.new
    end

    def transform
        transform_row

        load_simple_fields # Loads fields that don't require transformation into BoxRow
        load_status_field # Provides translation of single character status code
        load_enumeration_field # Parses enumeration fields, returning array and joined string for display
        load_date_fields # Transforms chronology fields into ISO-8601 start and end dates
    end

    def transform_row
        @transformed_row = @@box_columns.zip(@db_row).to_h
    end

    def load_simple_fields
        @formatted_row.box_id = @transformed_row['id']
        @formatted_row.holding_id = @transformed_row['record_num']
        @formatted_row.box_count = @transformed_row['box_count']
        @formatted_row.claim_count = @transformed_row['claim_cnt']
        @formatted_row.copy_count = @transformed_row['copy_cnt']
        @formatted_row.url = @transformed_row['url']
        @formatted_row.suppressed = @transformed_row['is_suppressed']
        @formatted_row.note = @transformed_row['note']
        @formatted_row.staff_note = @transformed_row['staff_note']
    end

    def load_status_field
        box_status = @transformed_row['box_status_code']
        @formatted_row.status = {
            code: box_status,
            label: @@box_codes[box_status]
        }
    end

    def load_enumeration_field
        enum_component = EnumerationComponent.new(@transformed_row.filter { |k, _| k.include? 'enum_level_' }.values)
        enum_component.generate_enumeration
        @formatted_row.enumeration = {
            enumeration: enum_component.enum_string,
            levels: enum_component.enum_values
        }
    end

    def load_date_fields
        chron_dates = parse_date_fields(/chron_level_([a-z]{1})$/)
        @formatted_row.start_date = chron_dates.date_strs[:start]
        @formatted_row.end_date = chron_dates.date_strs[:end]

        trans_dates = parse_date_fields(/chron_level_([a-z]{1})_trans_date$/)
        @formatted_row.trans_start_date = trans_dates.date_strs[:start]
        @formatted_row.trans_end_date = trans_dates.date_strs[:end]
    end

    def parse_date_fields(regex)
        date_component = DateComponent.new(@transformed_row.filter { |k, _| regex.match?(k) }.values)
        date_component.create_strs
        date_component
    end
end

BoxRow = Struct.new(
    :box_id, :holding_id, :box_count, :enumeration, :start_date, :end_date, :trans_start_date, :trans_end_date, :status,
    :claim_count, :copy_count, :url, :suppressed, :note, :staff_note
)
