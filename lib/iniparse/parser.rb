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
    # IniParse::LineCollection
    #
    def parse_raw
      current_section = nil
      parsed_lines    = []

      @source.split("\n").each_with_index do |line, i|
        sanitized, opts = IniParse::Lines::Line.sanitize_line(line)

        parsed = @@parse_types.reduce(nil) do |memo, type|
          memo ||= type.parse(sanitized, opts)
        end

        case parsed
        when IniParse::Lines::Section
          current_section = parsed
        when IniParse::Lines::Option
          if current_section.nil?
            # INI documents can't have options without a parent section.
            raise NoSectionError, <<-EOS.compress_lines
              Your INI document contains an option before the first section is
              declared: '#{line}' (line #{i+1}).
            EOS
          end
        when IniParse::Lines::Blank, IniParse::Lines::Comment
          # Do nothing at the moment,
        else
          raise IniParse::ParseError, <<-EOS.compress_lines
            A line of your INI document could not be parsed to a LineType:
            '#{line}' (line #{i+1}).
          EOS
        end

        # All done, add the line to the stack.
        parsed_lines << parsed
      end

      parsed_lines
    end
  end
end