module IniParse
  class Parser
    cattr_accessor :parse_types
    @@parse_types = [ IniParse::Lines::Option,
                      IniParse::Lines::Section,
                      IniParse::Lines::Blank ]

    # Creates a new Parser instance for parsing string +source+.
    #
    # ==== Parameters
    # source<String>:: The source string.
    #
    def initialize(source)
      @source = source
    end

    # Parses the source string and returns the resulting data structure.
    #
    # ==== Returns
    # IniParse::Document
    #
    def parse
      generator = IniParse::Generator.new

      @source.split("\n", -1).each_with_index do |line, i|
        sanitized, opts = IniParse::Lines::Line.sanitize_line(line)

        parsed = @@parse_types.reduce(nil) do |memo, type|
          memo ||= type.parse(sanitized, opts)
        end

        if parsed
          generator.send(*parsed)
        else
          raise IniParse::ParseError, <<-EOS.compress_lines
            A line of your INI document could not be parsed to a LineType:
            '#{line}' (line #{i+1}).
          EOS
        end
      end

      generator.document
    end
  end
end