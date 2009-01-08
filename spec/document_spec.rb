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
end
