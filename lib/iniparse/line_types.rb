module IniParse
  module LineTypes
    # A base class from which other line types should inherit.
    class Line
      # Default options for each Line.
      class_inheritable_reader :default_opts
      @default_opts = {
        :comment        => nil,
        :comment_sep    => nil,
        :comment_offset => 0,
        :indent         => nil,
        :line           => nil
      }.freeze

      # Holds options for this line.
      attr_accessor :opts

      # Parses a given line from an INI document.
      #
      # ==== Returns
      # Line:: If the line matched a Line type, it will be returned.
      # nil::  nil is returned if there was no match.
      #
      def self.parse(line, opts)
        raise NameError, <<-EOS.compress_lines
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
        line, opts = strip_comment(line.dup, @default_opts)
        line, opts = strip_indent(line, opts)
        [line.rstrip, opts]
      end

      #######
      private
      #######

      # Strips in inline comment from a line (or value), removes trailing
      # whitespace and sets the comment options as applicable.
      def self.strip_comment(line, opts)
        if m = /^(.*?)(?:\s+(;|\#)\s*(.*))$/.match(line)
          opts = opts.merge(
            :comment        => m[3].rstrip,
            :comment_sep    => m[2],
            # Remove the line content (since an option value may contain a
            # semi-colon) _then_ get the index of the comment separator.
            :comment_offset => line[(m[1].length..-1)].index(m[2]) + m[1].length
          )

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
          opts = opts.merge(:indent => m[1])
        end

        [line, opts]
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

      attr_accessor :name

      # ==== Parameters
      # name<String>:: The section name.
      # opts<Hash>::   Extra options for the line.
      #
      def initialize(name, opts)
        @name, @opts = name, opts
      end

      def self.parse(line, opts)
        if m = @regex.match(line)
          new(m[1], opts)
        end
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
      def initialize(key, value, opts)
        @key, @value, @opts = key, value, opts
      end

      def self.parse(line, opts)
        if m = @regex.match(line)
          new(m[1], m[2], opts)
        end
      end
    end

    # Represents a blank line. Used so that we can preserve blank lines when
    # writing back to the file.
    class Blank < Line
      # ==== Parameters
      # opts<Hash>:: Extra options for the line.
      #
      def initialize(opts)
        @opts = opts
      end

      def self.parse(line, opts)
        if line.blank?
          if opts[:comment].blank?
            new(opts)
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
  end # LineTypes
end # IniParse