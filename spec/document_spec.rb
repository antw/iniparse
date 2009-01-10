require File.dirname(__FILE__) + '/spec_helper'

describe "IniParse::Document" do
  it 'should have a +sections+ reader' do
    IniParse::Document.instance_methods.should include('lines')
  end

  it 'should not have a +sections+ writer' do
    IniParse::Document.instance_methods.should_not include('lines=')
  end

  it 'should delegate #[] to +lines+' do
    doc = IniParse::Document.new
    doc.lines.should_receive(:[]).with('key')
    doc['key']
  end

  it 'should call #each to +lines+' do
    doc = IniParse::Document.new
    doc.lines.should_receive(:each)
    doc.each { |l| }
  end

  describe '#save' do
    describe 'when no path is given to save' do
      it 'should save the INI document if a path was given when initialized' do
        doc = IniParse::Document.new('/a/path/to/a/file.ini')
        File.should_receive(:open).with('/a/path/to/a/file.ini', 'w')
        doc.save
      end

      it 'should raise IniParseError if no path was given when initialized' do
        lambda { IniParse::Document.new.save }.should \
          raise_error(IniParse::IniParseError)
      end
    end

    describe 'when a path is given to save' do
      it "should update the document's +path+" do
        File.stub!(:open).and_return(true)
        doc = IniParse::Document.new('/a/path/to/a/file.ini')
        doc.save('/a/new/path.ini')
        doc.path.should == '/a/new/path.ini'
      end

      it 'should save the INI document to the given path' do
        File.should_receive(:open).with('/a/new/path.ini', 'w')
        IniParse::Document.new('/a/path/to/a/file.ini').save('/a/new/path.ini')
      end

      it 'should raise IniParseError if no path was given when initialized' do
        lambda { IniParse::Document.new.save }.should \
          raise_error(IniParse::IniParseError)
      end
    end
  end
end
