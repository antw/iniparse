module IniParse
  module Lines
    # A base class from which other line types should inherit.
    class Line
      # Default options for each Line.
      class_inheritable_reader :default_opts
      @default_opts = {
        :comment        => nil,
        :comment_sep    => nil,
        :comment_offset => 0,
        :indent         => nil
      }.freeze

      # Holds options for this line.
      attr_accessor :opts

      # ==== Parameters
      # opts<Hash>:: Extra options for the line.
      #
      def initialize(opts = {})
        @opts = if opts.empty?
          self.default_opts
        else
          self.default_opts.merge(opts)
        end
      end

      # Returns the inline comment for this line. Includes the comment
      # separator at the beginning of the string.
      def comment
        unless @opts[:comment].blank?
          '%s %s' % [@opts[:comment_sep], @opts[:comment]]
        end
      end

      # Returns this line as a string as it would be represented in an INI
      # document.
      def to_ini
        ini = line_contents
        ini = @opts[:indent] + ini if @opts[:indent]

        unless @opts[:comment].blank?
          ini += ' ' unless ini.blank?
          ini  = ini.ljust(opts[:comment_offset])
          ini += comment
        end

        ini
      end

      # Parses a given line from an INI document.
      #
      # ==== Returns
      # Line:: If the line matched a Line type, it will be returned.
      # nil::  nil is returned if there was no match.
      #
      def self.parse(line, opts)
        raise NotImplementedError, <<-EOS.compress_lines
          Line is an abstract class from which other line types should
          inherit; please don't use it directly.
        EOS
      end

      # Takes a line from an INI document, strips any leading and trailing
      # whitespace, and removes the inline comment, returning the updated line
      # and an options hash.
      #
      # An inline comment appears at the end of a line, separated from the
      # line content with a mandatory space (to differentiate from semi-colons
      # used in option values) and then a semi-colon or hash.
      #
      # Changes to +line+ are done to a copy, not the original string.
      #
      # ==== Parameters
      # line<String>:: A line from an INI document.
      #
      # ==== Returns
      # Array::
      #   Returns an array with two elements:
      #     1. The sanitized line.
      #     2. The options hash for use when creating a new Line instance.
      #
      # ==== Examples
      #   sanitize_line('  my line ; a comment', {})
      #     # => ['my line', { :comment => 'a comment', :comment_offset => 8,
      #             :indent => '  ' }]
      #
      def self.sanitize_line(line)
        strip_indent(*strip_comment(line.dup, {}))
      end

      #######
      private
      #######

      # Strips in inline comment from a line (or value), removes trailing
      # whitespace and sets the comment options as applicable.
      def self.strip_comment(line, opts)
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
      def self.strip_indent(line, opts)
        if m = /^(\s+).*$/.match(line)
          line.lstrip!
          opts[:indent] = m[1]
        end

        [line, opts]
      end

      # Returns the contents for this line.
      def line_contents
        ''
      end
    end

    # Represents a section header in an INI document. Section headers consist
    # of a string of characters wrapped in square brackets.
    #
    #   [section]
    #   key=value
    #   etc
    #   ...
    #
    class Section < Line
      @regex = /^\[        # Opening bracket
                 ([^\]]+)  # Section name
                 \]$       # Closing bracket
               /x

      attr_accessor :key
      attr_reader   :lines

      include Enumerable

      # ==== Parameters
      # key<String>:: The section name.
      # opts<Hash>::  Extra options for the line.
      #
      def initialize(key, opts = {})
        super(opts)
        @key   = key.to_s
        @lines = IniParse::OptionCollection.new
      end

      def self.parse(line, opts)
        if m = @regex.match(line)
          new(m[1], opts)
        end
      end

      # Returns this line as a string as it would be represented in an INI
      # document. Includes options, comments and blanks.
      def to_ini
        coll = lines.to_a

        if coll.any?
          super + $/ + coll.to_a.map do |line|
            if line.kind_of?(Array)
              line.map { |dup_line| dup_line.to_ini }.join($/)
            else
              line.to_ini
            end
          end.join($/)
        else
          super
        end
      end

      # Enumerates through each Option in this section.
      #
      # Does not yield blank and comment lines by default; if you want _all_
      # lines to be yielded, pass true.
      #
      # ==== Parameters
      # include_blank<Boolean>:: Include blank/comment lines?
      #
      def each(*args, &blk)
        @lines.each(*args, &blk)
      end

      # Adds a new option to this section, or updates an existing one.
      #
      # Note that +[]=+ has no knowledge of duplicate options and will happily
      # overwrite duplicate options with your new value.
      #
      #   section['an_option']
      #     # => ['duplicate one', 'duplicate two', ...]
      #   section['an_option'] = 'new value'
      #   section['an_option]
      #     # => 'new value'
      #
      # If you do not wish to overwrite duplicates, but wish instead for your
      # new option to be considered a duplicate, use +add_option+ instead.
      #
      def []=(key, value)
        @lines[key.to_s] = IniParse::Lines::Option.new(key.to_s, value)
      end

      # Returns the value of an option identified by +key+.
      #
      # Returns nil if there is no corresponding option. If the key provided
      # matches a set of duplicate options, an array will be returned containing
      # the value of each option.
      #
      def [](key)
        key = key.to_s

        if @lines.has_key?(key)
          if (match = @lines[key]).kind_of?(Array)
            match.map { |line| line.value }
          else
            match.value
          end
        end
      end

      # Like [], except instead of returning just the option value, it returns
      # the matching line instance.
      #
      # Will return an array of lines if the key matches a set of duplicates.
      #
      def option(key)
        @lines[key.to_s]
      end

      # Merges section +other+ into this one. If the section being merged into
      # this one contains options with the same key, they will be handled as
      # duplicates.
      #
      # ==== Parameters
      # other<IniParse::Section>:: The section to merge into this one.
      #
      def merge!(other)
        other.lines.each(true) do |line|
          if line.kind_of?(Array)
            line.each { |duplicate| @lines << duplicate }
          else
            @lines << line
          end
        end
      end

      #######
      private
      #######

      def line_contents
        '[%s]' % key
      end
    end

    # Represents probably the most common type of line in an INI document:
    # an option. Consists of a key and value, usually separated with an =.
    #
    #   key = value
    #
    class Option < Line
      @regex = /^(.*)     # Key
                 =
                 (.*?)$   # Value
               /x

      attr_accessor :key, :value

      # ==== Parameters
      # key<String>::   The option key.
      # value<String>:: The value for this option.
      # opts<Hash>::    Extra options for the line.
      #
      def initialize(key, value, opts = {})
        super(opts)
        @key, @value = key.to_s, value
      end

      def self.parse(line, opts)
        if m = @regex.match(line)
          new(m[1].strip, typecast(m[2].strip), opts)
        end
      end

      # Attempts to typecast values.
      def self.typecast(value)
        case value
          when /^\s*$/                                        then nil
          when /^-?(?:\d|[1-9]\d+)$/                          then Integer(value)
          when /^-?(?:\d|[1-9]\d+)(?:\.\d+)?(?:e[+-]?\d+)?$/i then Float(value)
          when /true/i                                        then true
          when /false/i                                       then false
          else                                                     value
        end
      end

      #######
      private
      #######

      def line_contents
        '%s = %s' % [key, value]
      end
    end

    # Represents a blank line. Used so that we can preserve blank lines when
    # writing back to the file.
    class Blank < Line
      def blank?
        true
      end

      def self.parse(line, opts)
        if line.blank?
          if opts[:comment].blank?
            new
          else
            Comment.new(opts)
          end
        end
      end
    end

    # Represents a comment. Comment lines begin with a semi-colon or hash.
    #
    #   ; this is a comment
    #   # also a comment
    #
    class Comment < Blank
    end
  end # Lines
end # IniParse