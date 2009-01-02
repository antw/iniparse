require File.dirname(__FILE__) + '/spec_helper'

describe 'IniParse::Parser#parse_raw' do
  def parse_raw(source)
    IniParse::Parser.new(source).parse_raw
  end

  it 'should return an array' do
    parse_raw('').should == []
  end

  it 'should allow comments to preceed the first section' do
    lambda { parse_raw(fixture(:comment_before_section)) }.should_not raise_error
  end

  it 'should allow blank lines to preceed the first section' do
    lambda { parse_raw(fixture(:blank_before_section)) }.should_not raise_error
  end

  it 'should raise an error if an option preceeds the first section' do
    lambda { parse_raw(fixture(:option_before_section)) }.should \
      raise_error(IniParse::NoSectionError)
  end
  
  it 'should raise ParseError if a line could not be parsed' do
    lambda { parse_raw(fixture(:invalid_line)) }.should \
      raise_error(IniParse::ParseError)
  end
end