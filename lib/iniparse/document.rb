module IniParse
  # Represents an INI document.
  class Document
    include Enumerable

    attr_reader   :lines
    attr_accessor :path

    # Creates a new Document instance.
    def initialize(path = nil)
      @path  = path
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

    # Returns true if a section with the given +key+ exists in this document.
    def has_section?(key)
      @lines.has_key?(key.to_s)
    end

    # Saves a copy of this Document to disk.
    #
    # If a path was supplied when the Document was initialized then nothing
    # needs to be given to Document#save. If Document was not given a file
    # path, or you wish to save the document elsewhere, supply a path when
    # calling Document#save.
    #
    # ==== Parameters
    # path<String>:: A path to which this document will be saved.
    #
    # ==== Raises
    # IniParseError:: If your document couldn't be saved.
    #
    def save(path = nil)
      @path = path if path
      raise IniParseError, 'No path given to Document#save' if @path !~ /\S/
      File.open(@path, 'w') { |f| f.write(self.to_ini) }
    end
  end
end
