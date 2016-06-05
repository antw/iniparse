require 'spec_helper'

# Tests parsing of individual, out of context, line types using #parse_line.

describe 'Parsing a line' do
  it 'should strip leading whitespace and set the :indent option' do
    expect(IniParse::Parser.parse_line('  [section]')).to \
      be_section_tuple(:any, {:indent => '  '})
  end

  it 'should raise an error if the line could not be matched' do
    expect { IniParse::Parser.parse_line('invalid line') }.to \
      raise_error(IniParse::ParseError)
  end

  it 'should parse using the types set in IniParse::Parser.parse_types' do
    begin
      # Remove last type.
      type = IniParse::Parser.parse_types.pop
      expect(type).not_to receive(:parse)
      IniParse::Parser.parse_line('[section]')
    ensure
      IniParse::Parser.parse_types << type
    end
  end

  # --
  # ==========================================================================
  #   Option lines.
  # ==========================================================================
  # ++

  describe 'with "k = v"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('k = v')
    end

    it 'should return an option tuple' do
      expect(@tuple).to be_option_tuple('k', 'v')
    end

    it 'should set no indent, comment, offset or separator' do
      expect(@tuple.last[:indent]).to be_nil
      expect(@tuple.last[:comment]).to be_nil
      expect(@tuple.last[:comment_offset]).to be_nil
      expect(@tuple.last[:comment_sep]).to be_nil
    end
  end

  describe 'with "k = a value with spaces"' do
    it 'should return an option tuple' do
      expect(IniParse::Parser.parse_line('k = a value with spaces')).to \
        be_option_tuple('k', 'a value with spaces')
    end
  end

  describe 'with "k = v ; a comment "' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('k = v ; a comment')
    end

    it 'should return an option tuple' do
      expect(@tuple).to be_option_tuple('k', 'v')
    end

    it 'should set the comment to "a comment"' do
      expect(@tuple).to be_option_tuple(:any, :any, :comment => 'a comment')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_option_tuple(:any, :any, :comment_sep => ';')
    end

    it 'should set the comment offset to 6' do
      expect(@tuple).to be_option_tuple(:any, :any, :comment_offset => 6)
    end
  end

  describe 'with "k = v;w;x y;z"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('k = v;w;x y;z')
    end

    it 'should return an option tuple with the correct value' do
      expect(@tuple).to be_option_tuple(:any, 'v;w;x y;z')
    end

    it 'should not set a comment' do
      expect(@tuple.last[:comment]).to be_nil
      expect(@tuple.last[:comment_offset]).to be_nil
      expect(@tuple.last[:comment_sep]).to be_nil
    end
  end

  describe 'with "k = v;w ; a comment"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('k = v;w ; a comment')
    end

    it 'should return an option tuple with the correct value' do
      expect(@tuple).to be_option_tuple(:any, 'v;w')
    end

    it 'should set the comment to "a comment"' do
      expect(@tuple).to be_option_tuple(:any, :any, :comment => 'a comment')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_option_tuple(:any, :any, :comment_sep => ';')
    end

    it 'should set the comment offset to 8' do
      expect(@tuple).to be_option_tuple(:any, :any, :comment_offset => 8)
    end
  end

  describe 'with "key=value"' do
    it 'should return an option tuple with the correct key and value' do
      expect(IniParse::Parser.parse_line('key=value')).to \
        be_option_tuple('key', 'value')
    end
  end

  describe 'with "key= value"' do
    it 'should return an option tuple with the correct key and value' do
      expect(IniParse::Parser.parse_line('key= value')).to \
        be_option_tuple('key', 'value')
    end
  end

  describe 'with "key =value"' do
    it 'should return an option tuple with the correct key and value' do
      expect(IniParse::Parser.parse_line('key =value')).to \
        be_option_tuple('key', 'value')
    end
  end

  describe 'with "key   =   value"' do
    it 'should return an option tuple with the correct key and value' do
      expect(IniParse::Parser.parse_line('key   =   value')).to \
        be_option_tuple('key', 'value')
    end
  end

  describe 'with "key ="' do
    it 'should return an option tuple with the correct key' do
      expect(IniParse::Parser.parse_line('key =')).to \
        be_option_tuple('key')
    end

    it 'should set the option value to nil' do
      expect(IniParse::Parser.parse_line('key =')).to \
        be_option_tuple(:any, nil)
    end
  end


  describe 'with "key = EEjDDJJjDJDJD233232=="' do
    it 'should include the "equals" in the option value' do
      expect(IniParse::Parser.parse_line('key = EEjDDJJjDJDJD233232==')).to \
        be_option_tuple('key', 'EEjDDJJjDJDJD233232==')
    end
  end

  describe 'with "key = ==EEjDDJJjDJDJD233232"' do
    it 'should include the "equals" in the option value' do
      expect(IniParse::Parser.parse_line('key = ==EEjDDJJjDJDJD233232')).to \
        be_option_tuple('key', '==EEjDDJJjDJDJD233232')
    end
  end

  describe 'with "key.two = value"' do
    it 'should return an option tuple with the correct key' do
      expect(IniParse::Parser.parse_line('key.two = value')).to \
        be_option_tuple('key.two')
    end
  end

  describe 'with "key/with/slashes = value"' do
    it 'should return an option tuple with the correct key' do
      expect(IniParse::Parser.parse_line('key/with/slashes = value')).to \
        be_option_tuple('key/with/slashes', 'value')
    end
  end

  describe 'with "key_with_underscores = value"' do
    it 'should return an option tuple with the correct key' do
      expect(IniParse::Parser.parse_line('key_with_underscores = value')).to \
        be_option_tuple('key_with_underscores', 'value')
    end
  end

  describe 'with "key-with-dashes = value"' do
    it 'should return an option tuple with the correct key' do
      expect(IniParse::Parser.parse_line('key-with-dashes = value')).to \
        be_option_tuple('key-with-dashes', 'value')
    end
  end

  describe 'with "key with spaces = value"' do
    it 'should return an option tuple with the correct key' do
      expect(IniParse::Parser.parse_line('key with spaces = value')).to \
        be_option_tuple('key with spaces', 'value')
    end
  end

  # --
  # ==========================================================================
  #   Section lines.
  # ==========================================================================
  # ++

  describe 'with "[section]"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('[section]')
    end

    it 'should return a section tuple' do
      expect(@tuple).to be_section_tuple('section')
    end

    it 'should set no indent, comment, offset or separator' do
      expect(@tuple.last[:indent]).to be_nil
      expect(@tuple.last[:comment]).to be_nil
      expect(@tuple.last[:comment_offset]).to be_nil
      expect(@tuple.last[:comment_sep]).to be_nil
    end
  end

  describe 'with "[section with whitespace]"' do
    it 'should return a section tuple with the correct key' do
      expect(IniParse::Parser.parse_line('[section with whitespace]')).to \
        be_section_tuple('section with whitespace')
    end
  end

  describe 'with "[  section with surounding whitespace  ]"' do
    it 'should return a section tuple with the correct key' do
      expect(IniParse::Parser.parse_line('[  section with surounding whitespace  ]')).to \
        be_section_tuple('  section with surounding whitespace  ')
    end
  end

  describe 'with "[section] ; a comment"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('[section] ; a comment')
    end

    it 'should return a section tuple' do
      expect(@tuple).to be_section_tuple('section')
    end

    it 'should set the comment to "a comment"' do
      expect(@tuple).to be_section_tuple(:any, :comment => 'a comment')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_section_tuple(:any, :comment_sep => ';')
    end

    it 'should set the comment offset to 10' do
      expect(@tuple).to be_section_tuple(:any, :comment_offset => 10)
    end
  end

  describe 'with "[section;with#comment;chars]"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('[section;with#comment;chars]')
    end

    it 'should return a section tuple with the correct key' do
      expect(@tuple).to be_section_tuple('section;with#comment;chars')
    end

    it 'should not set a comment' do
      expect(@tuple.last[:indent]).to be_nil
      expect(@tuple.last[:comment]).to be_nil
      expect(@tuple.last[:comment_offset]).to be_nil
      expect(@tuple.last[:comment_sep]).to be_nil
    end
  end

  describe 'with "[section;with#comment;chars] ; a comment"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('[section;with#comment;chars] ; a comment')
    end

    it 'should return a section tuple with the correct key' do
      expect(@tuple).to be_section_tuple('section;with#comment;chars')
    end

    it 'should set the comment to "a comment"' do
      expect(@tuple).to be_section_tuple(:any, :comment => 'a comment')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_section_tuple(:any, :comment_sep => ';')
    end

    it 'should set the comment offset to 29' do
      expect(@tuple).to be_section_tuple(:any, :comment_offset => 29)
    end
  end

  # --
  # ==========================================================================
  #   Comment lines.
  # ==========================================================================
  # ++

  describe 'with "; a comment"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line('; a comment')
    end

    it 'should return a comment tuple with the correct comment' do
      expect(@tuple).to be_comment_tuple('a comment')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_comment_tuple(:any, :comment_sep => ';')
    end

    it 'should set the comment offset to 0' do
      expect(@tuple).to be_comment_tuple(:any, :comment_offset => 0)
    end
  end

  describe 'with " ; a comment"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line(' ; a comment')
    end

    it 'should return a comment tuple with the correct comment' do
      expect(@tuple).to be_comment_tuple('a comment')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_comment_tuple(:any, :comment_sep => ';')
    end

    it 'should set the comment offset to 1' do
      expect(@tuple).to be_comment_tuple(:any, :comment_offset => 1)
    end
  end

  describe 'with ";"' do
    before(:all) do
      @tuple = IniParse::Parser.parse_line(';')
    end

    it 'should return a comment tuple with an empty value' do
      expect(@tuple).to be_comment_tuple('')
    end

    it 'should set the comment separator to ";"' do
      expect(@tuple).to be_comment_tuple(:any, :comment_sep => ';')
    end

    it 'should set the comment offset to 0' do
      expect(@tuple).to be_comment_tuple(:any, :comment_offset => 0)
    end
  end

  # --
  # ==========================================================================
  #   Blank lines.
  # ==========================================================================
  # ++

  describe 'with ""' do
    it 'should return a blank tuple' do
      expect(IniParse::Parser.parse_line('')).to be_blank_tuple
    end
  end

  describe 'with " "' do
    it 'should return a blank tuple' do
      expect(IniParse::Parser.parse_line(' ')).to be_blank_tuple
    end
  end
end
