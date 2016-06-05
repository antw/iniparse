require 'spec_helper'

# ----------------------------------------------------------------------------
# Shared specs for all Collection types...
# ----------------------------------------------------------------------------

shared_examples_for "LineCollection" do
  before(:each) do
    @collection << (@c1 = IniParse::Lines::Comment.new)
    @collection <<  @i1
    @collection <<  @i2
    @collection << (@b1 = IniParse::Lines::Blank.new)
    @collection <<  @i3
    @collection << (@b2 = IniParse::Lines::Blank.new)
  end

  describe '#each' do
    it 'should remove blanks and comments by default' do
      @collection.each { |l| expect(l).to be_kind_of(@i1.class) }
    end

    it 'should not remove blanks and comments if true is given' do
      arr = []

      # map(true)->each(true) not possible with Enumerable
      @collection.each(true) do |line|
        arr << line
      end

      expect(arr).to eq([@c1, @i1, @i2, @b1, @i3, @b2])
    end
  end

  describe '#[]' do
    it 'should fetch the correct value' do
      expect(@collection['first']).to  eq(@i1)
      expect(@collection['second']).to eq(@i2)
      expect(@collection['third']).to  eq(@i3)
    end

    it 'should return nil if the given key does not exist' do
      expect(@collection['does not exist']).to be_nil
    end
  end

  describe '#[]=' do
    it 'should successfully add a new key' do
      @collection['fourth'] = @new
      expect(@collection['fourth']).to eq(@new)
    end

    it 'should successfully update an existing key' do
      @collection['second'] = @new
      expect(@collection['second']).to eq(@new)

      # Make sure the old data is gone.
      expect(@collection.detect { |s| s.key == 'second' }).to be_nil
    end

    it 'should typecast given keys to a string' do
      @collection[:a_symbol] = @new
      expect(@collection['a_symbol']).to eq(@new)
    end
  end

  describe '#<<' do
    it 'should set the key correctly if given a new item' do
      expect(@collection).not_to have_key(@new.key)
      @collection << @new
      expect(@collection).to have_key(@new.key)
    end

    it 'should append Blank lines' do
      @collection << IniParse::Lines::Blank.new
      expect(@collection.instance_variable_get(:@lines).last).to \
        be_kind_of(IniParse::Lines::Blank)
    end

    it 'should append Comment lines' do
      @collection << IniParse::Lines::Comment.new
      expect(@collection.instance_variable_get(:@lines).last).to \
        be_kind_of(IniParse::Lines::Comment)
    end

    it 'should return self' do
      expect(@collection << @new).to eq(@collection)
    end
  end

  describe '#delete' do
    it 'should remove the given value and adjust the indicies' do
      expect(@collection['second']).not_to be_nil
      @collection.delete('second')
      expect(@collection['second']).to be_nil
      expect(@collection['first']).to eq(@i1)
      expect(@collection['third']).to eq(@i3)
    end

    it "should do nothing if the supplied key does not exist" do
      @collection.delete('does not exist')
      expect(@collection['first']).to eq(@i1)
      expect(@collection['third']).to eq(@i3)
    end
  end

  describe '#to_a' do
    it 'should return an array' do
      expect(@collection.to_a).to be_kind_of(Array)
    end

    it 'should include all lines' do
      expect(@collection.to_a).to eq([@c1, @i1, @i2, @b1, @i3, @b2])
    end

    it 'should include references to the same line objects as the collection' do
      @collection << @new
      expect(@collection.to_a.last.object_id).to eq(@new.object_id)
    end
  end

  describe '#to_hash' do
    it 'should return a hash' do
      expect(@collection.to_hash).to be_kind_of(Hash)
    end

    it 'should have the correct keys' do
      hash = @collection.to_hash
      expect(hash.keys.length).to eq(3)
      expect(hash).to have_key('first')
      expect(hash).to have_key('second')
      expect(hash).to have_key('third')
    end

    it 'should have the correct values' do
      hash = @collection.to_hash
      expect(hash['first']).to  eq(@i1)
      expect(hash['second']).to eq(@i2)
      expect(hash['third']).to  eq(@i3)
    end
  end

  describe '#keys' do
    it 'should return an array of strings' do
      expect(@collection.keys).to eq(['first', 'second', 'third'])
    end
  end
end

# ----------------------------------------------------------------------------
# On with the collection specs...
# ----------------------------------------------------------------------------

describe 'IniParse::OptionCollection' do
  before(:each) do
    @collection = IniParse::OptionCollection.new
    @i1  = IniParse::Lines::Option.new('first',  'v1')
    @i2  = IniParse::Lines::Option.new('second', 'v2')
    @i3  = IniParse::Lines::Option.new('third',  'v3')
    @new = IniParse::Lines::Option.new('fourth', 'v4')
  end

  it_should_behave_like 'LineCollection'

  describe '#<<' do
    it 'should raise a LineNotAllowed exception if a Section is pushed' do
      expect { @collection << IniParse::Lines::Section.new('s') }.to \
        raise_error(IniParse::LineNotAllowed)
    end

    it 'should add the Option as a duplicate if an option with the same key exists' do
      option_one = IniParse::Lines::Option.new('k', 'value one')
      option_two = IniParse::Lines::Option.new('k', 'value two')

      @collection << option_one
      @collection << option_two

      expect(@collection['k']).to eq([option_one, option_two])
    end
  end

  describe '#keys' do
    it 'should handle duplicates' do
      @collection << @i1 << @i2 << @i3
      @collection << IniParse::Lines::Option.new('first', 'v5')
      expect(@collection.keys).to eq(['first', 'second', 'third'])
    end
  end
end

describe 'IniParse::SectionCollection' do
  before(:each) do
    @collection = IniParse::SectionCollection.new
    @i1  = IniParse::Lines::Section.new('first')
    @i2  = IniParse::Lines::Section.new('second')
    @i3  = IniParse::Lines::Section.new('third')
    @new = IniParse::Lines::Section.new('fourth')
  end

  it_should_behave_like 'LineCollection'

  describe '#<<' do
    it 'should add merge Section with the other, if it is a duplicate' do
      new_section = IniParse::Lines::Section.new('first')
      @collection << @i1
      expect(@i1).to receive(:merge!).with(new_section).once
      @collection << new_section
    end
  end
end
