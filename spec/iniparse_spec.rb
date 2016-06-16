require 'spec_helper'


describe "IniParse" do
  describe '.parse' do
    context 'with a line ending in a backslash' do
      let(:ini) do
        <<-'INI'.gsub(/^\s*/, '')
          [a]
          opt = 1 \
          other = 2
        INI
      end

      let(:doc) { IniParse.parse(ini) }

      it 'recognises the line continuation' do
        expect(doc.to_s).to eq("[a]\nopt = 1 other = 2\n")
      end

      it 'has one option' do
        expect(doc['a'].to_a.length).to eq(1)
      end
    end

    context 'with a line ending in a double-backslash' do
      let(:ini) do
        <<-'INI'.gsub(/^\s*/, '')
          [a]
          opt = 1 \\
          other = 2
        INI
      end

      let(:doc) { IniParse.parse(ini) }

      it 'does not see a line continuation' do
        expect(doc.to_s).to eq(ini)
      end

      it 'has one option' do
        expect(doc['a'].to_a.length).to eq(2)
      end
    end
  end

  describe '.open' do
    before(:each) { allow(File).to receive(:read).and_return('[section]') }

    it 'should return an IniParse::Document' do
      expect(IniParse.open('/my/path.ini')).to be_kind_of(IniParse::Document)
    end

    it 'should set the path on the returned Document' do
      expect(IniParse.open('/my/path.ini').path).to eq('/my/path.ini')
    end

    it 'should read the file at the given path' do
      expect(File).to receive(:read).with('/my/path.ini').and_return('[section]')
      IniParse.open('/my/path.ini')
    end
  end
end
