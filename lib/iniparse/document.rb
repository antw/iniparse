module IniParse
  # Represents an INI document.
  class Document
    attr_reader :lines

    # Creates a new Document instance.
    def initialize
      @lines = IniParse::SectionCollection.new
    end

    # Enumerates through each Section in this document.
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

    # Returns the section identified by +key+.
    #
    # Returns nil if there is no Section with the given key.
    #
    def [](key)
      @lines[key.to_s]
    end

    # Returns this document as a string suitable for saving to a file.
    def to_ini
      @lines.to_a.map { |line| line.to_ini }.join($/)
    end
  end
end
