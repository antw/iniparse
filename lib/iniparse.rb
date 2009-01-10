require 'rubygems'
require 'extlib'

dir = Pathname(__FILE__).dirname.expand_path / 'iniparse'

require dir / 'document'
require dir / 'line_collection'
require dir / 'lines'
require dir / 'parser'
require dir / 'version'

module IniParse
  # A base class for IniParse errors.
  class IniParseError < StandardError; end

  # Raised if an error occurs parsing an INI document.
  class ParseError < IniParseError; end

  # Raised when an option line is found during parsing before the first
  # section.
  class NoSectionError < ParseError; end

  # Raised when a line is added to a collection which isn't allowed (e.g.
  # adding a Section line into an OptionCollection).
  class LineNotAllowed < IniParseError; end

  module_function

  # Parse given given INI document source +source+.
  #
  # See IniParse::Parser.parse
  #
  # ==== Parameters
  # source<String>:: The source from the INI document.
  #
  # ==== Returns
  # IniParse::Document
  #
  def parse(source)
    IniParse::Parser.new(source).parse
  end

  # Opens the file at +path+, reads and parses it's contents.
  #
  # ==== Parameters
  # path<String>:: The path to the INI document.
  #
  # ==== Returns
  # IniParse::Document
  #
  def open(path)
    IniParse::Parser.new(File.read(path)).parse(
      IniParse::Document.new(path)
    )
  end
end
