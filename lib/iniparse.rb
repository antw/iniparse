require 'rubygems'
require 'extlib'

dir = Pathname(__FILE__).dirname.expand_path / 'iniparse'

require dir / 'line_collection'
require dir / 'line_types'
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

  module_function

  # Parse given given INI document source +source+.
  #
  # See IniParse::Parser.parse_raw
  #
  # ==== Parameters
  # source<String>:: The source from the INI document.
  #
  def parse_raw(source)
    IniParse::Parser.new(source).parse_raw
  end
end
