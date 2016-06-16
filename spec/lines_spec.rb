require 'spec_helper'

module IniParse::Test
  class FakeLine
    include IniParse::Lines::Line

    def line_contents
      'fake line'
    end
  end
end

describe "IniParse::Lines::Line module" do
  describe '#to_ini' do
    it 'should return +line_contents+' do
      expect(IniParse::Test::FakeLine.new.to_ini).to eq('fake line')
    end

    it 'should preserve line indents' do
      expect(IniParse::Test::FakeLine.new(
        :indent => '    '
      ).to_ini).to eq('    fake line')
    end

    describe 'when a comment is set' do
      it 'should correctly include the comment' do
        expect(IniParse::Test::FakeLine.new(
          :comment => 'comment', :comment_sep => ';', :comment_offset => 10
        ).to_ini).to eq('fake line ; comment')
      end

      it 'should correctly indent the comment' do
        expect(IniParse::Test::FakeLine.new(
          :comment => 'comment', :comment_sep => ';', :comment_offset => 15
        ).to_ini).to eq('fake line      ; comment')
      end

      it 'should use ";" as a default comment seperator' do
        expect(IniParse::Test::FakeLine.new(
          :comment => 'comment'
        ).to_ini).to eq('fake line ; comment')
      end

      it 'should use the correct seperator' do
        expect(IniParse::Test::FakeLine.new(
          :comment => 'comment', :comment_sep => '#'
        ).to_ini).to eq('fake line # comment')
      end

      it 'should use the ensure a space is added before the comment seperator' do
        expect(IniParse::Test::FakeLine.new(
          :comment => 'comment', :comment_sep => ';', :comment_offset => 0
        ).to_ini).to eq('fake line ; comment')
      end

      it 'should not add an extra space if the line is blank' do
        line = IniParse::Test::FakeLine.new(
          :comment => 'comment', :comment_sep => ';', :comment_offset => 0
        )

        allow(line).to receive(:line_contents).and_return('')
        expect(line.to_ini).to eq('; comment')
      end
    end

    describe 'when no comment is set' do
      it 'should not add trailing space if :comment_offset has a value' do
        expect(IniParse::Test::FakeLine.new(:comment_offset => 10).to_ini).to eq('fake line')
      end

      it 'should not add a comment seperator :comment_sep has a value' do
        expect(IniParse::Test::FakeLine.new(:comment_sep => ';').to_ini).to eq('fake line')
      end
    end
  end

  describe '#has_comment?' do
    it 'should return true if :comment has a non-blank value' do
      expect(IniParse::Test::FakeLine.new(:comment => 'comment')).to have_comment
    end

    it 'should return true if :comment has a blank value' do
      expect(IniParse::Test::FakeLine.new(:comment => '')).to have_comment
    end

    it 'should return false if :comment has a nil value' do
      expect(IniParse::Test::FakeLine.new).not_to have_comment
      expect(IniParse::Test::FakeLine.new(:comment => nil)).not_to have_comment
    end
  end
end

#
# Section
#

