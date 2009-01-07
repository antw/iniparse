require File.dirname(__FILE__) + '/spec_helper'

describe "IniParse::LineCollection" do

  before(:each) do
    @collection = IniParse::LineCollection.new
    @collection << (@c1 = IniParse::LineTypes::Comment.new)
    @collection << (@s1 = IniParse::LineTypes::Section.new('first section'))
    @collection << (@s2 = IniParse::LineTypes::Section.new('second section'))
    @collection << (@b1 = IniParse::LineTypes::Blank.new)
    @collection << (@s3 = IniParse::LineTypes::Section.new('third section'))
    @collection << (@b2 = IniParse::LineTypes::Blank.new)
  end

  describe '#each' do
    it 'should remove blanks and comments by default' do
      @collection.each { |l| l.should be_kind_of(IniParse::LineTypes::Section) }
    end

    it 'should not remove blanks and comments if true is given' do
      arr = []

      # map(true)->each(true) not possible with Enumerable
      @collection.each(true) do |line|
        arr << line
      end

      arr.should == [@c1, @s1, @s2, @b1, @s3, @b2]
    end
  end

  describe '#[]' do
    it 'should fetch the correct value' do
      @collection['first section'].should  == @s1
      @collection['second section'].should == @s2
      @collection['third section'].should  == @s3
    end

    it 'should return nil if the given key does not exist' do
      @collection['does not exist'].should be_nil
    end
  end

  describe '#[]=' do
    it 'should successfully add a new key' do
      s4 = IniParse::LineTypes::Section.new('fourth section')
      @collection['fourth section'] = s4
      @collection['fourth section'].should == s4
    end

    it 'should successfully update an existing key' do
      s4 = IniParse::LineTypes::Section.new('fourth section')
      @collection['second section'] = s4
      @collection['second section'].should == s4

      # Make sure the old data is gone.
      @collection.detect { |s| s.name == 'second section' }.should be_nil
    end

    it 'should typecast given keys to a string' do
      s4 = IniParse::LineTypes::Section.new('fourth section')
      @collection[:a_symbol] = s4
      @collection['a_symbol'].should == s4
    end
  end

  describe '#<<' do
    it 'should set the key correctly if given a Section' do
      @collection.should_not have_key('new section')
      @collection << IniParse::LineTypes::Section.new('new section')
      @collection.should have_key('new section')
    end

    it 'should set the key correctly if given an Option' do
      @collection.should_not have_key('new option')
      @collection << IniParse::LineTypes::Option.new('new option', 'v')
      @collection.should have_key('new option')
    end
  end

  describe '#delete' do
    it 'should remove the given value and adjust the indicies' do
      @collection.delete('second section')
      @collection['first section'].should == @s1
      @collection['third section'].should == @s3
    end

    it "should do nothing if the supplied key does not exist" do
      @collection.delete('does not exist')
      @collection['first section'].should == @s1
      @collection['third section'].should == @s3
    end
  end
end