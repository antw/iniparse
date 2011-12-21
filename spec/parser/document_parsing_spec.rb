require 'spec_helper'

# Tests parsing of multiple lines, in context, using #parse.

describe 'Parsing a document' do
  describe 'when a comment preceeds a single section and option' do
    before(:all) do
      @doc = IniParse::Parser.new(fixture(:comment_before_section)).parse
    end

    it 'should have a comment as the first line' do
      @doc.lines.to_a.first.should be_kind_of(IniParse::Lines::Comment)
    end

    it 'should have one section' do
      @doc.lines.keys.should == ['first_section']
    end

    it 'should have one option belonging to `first_section`' do
      @doc['first_section']['key'].should == 'value'
    end
  end

  it 'should allow blank lines to preceed the first section' do
    lambda {
      @doc = IniParse::Parser.new(fixture(:blank_before_section)).parse
    }.should_not raise_error

    @doc.lines.to_a.first.should be_kind_of(IniParse::Lines::Blank)
  end

  it 'should allow a blank line to belong to a section' do
    lambda {
      @doc = IniParse::Parser.new(fixture(:blank_in_section)).parse
    }.should_not raise_error

    @doc['first_section'].lines.to_a.first.should be_kind_of(IniParse::Lines::Blank)
  end

  it 'should raise an error if an option preceeds the first section' do
    lambda {
      IniParse::Parser.new(fixture(:option_before_section)).parse
    }.should raise_error(IniParse::NoSectionError)
  end

  it 'should raise ParseError if a line could not be parsed' do
    lambda { IniParse::Parser.new(fixture(:invalid_line)).parse }.should \
      raise_error(IniParse::ParseError)
  end

  describe 'when a section name contains "="' do
    before(:all) do
      @doc = IniParse::Parser.new(fixture(:section_with_equals)).parse
    end

    it 'should have two sections' do
      @doc.lines.to_a.length.should == 2
    end

    it 'should have one section' do
      @doc.lines.keys.should == ['first_section = name',
                                 'another_section = a name']
    end

    it 'should have one option belonging to `first_section = name`' do
      @doc['first_section = name']['key'].should == 'value'
    end

    it 'should have one option belonging to `another_section = a name`' do
      @doc['another_section = a name']['another'].should == 'thing'
    end
  end
end
