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
      @source = source.dup
    end

    # Parses the source string and returns the resulting data structure.
    #
    # ==== Returns
    # IniParse::Document
    #
    def parse
      IniParse::Generator.gen do |generator|
        @source.split("\n", -1).each do |line|
          generator.send(*Parser.parse_line(line))
        end
      end
    end

    class << self
      # Takes a raw line from an INI document, striping out any inline
      # comment, and indent, then returns the appropriate tuple so that the
      # Generator instance can add the line to the Document.
      #
      # ==== Raises
      # IniParse::ParseError: If the line could not be parsed.
      #
      def parse_line(line)
        sanitized, opts = strip_indent(*strip_comment(line, {}))

        parsed = nil
        @@parse_types.each do |type|
          break if (parsed = type.parse(sanitized, opts))
        end

        if parsed.nil?
          raise IniParse::ParseError, <<-EOS.compress_lines
            A line of your INI document could not be parsed to a LineType:
            '#{line}'.
          EOS
        end

        parsed
      end

      #######
      private
      #######

      # Strips in inline comment from a line (or value), removes trailing
      # whitespace and sets the comment options as applicable.
      def strip_comment(line, opts)
        if m = /^(.*?)(?:\s+(;|\#)\s*(.*))$/.match(line) ||
           m = /(^)(?:(;|\#)\s*(.*))$/.match(line) # Comment lines.
          opts[:comment] = m[3].rstrip
          opts[:comment_sep] = m[2]
          # Remove the line content (since an option value may contain a
          # semi-colon) _then_ get the index of the comment separator.
          opts[:comment_offset] =
            line[(m[1].length..-1)].index(m[2]) + m[1].length

          line = m[1]
        else
          line.rstrip!
        end

        [line, opts]
      end

      # Removes any leading whitespace from a line, and adds it to the options
      # hash.
      def strip_indent(line, opts)
        if m = /^(\s+).*$/.match(line)
          line.lstrip!
          opts[:indent] = m[1]
        end

        [line, opts]
      end
    end
  end # Parser
end # IniParse
