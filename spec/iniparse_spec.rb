require File.dirname(__FILE__) + '/spec_helper'


describe "IniParse" do
  describe '.open' do
    before(:each) { File.stub!(:read).and_return('[section]') }

    it 'should return an IniParse::Document' do
      IniParse.open('/my/path.ini').should be_kind_of(IniParse::Document)
    end

    it 'should set the path on the returned Document' do
      IniParse.open('/my/path.ini').path.should == '/my/path.ini'
    end

    it 'should read the file at the given path' do
      File.should_receive(:read).with('/my/path.ini').and_return('[section]')
      IniParse.open('/my/path.ini')
    end
  end
end
