require 'date'

# Component that parses date components from different fields into combined date range representations
# Incoming data consists of strings in an array of ordered fields such that:
# ["2020", "01-12", "01-31", nil]
# This data is processed in the following steps:
# 1) The data is transposed from being grouped by "level" (e.g. year, month, etc.) to being grouped by type
# 2) These transposed arrays are parsed into human-readable date strings
# 3) These strings are put into a start/end object, with the end date being set to nil if the object
# represents a single date value
class DateComponent
    attr_reader :date_strs

    # These are ISO-8601 season codes that are used in catalog records
    @@season_codes = {
        21 => 'Spring',
        22 => 'Summer',
        23 => 'Fall',
        24 => 'Winter'
    }

    def initialize(date_values)
        @date_values = date_values
        @date_strs = {
            start: nil,
            end: nil
        }
    end

    # The main handler method for this class
    # Inovkes method to extract date values into transposed arrays, then parses these
    # arrays to strings before storing them in the date_strs object
    # If an error occurs the dates are left set to nil
    def create_strs
        $logger.debug 'Parsing date strings from values', { values: @date_values }
        # Split date strings into start/end values and then pivot them into properly arranged arrays
        # e.g. [[1, 2], [3, 4], [5, 6]] to [[1, 3, 5], [2, 4, 6]]
        date_components = @date_values.map { |v| _extract_date_components v.to_s }.transpose

        begin
            start_str = _transform_date_components_to_str date_components[0]
            end_str = _transform_date_components_to_str date_components[1]
            $logger.info "Setting date values: start / #{start_str}, end / #{end_str}"

            @date_strs[:start] = start_str
            @date_strs[:end] = end_str && end_str != start_str ? end_str : nil
        rescue Date::Error, TypeError, DateComponentError
            $logger.error 'Unable to parse date values for this check-in box'
            $logger.debug date_components
        end
    end

    private

    # This takes individual date components and turns them into start/end arrays
    # Components are strings and can be either single values ("2020") or spans ("2019-2020")
    # This returns an array of either both values, or the single value duplicated
    # This supports date ranges within a single year or month (e.g. three values of
    # "2020", "01-03" and "01-15" would eventually become "2020-01-01" and "2020-03-15")
    def _extract_date_components(component)
        component_arr = component.split('-')
        component_arr[1] ? component_arr : [component_arr[0], component_arr[0]]
    end

    # This method performs the core parsing of date arrays into strings
    # It takes an array of up to three values and looks at what non-nil values are present
    # The position of these values determines what the format of the date is and it is processed accordingly
    # The ruby Date class does not handle all of these formats properly, so we have added some custom handling for these
    # rubocop:disable Metrics/CyclomaticComplexity
    def _transform_date_components_to_str(part)
        $logger.debug 'Creating date string from', { values: part }
        date_values = part[0, 3] # We only want the first three values, so slice to be safe
        date_str = nil

        # Create a simplified array with the shape of the date values
        # This gives us a good idea of what the date format is
        null_positions = date_values.map { |x| x.nil? ? 0 : 1 }

        # Convert to array of ints with no nil values since DateTime doesn't like them
        date_array = date_values.map { |x| x.nil? ? x : x.to_i }

        case null_positions
        # Single value should be a year and returned as-is
        when [1, 0, 0]
            date_str = date_array[0].to_s
        # Two consecutive values should be Month-Year or Season-Year
        when [1, 1, 0]
            begin
                date_str = DateTime.new(*date_array.compact).strftime('%b. %Y')
            rescue Date::Error => e
                $logger.error 'Unable to parse date', { value: date_array, reason: e }
                # DateTime doesn't know about seasons, so fake it here
                date_str = "#{@@season_codes[date_array[1]]} #{date_array[0]}"
            end
        # Three values will 99.99% of the time be a true date
        when [1, 1, 1]
            date_str = DateTime.new(*date_array).strftime('%b. %-d, %Y')
        # A missing value in the month/season position might indicate a day-of-year value
        when [1, 0, 1]
            date_str = "Day #{date_array[2]} of #{date_array[0]}"
        else
            $logger.error 'Unable to process date components, unrecognized format', { components: part }
            $logger.debug 'Shape of components: ', { date_comp_shape: null_positions }
            raise DateComponentError, 'Unprocessable component found'
        end

        date_str
    end
    # rubocop:enable Metrics/CyclomaticComplexity
end

class DateComponentError < StandardError; end
