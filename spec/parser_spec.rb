require File.dirname(__FILE__) + '/spec_helper'

describe 'IniParse::Parser#parse' do
  def parse(source)
    IniParse::Parser.new(source).parse
  end

  it 'should return an IniParse::Document' do
    parse('').should be_kind_of(IniParse::Document)
  end

  it "should set the Document's path to the one given" do
    IniParse::Parser.new('').parse('/my/file.ini').path.should == '/my/file.ini'
  end

  describe 'with :comment_before_section fixture' do
    before(:all) { @doc = parse(fixture(:comment_before_section)) }

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

  it 'should allow comments to preceed the first section' do
    lambda { parse(fixture(:comment_before_section)) }.should_not raise_error
  end

  it 'should allow blank lines to preceed the first section' do
    lambda { @doc = parse(fixture(:blank_before_section)) }.should_not raise_error
    @doc.lines.to_a.first.should be_kind_of(IniParse::Lines::Blank)
  end

  it 'should allow a blank line to belong to a section' do
    lambda { @doc = parse(fixture(:blank_in_section)) }.should_not raise_error
    @doc['first_section'].lines.to_a.first.should be_kind_of(IniParse::Lines::Blank)
  end

  it 'should raise an error if an option preceeds the first section' do
    lambda { parse(fixture(:option_before_section)) }.should \
      raise_error(IniParse::NoSectionError)
  end

  it 'should raise ParseError if a line could not be parsed' do
    lambda { parse(fixture(:invalid_line)) }.should \
      raise_error(IniParse::ParseError)
  end
end