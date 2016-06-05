require 'spec_helper'

# Tests parsing of multiple lines, in context, using #parse.

describe 'Parsing a document' do
  describe 'when a comment preceeds a single section and option' do
    before(:all) do
      @doc = IniParse::Parser.new(fixture(:comment_before_section)).parse
    end

    it 'should have a comment as the first line' do
      expect(@doc.lines.to_a.first).to be_kind_of(IniParse::Lines::Comment)
    end

    it 'should have one section' do
      expect(@doc.lines.keys).to eq(['first_section'])
    end

    it 'should have one option belonging to `first_section`' do
      expect(@doc['first_section']['key']).to eq('value')
    end
  end

  it 'should allow blank lines to preceed the first section' do
    expect {
      @doc = IniParse::Parser.new(fixture(:blank_before_section)).parse
    }.not_to raise_error

    expect(@doc.lines.to_a.first).to be_kind_of(IniParse::Lines::Blank)
  end

  it 'should allow a blank line to belong to a section' do
    expect {
      @doc = IniParse::Parser.new(fixture(:blank_in_section)).parse
    }.not_to raise_error

    expect(@doc['first_section'].lines.to_a.first).to be_kind_of(IniParse::Lines::Blank)
  end

  it 'should permit comments on their own line' do
    expect {
      @doc = IniParse::Parser.new(fixture(:comment_line)).parse
    }.not_to raise_error

    line = @doc['first_section'].lines.to_a.first
    expect(line.comment).to eql('; block comment ;')
  end

  it 'should permit options before the first section' do
    doc = IniParse::Parser.new(fixture(:option_before_section)).parse

    expect(doc.lines).to have_key('__anonymous__')
    expect(doc['__anonymous__']['foo']).to eql('bar')
    expect(doc['foo']['another']).to eql('thing')
  end

  it 'should raise ParseError if a line could not be parsed' do
    expect { IniParse::Parser.new(fixture(:invalid_line)).parse }.to \
      raise_error(IniParse::ParseError)
  end

  describe 'when a section name contains "="' do
    before(:all) do
      @doc = IniParse::Parser.new(fixture(:section_with_equals)).parse
    end

    it 'should have two sections' do
      expect(@doc.lines.to_a.length).to eq(2)
    end

    it 'should have one section' do
      expect(@doc.lines.keys).to eq(['first_section = name',
                                 'another_section = a name'])
    end

    it 'should have one option belonging to `first_section = name`' do
      expect(@doc['first_section = name']['key']).to eq('value')
    end

    it 'should have one option belonging to `another_section = a name`' do
      expect(@doc['another_section = a name']['another']).to eq('thing')
    end
  end

  describe 'when a document contains a section multiple times' do
    before(:all) do
      @doc = IniParse::Parser.new(fixture(:duplicate_section)).parse
    end

    it 'should only add the section once' do
      # "first_section" and "second_section".
      expect(@doc.lines.to_a.length).to eq(2)
    end

    it 'should retain values from the first time' do
      expect(@doc['first_section']['key']).to eq('value')
    end

    it 'should add new keys' do
      expect(@doc['first_section']['third']).to eq('fourth')
    end

    it 'should merge in duplicate keys' do
      expect(@doc['first_section']['another']).to eq(%w( thing again ))
    end
  end
end
