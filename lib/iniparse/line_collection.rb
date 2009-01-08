module IniParse
  # Like extlib's Dictionary, but storing the data in the array rather than
  # the Hash, with the hash storing the array index of each key. This allows
  # storage of items without a key (blanks and comments) while still allowing
  # fast lookups of those which do have a key (sections and options).
  class LineCollection
    include Enumerable

    def initialize
      @lines    = []
      @indicies = {}
    end

    # Retrive a value identified by +key+.
    def [](key)
      has_key?(key) ? @lines[ @indicies[key] ] : nil
    end

    # Set a +value+ identified by +key+.
    #
    # If a value with the given key already exists, the value will be replaced
    # with the new one, with the new value taking the position of the old.
    #
    def []=(key, value)
      key = key.to_s

      if has_key?(key)
        @lines[ @indicies[key] ] = value
      else
        @lines << value
        @indicies[key] = @lines.length - 1
      end
    end

    # Appends a line to the collection.
    #
    # Note that if you pass a line with a key already represented in the
    # collection, the old item will be replaced.
    #
    def <<(line)
      line.blank? ? (@lines << line) : (self[line.key] = line) ; self
    end

    alias_method :push, :<<

    # Enumerates through the collection.
    #
    # By default #each does not yield blank and comment lines.
    #
    # ==== Parameters
    # include_blank<Boolean>:: Include blank/comment lines?
    #
    def each(include_blank = false)
      @lines.each do |line|
        yield(line) if include_blank || (! line.blank?)
      end
    end

    # Removes the value identified by +key+.
    def delete(key)
      unless (idx = @indicies[key]).nil?
        @indicies.delete(key)
        @indicies.each { |k,v| @indicies[k] = v -= 1 if v > idx }
        @lines.delete_at(idx)
      end
    end

    # Returns whether +key+ is in the collection.
    def has_key?(*args)
      @indicies.has_key?(*args)
    end

    # Returns this collection as an array. Includes blank and comment lines.
    def to_a
      @lines.dup
    end

    # Returns this collection as a hash. Does not contain blank and comment
    # lines.
    def to_hash
      Hash[ map { |line| [line.key, line] } ]
    end

    alias_method :to_h, :to_hash
  end

  # A subclass of LineCollection used for storing (mainly) Option instances
  # contained within a Section.
  class OptionCollection < LineCollection
    # Appends a line to the collection.
    #
    # If you push an Option with a key already represented in the collection,
    # the previous Option will not be overwritten, but treated as a duplicate.
    #
    # ==== Parameters
    # line<IniParse::LineType::Line>:: The line to be added to this section.
    #
    def <<(line)
      if line.kind_of?(IniParse::Lines::Section)
        raise IniParse::LineNotAllowed,
          "You can't add a Section to an OptionCollection."
      end

      if line.blank? || (! has_key?(line.key))
        super # Adding a comment or blank line.
      else
        self[line.key] = [self[line.key], line].flatten
      end

      self
    end
  end

  # A subclass of LineCollection used for storing (mainly) Section instances
  # which, when put together, constitute a Document.
  class SectionCollection < LineCollection
    def <<(line)
      if line.kind_of?(IniParse::Lines::Option)
        raise IniParse::LineNotAllowed,
          "You can't add an Option to a SectionCollection."
      end

      if line.blank? || (! has_key?(line.key))
        super # Adding a comment or blank line.
      else
        self[line.key].merge!(line)
      end

      self
    end
  end
end