describe 'IniParse::Lines::Section' do
  before(:each) { @section = IniParse::Lines::Section.new('a section') }

  it 'should respond_to +lines+' do
    expect(@section).to respond_to(:lines)
  end

  it 'should not respond_to +lines=+' do
    expect(@section).not_to respond_to(:lines=)
  end

  it 'should include Enumerable' do
    expect(IniParse::Lines::Section.included_modules).to include(Enumerable)
  end

  describe '#initialize' do
    it 'should typecast the given key to a string' do
      expect(IniParse::Lines::Section.new(:symbol).key).to eq('symbol')
    end
  end

  describe '#option' do
    it 'should retrieve the line identified by the given key' do
      option = IniParse::Lines::Option.new('k', 'value one')
      @section.lines << option
      expect(@section.option('k')).to eq(option)
    end

    it 'should return nil if the given key does not exist' do
      expect(@section.option('does_not_exist')).to be_nil
    end
  end

  describe '#each' do
    it 'should call #each on +lines+' do
      expect(@section.lines).to receive(:each)
      @section.each { |l| }
    end
  end

  describe '#[]' do
    it 'should return nil if the given key does not exist' do
      expect(@section['k']).to be_nil
    end

    it 'should return a value if the given key exists' do
      @section.lines << IniParse::Lines::Option.new('k', 'v')
      expect(@section['k']).to eq('v')
    end

    it 'should return an array of values if the key is a duplicate' do
      @section.lines << IniParse::Lines::Option.new('k', 'v1')
      @section.lines << IniParse::Lines::Option.new('k', 'v2')
      @section.lines << IniParse::Lines::Option.new('k', 'v3')
      expect(@section['k']).to eq(['v1', 'v2', 'v3'])
    end

    it 'should typecast the key to a string' do
      @section.lines << IniParse::Lines::Option.new('k', 'v')
      expect(@section[:k]).to eq('v')
    end
  end

  describe '#[]=' do
    it 'should add a new Option with the given key and value' do
      @section['k'] = 'a value'
      expect(@section.option('k')).to be_kind_of(IniParse::Lines::Option)
      expect(@section['k']).to eq('a value')
    end

    it 'should update the Option if one already exists' do
      @section.lines << IniParse::Lines::Option.new('k', 'orig value')
      @section['k'] = 'new value'
      expect(@section['k']).to eq('new value')
    end

    it 'should replace the existing Option if it is an array' do
      @section.lines << IniParse::Lines::Option.new('k', 'v1')
      @section.lines << IniParse::Lines::Option.new('k', 'v2')
      @section['k'] = 'new value'
      expect(@section.option('k')).to be_kind_of(IniParse::Lines::Option)
      expect(@section['k']).to eq('new value')
    end

    it 'should typecast the key to a string' do
      @section[:k] = 'a value'
      expect(@section['k']).to eq('a value')
    end
  end

  describe '#merge!' do
    before(:each) do
      @section.lines << IniParse::Lines::Option.new('a', 'val1')
      @section.lines << IniParse::Lines::Blank.new
      @section.lines << IniParse::Lines::Comment.new
      @section.lines << IniParse::Lines::Option.new('b', 'val2')

      @new_section = IniParse::Lines::Section.new('new section')
    end

    it 'should merge options from the given Section into the receiver' do
      @new_section.lines << IniParse::Lines::Option.new('c', 'val3')
      @new_section.lines << IniParse::Lines::Option.new('d', 'val4')

      @section.merge!(@new_section)
      expect(@section['a']).to eq('val1')
      expect(@section['b']).to eq('val2')
      expect(@section['c']).to eq('val3')
      expect(@section['d']).to eq('val4')
    end

    it 'should handle duplicates' do
      @new_section.lines << IniParse::Lines::Option.new('a', 'val2')
      @section.merge!(@new_section)
      expect(@section['a']).to eq(['val1', 'val2'])
    end

    it 'should handle duplicates on both sides' do
      @section.lines << IniParse::Lines::Option.new('a', 'val2')
      @new_section.lines << IniParse::Lines::Option.new('a', 'val3')
      @new_section.lines << IniParse::Lines::Option.new('a', 'val4')

      @section.merge!(@new_section)
      expect(@section['a']).to eq(['val1', 'val2', 'val3', 'val4'])
    end

    it 'should copy blank lines' do
      @new_section.lines << IniParse::Lines::Blank.new
      @section.merge!(@new_section)
      line = nil
      @section.each(true) { |l| line = l }
      expect(line).to be_kind_of(IniParse::Lines::Blank)
    end

    it 'should copy comments' do
      @new_section.lines << IniParse::Lines::Comment.new
      @section.merge!(@new_section)
      line = nil
      @section.each(true) { |l| line = l }
      expect(line).to be_kind_of(IniParse::Lines::Comment)
    end
  end

  describe '#delete' do
    let(:opt_one) { IniParse::Lines::Option.new('a', 'b') }
    let(:opt_two) { IniParse::Lines::Option.new('c', 'd') }

    before(:each) do
      @section.lines << opt_one
      @section.lines << opt_two
    end

    it 'removes the option given a key' do
      expect { @section.delete('a') }.
        to change { @section['a'] }.to(nil)
    end

    it 'removes the option given an Option' do
      expect { @section.delete(opt_one) }.
        to change { @section['a'] }.to(nil)
    end

    it 'should not remove non-matching lines' do
      expect { @section.delete('a') }.not_to change { @section['c'] }
    end

    it 'returns the section' do
      expect(@section.delete('a')).to eql(@section)
    end
  end

  describe '#to_ini' do
    it 'should include the section key' do
      expect(IniParse::Lines::Section.new('a section').to_ini).to eq('[a section]')
    end

    it 'should include lines belonging to the section' do
      @section.lines << IniParse::Lines::Option.new('a', 'val1')
      @section.lines << IniParse::Lines::Blank.new
      @section.lines << IniParse::Lines::Comment.new(
        :comment => 'my comment', :comment_sep => ';', :comment_offset => 0
      )
      @section.lines << IniParse::Lines::Option.new('b', 'val2')

      expect(@section.to_ini).to eq(
        "[a section]\n" \
        "a = val1\n" \
        "\n" \
        "; my comment\n" \
        "b = val2"
      )
    end

    it 'should include duplicate lines' do
      @section.lines << IniParse::Lines::Option.new('a', 'val1')
      @section.lines << IniParse::Lines::Option.new('a', 'val2')

      expect(@section.to_ini).to eq(
        "[a section]\n" \
        "a = val1\n" \
        "a = val2"
      )
    end
  end

  describe '#has_option?' do
    before do
      @section['first'] = 'value'
    end

    it 'should return true if an option with the given key exists' do
      expect(@section).to have_option('first')
    end

    it 'should return true if no option with the given key exists' do
      expect(@section).not_to have_option('second')
    end
  end
end

#
# Option
#

