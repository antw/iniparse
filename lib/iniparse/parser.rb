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
      document        = IniParse::Document.new
      current_section = nil

      @source.split("\n").each_with_index do |line, i|
        sanitized, opts = IniParse::Lines::Line.sanitize_line(line)

        parsed = @@parse_types.reduce(nil) do |memo, type|
          memo ||= type.parse(sanitized, opts)
        end

        case parsed
        when IniParse::Lines::Section
          current_section = parsed
          document.lines << parsed
        when IniParse::Lines::Option
          if current_section.nil?
            # INI documents can't have options without a parent section.
            raise NoSectionError, <<-EOS.compress_lines
              Your INI document contains an option before the first section is
              declared: '#{line}' (line #{i+1}).
            EOS
          end
          current_section.lines << parsed
        when IniParse::Lines::Blank, IniParse::Lines::Comment
          ((current_section && current_section.lines) || document.lines) << parsed
        else
          raise IniParse::ParseError, <<-EOS.compress_lines
            A line of your INI document could not be parsed to a LineType:
            '#{line}' (line #{i+1}).
          EOS
        end
      end

      document
    end
  end
end