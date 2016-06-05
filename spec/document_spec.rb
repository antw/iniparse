require 'spec_helper'

describe "IniParse::Document" do
  it 'should have a +lines+ reader' do
    methods = IniParse::Document.instance_methods.map { |m| m.to_sym }
    expect(methods).to include(:lines)
  end

  it 'should not have a +lines+ writer' do
    methods = IniParse::Document.instance_methods.map { |m| m.to_sym }
    expect(methods).not_to include(:lines=)
  end

  it 'should delegate #[] to +lines+' do
    doc = IniParse::Document.new
    expect(doc.lines).to receive(:[]).with('key')
    doc['key']
  end

  it 'should call #each to +lines+' do
    doc = IniParse::Document.new
    expect(doc.lines).to receive(:each)
    doc.each { |l| }
  end

  it 'should be enumerable' do
    expect(IniParse::Document.included_modules).to include(Enumerable)

    sections = [
      IniParse::Lines::Section.new('first section'),
      IniParse::Lines::Section.new('second section')
    ]

    doc = IniParse::Document.new
    doc.lines << sections[0] << sections[1]

    expect(doc.map { |line| line }).to eq(sections)
  end

  describe '#has_section?' do
    before(:all) do
      @doc = IniParse::Document.new
      @doc.lines << IniParse::Lines::Section.new('first section')
      @doc.section('another section')
    end

    it 'should return true if a section with the given key exists' do
      expect(@doc).to have_section('first section')
      expect(@doc).to have_section('another section')
    end

    it 'should return true if no section with the given key exists' do
      expect(@doc).not_to have_section('second section')
    end
  end

  describe '#delete' do
    let(:document) do
      IniParse::Generator.gen do |doc|
        doc.section('first') do |section|
          section.alpha   = 'bravo'
          section.charlie = 'delta'
        end

        doc.section('second') do |section|
          section.echo = 'foxtrot'
          section.golf = 'hotel'
        end
      end
    end

    it 'removes the section given a key' do
      expect { document.delete('first') }.
        to change { document['first'] }.to(nil)
    end

    it 'removes the section given a Section' do
      expect { document.delete(document['first']) }.
        to change { document['first'] }.to(nil)
    end

    it 'removes the lines' do
      expect { document.delete('first') }.
        to change { document.to_ini.match(/alpha/) }.to(nil)
    end

    it 'returns the document' do
      expect(document.delete('first')).to eql(document)
    end
  end

  describe '#to_ini' do
    let(:document) do
      IniParse.parse(<<-EOF.gsub(/^\s+/, ''))
        [one]
        alpha = bravo
        [two]
        chalie = delta
      EOF
    end

    context 'when the document has a trailing Blank line' do
      it 'outputs the newline to the output string' do
        expect(document.to_ini).to match(/\n\Z/)
      end

      it 'does not add a second newline to the output string' do
        expect(document.to_ini).to_not match(/\n\n\Z/)
      end
    end # when the document has a trailing Blank line

    context 'when the document has no trailing Blank line' do
      before { document.delete('two') }

      it 'adds a newline to the output string' do
        expect(document.to_ini).to match(/\n\Z/)
      end
    end # when the document has no trailing Blank line
  end # to_ini

  describe '#save' do
    describe 'when no path is given to save' do
      it 'should save the INI document if a path was given when initialized' do
        doc = IniParse::Document.new('/a/path/to/a/file.ini')
        expect(File).to receive(:open).with('/a/path/to/a/file.ini', 'w')
        doc.save
      end

      it 'should raise IniParseError if no path was given when initialized' do
        expect { IniParse::Document.new.save }.to \
          raise_error(IniParse::IniParseError)
      end
    end

    describe 'when a path is given to save' do
      it "should update the document's +path+" do
        allow(File).to receive(:open).and_return(true)
        doc = IniParse::Document.new('/a/path/to/a/file.ini')
        doc.save('/a/new/path.ini')
        expect(doc.path).to eq('/a/new/path.ini')
      end

      it 'should save the INI document to the given path' do
        expect(File).to receive(:open).with('/a/new/path.ini', 'w')
        IniParse::Document.new('/a/path/to/a/file.ini').save('/a/new/path.ini')
      end

      it 'should raise IniParseError if no path was given when initialized' do
        expect { IniParse::Document.new.save }.to \
          raise_error(IniParse::IniParseError)
      end
    end
  end
end