describe 'Iniparse::Lines::Option' do
  describe '#initialize' do
    it 'should typecast the given key to a string' do
      expect(IniParse::Lines::Option.new(:symbol, '').key).to eq('symbol')
    end
  end

  describe '#to_ini' do
    it 'should include the key and value' do
      expect(IniParse::Lines::Option.new('key', 'value').to_ini).to eq('key = value')
    end
  end

  describe '.parse' do
    def parse(line, opts = {})
      IniParse::Lines::Option.parse(line, opts)
    end

    it 'should typecast empty values to nil' do
      expect(parse('key =')).to be_option_tuple('key', nil)
      expect(parse('key = ')).to be_option_tuple('key', nil)
      expect(parse('key =    ')).to be_option_tuple('key', nil)
    end

    it 'should not typecast "true" if true is part of a word' do
      expect(parse('key = TestTrueTest')).to be_option_tuple('key', 'TestTrueTest')
      expect(parse('key = TrueTest')).to be_option_tuple('key', 'TrueTest')
      expect(parse('key = TestTrue')).to be_option_tuple('key', 'TestTrue')
    end

    it 'should not typecast "false" if false is part of a word' do
      expect(parse('key = TestFalseTest')).to be_option_tuple('key', 'TestFalseTest')
      expect(parse('key = FalseTest')).to be_option_tuple('key', 'FalseTest')
      expect(parse('key = TestFalse')).to be_option_tuple('key', 'TestFalse')
    end

    it 'should typecast "true" to TrueClass' do
      expect(parse('key = true')).to be_option_tuple('key', true)
      expect(parse('key = TRUE')).to be_option_tuple('key', true)
    end

    it 'should typecast "false" to FalseClass' do
      expect(parse('key = false')).to be_option_tuple('key', false)
      expect(parse('key = FALSE')).to be_option_tuple('key', false)
    end

    it 'should typecast integer values to Integer' do
      expect(parse('key = 1')).to be_option_tuple('key', 1)
      expect(parse('key = 10')).to be_option_tuple('key', 10)
    end

    it 'should not typecast integers with a leading 0 to Integer' do
      expect(parse('key = 0700')).to be_option_tuple('key', '0700')
    end

    it 'should typecast negative integer values to Integer' do
      expect(parse('key = -1')).to be_option_tuple('key', -1)
    end

    it 'should typecast float values to Float' do
      expect(parse('key = 3.14159265')).to be_option_tuple('key', 3.14159265)
    end

    it 'should typecast negative float values to Float' do
      expect(parse('key = -3.14159265')).to be_option_tuple('key', -3.14159265)
    end

    it 'should typecast scientific notation numbers to Float' do
      expect(parse('key = 10e5')).to be_option_tuple('key', 10e5)
      expect(parse('key = 10e+5')).to be_option_tuple('key', 10e5)
      expect(parse('key = 10e-5')).to be_option_tuple('key', 10e-5)

      expect(parse('key = -10e5')).to be_option_tuple('key', -10e5)
      expect(parse('key = -10e+5')).to be_option_tuple('key', -10e5)
      expect(parse('key = -10e-5')).to be_option_tuple('key', -10e-5)

      expect(parse('key = 3.14159265e5')).to be_option_tuple('key', 3.14159265e5)
      expect(parse('key = 3.14159265e+5')).to be_option_tuple('key', 3.14159265e5)
      expect(parse('key = 3.14159265e-5')).to be_option_tuple('key', 3.14159265e-5)

      expect(parse('key = -3.14159265e5')).to be_option_tuple('key', -3.14159265e5)
      expect(parse('key = -3.14159265e+5')).to be_option_tuple('key', -3.14159265e5)
      expect(parse('key = -3.14159265e-5')).to be_option_tuple('key', -3.14159265e-5)
    end
  end
end

#
# Blank
#

#
# Comment
#

describe 'IniParse::Lines::Comment' do
  describe '#has_comment?' do
    it 'should return true if :comment has a non-blank value' do
      expect(IniParse::Lines::Comment.new(:comment => 'comment')).to have_comment
    end

    it 'should return true if :comment has a blank value' do
      expect(IniParse::Lines::Comment.new(:comment => '')).to have_comment
    end

    it 'should return true if :comment has a nil value' do
      expect(IniParse::Lines::Comment.new).to have_comment
      expect(IniParse::Lines::Comment.new(:comment => nil)).to have_comment
    end
  end

  describe '#to_ini' do
    it 'should return the comment' do
      expect(IniParse::Lines::Comment.new(
        :comment => 'a comment'
      ).to_ini).to eq('; a comment')
    end

    it 'should preserve comment offset' do
      expect(IniParse::Lines::Comment.new(
        :comment => 'a comment', :comment_offset => 10
      ).to_ini).to eq('          ; a comment')
    end

    it 'should return just the comment_sep if the comment is blank' do
      expect(IniParse::Lines::Comment.new.to_ini).to eq(';')
    end
  end
end
