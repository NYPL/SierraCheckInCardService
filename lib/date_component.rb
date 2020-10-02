# Component that parses date components from different fields into combined date range representations
class DateComponent
    attr_reader :date_str

    def initialize
        @start_year = nil
        @end_year = nil
        @start_month = nil
        @end_month = nil
        @start_day = nil
        @end_day = nil

        @date_str = ''
    end

    def set_field(component, value)
        return if /^0\-?$/.match value

        value_arr = value.split('-')
        instance_variable_set("@start_#{component}", value_arr[0])
        instance_variable_set("@end_#{component}", value_arr[1] || value_arr[0])
    end

    def create_strs
        start_str = _format_str 'start'
        end_str = _format_str 'end'

        if start_str == end_str
            { start: start_str, end: nil }
        else
            { start: start_str, end: end_str }
        end
    end

    private

    def _format_str(pos)
        year = instance_variable_get("@#{pos}_year")
        month = instance_variable_get("@#{pos}_month") || '-'
        day = instance_variable_get("@#{pos}_day")

        "#{year}-#{month}-#{day}".gsub(/\-+$/, '')
    end
end
