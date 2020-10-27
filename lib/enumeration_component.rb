# Class that handles formatting enumeration strings
class EnumerationComponent
    attr_reader :enum_string, :enum_values

    def initialize(enum_values)
        @enum_values = enum_values
        @enum_string = nil
    end

    def generate_enumeration
        not_nil_enums = @enum_values.compact
        $logger.debug 'Transforming array of enum values to string', { values: not_nil_enums }

        case not_nil_enums.length
        # If this is a single value it should be an issue number
        when 1
            @enum_string = "No. #{not_nil_enums[0]}"
        # If there are two values it should be a volume and issue numbers
        when 2
            @enum_string = "Vol. #{not_nil_enums[0]} No. #{not_nil_enums[1]}"
        # If there are three or more values we don't know, so just join them
        # This goes to 26 because the fields are alphabetical a-z
        when 3..26
            @enum_string = not_nil_enums.join(':')
        end
    end
end
