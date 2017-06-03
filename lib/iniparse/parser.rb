module IniParse
  @@multiline = false
  @@ml_current = nil
  @@ml_join = nil
  class Parser

    # Returns the line types.
    #
    # ==== Returns
    # Array
    #
    def self.parse_types
      @@parse_types ||= []
    end

    # Sets the line types. Handy if you want to add your own custom Line
    # classes.
    #
    # ==== Parameters
    # types<Array[IniParse::Lines::Line]>:: An array containing Line classes.
    #
    def self.parse_types=(types)
      parse_types.replace(types)
    end

    self.parse_types = [ IniParse::Lines::Section,
      IniParse::Lines::Option, IniParse::Lines::Blank ]

    # Creates a new Parser instance for parsing string +source+.
    #
    # ==== Parameters
    # source<String>:: The source string.
    #
    def initialize(source)
      @source = source.dup.sub(/\n\z/m,'')
      @@multiline = false
    end

    # Parses the source string and returns the resulting data structure.
    #
    # ==== Returns
    # IniParse::Document
    #
    def parse
      IniParse::Generator.gen do |generator|
        @source.split("\n", -1).each do |line|
          parsed = Parser.parse_line(line)
          generator.send(*parsed) unless @@multiline
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
          if @@multiline
            parsed = @@ml_current
            parsed[2] << "#{@@ml_join}#{sanitized}"
            if @@ml_join == ''
              parsed[3][:comment] << "#{opts[:comment_prefix]}#{opts[:comment]}"
            else
              parsed[3] = opts
            end
            @@multiline = false
            @@ml_current = nil
            @@ml_join = nil
          else
            raise IniParse::ParseError,
              "A line of your INI document could not be parsed to a " \
              "LineType: '#{line}'."
          end
        end

        if parsed[0] == :option && parsed[2].kind_of?(String)
          if parsed[2][-1,1] == '\\' && parsed[2][-2,2] != '\\\\'
            parsed[2].slice!(-1,1)
            @@multiline = true
            @@ml_current = parsed
            @@ml_join = ''
          elsif /^("[^"]*)\z/.match(parsed[2])
            @@multiline = true
            @@ml_current = parsed
            @@ml_join = "\n"
          end
        end

        parsed
      end

      #######
      private
      #######

      # Strips in inline comment from a line (or value), removes trailing
      # whitespace and sets the comment options as applicable.
      def strip_comment(line, opts)
        if m = /^(^)(?:(;|\#)(\s*)(.*))$$/.match(line) ||
           m = /^(.*?)(?:\s+(;|\#)(\s*)(.*))$/.match(line) # Comment lines.
          opts[:comment] = m[4].rstrip
          opts[:comment_prefix] = m[3]
          opts[:comment_sep] = m[2]
          # Remove the line content (since an option value may contain a
          # semi-colon) _then_ get the index of the comment separator.
          opts[:comment_offset] =
            line[(m[1].length..-1)].index(m[2]) + m[1].length

          line = m[1]
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
