require File.dirname(__FILE__) + '/../spec_helper'

# Tests use of the Generator when used like so:
#
#   IniParse::Generator.gen do |doc|
#     doc.comment('My very own comment')
#     doc.section('my_section') do |section|
#       section.option('my_option', 'my value')
#     end
#   end
#

describe 'When generating a document using Generator with section blocks,' do

  it 'should be able to compile an empty document' do
    lambda { IniParse::Generator.gen { |doc| } }.should_not raise_error
  end

  it 'should raise LocalJumpError if no block is given' do
    lambda { IniParse::Generator.gen }.should raise_error(LocalJumpError)
  end

  it "should yield an object with generator methods" do
    IniParse::Generator.gen do |doc|
      %w( section option comment blank ).each do |meth|
        doc.should respond_to(meth)
      end
    end
  end

  # --
  # ==========================================================================
  #   SECTION LINES
  # ==========================================================================
  # ++

  describe 'adding a section' do
    it 'should yield an object with generator methods' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") do |section|
          %w( option comment blank ).each do |meth|
            section.should respond_to(meth)
          end
        end
      end
    end

    it 'should add a Section to the document' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") { |section| }
      end.should have_section("a section")
    end

    it 'should change the Generator context to the section during the section block' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") do |section|
          section.context.should be_kind_of(IniParse::Lines::Section)
          section.context.key.should == "a section"
        end
      end
    end

    it 'should reset the Generator context to the document after the section block' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") { |section| }
        doc.context.should be_kind_of(IniParse::Document)
      end
    end

    it 'should pass extra options to the Section instance' do
      document = IniParse::Generator.gen do |doc|
        doc.section("a section", :indent => '    ') { |section| }
        doc.context.should be_kind_of(IniParse::Document)
      end

      document["a section"].opts[:indent].should == '    '
    end

    it 'should append a blank line to the document, after the section' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") { |section| }
      end.lines.to_a.last.should be_kind_of(IniParse::Lines::Blank)
    end

    it 'should raise a LineNotAllowed if you attempt to nest a section' do
      lambda do
        IniParse::Generator.gen do |doc|
          doc.section("a section") do |section_one|
            section_one.section("another_section") { |section_two| }
          end
        end
      end.should raise_error(IniParse::LineNotAllowed)
    end
  end

  # --
  # ==========================================================================
  #   OPTION LINES
  # ==========================================================================
  # ++

  describe 'adding a option' do

    describe 'when the context is a Document' do
      it "should raise a NoSectionError" do
        lambda do
          IniParse::Generator.gen do |doc|
            doc.option("my option", "a value")
          end
        end.should raise_error(IniParse::NoSectionError)
      end
    end

    describe 'when the context is a Section' do
      it 'should add the option to the section' do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section") do |section|
            section.option("my option", "a value")
          end
        end

        section = document["a section"]
        section.should have_option("my option")
        section["my option"].should == "a value"
      end

      it 'should pass extra options to the Option instance' do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section") do |section|
            section.option("my option", "a value", :indent => "    ")
          end
        end

        document["a section"].option("my option").opts[:indent].should == "    "
      end

      it "should use the parent section's options as a base" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :indent => "    ") do |section|
            section.option("my option", "a value", :comment_sep => "#")
          end
        end

        opts = document["a section"].option("my option").opts
        opts[:indent].should == "    "
        opts[:comment_sep].should == "#"
      end

      it "should not use the parent section's comment when setting line options" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment => "My section") do |section|
            section.option("my option", "a value", :comment_sep => "#")
          end
        end

        document["a section"].option("my option").opts[:comment].should be_nil
      end
    end
  end

  # --
  # ==========================================================================
  #   COMMENT LINES
  # ==========================================================================
  # ++

  describe 'adding a comment' do
    it 'should pass extra options to the Option instance' do
      document = IniParse::Generator.gen do |doc|
        doc.comment("My comment", :indent => '    ')
      end

      document.lines.to_a.first.opts[:indent].should == '    '
    end

    it 'should ignore any extra :comment option' do
      document = IniParse::Generator.gen do |doc|
        doc.comment("My comment", :comment => 'Ignored')
      end

      document.lines.to_a.first.opts[:comment].should == 'My comment'
    end

    describe 'when the context is a Document' do
      it 'should add a comment to the document' do
        document = IniParse::Generator.gen do |doc|
          doc.comment("My comment")
        end

        comment = document.lines.to_a.first
        comment.should be_kind_of(IniParse::Lines::Comment)
        comment.opts[:comment].should == 'My comment'
      end

      it 'should use the default line options as a base' do
        document = IniParse::Generator.gen do |doc|
          doc.comment("My comment")
        end

        opts = document.lines.to_a.first.opts

        opts[:indent].should \
          == IniParse::Lines.default_opts[:indent]
        opts[:comment_sep].should \
          == IniParse::Lines.default_opts[:comment_sep]
        opts[:comment_indent].should \
          == IniParse::Lines.default_opts[:comment_indent]
      end
    end

    describe 'when the context is a Section' do
      it 'should add a comment to the section' do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section") do |section|
            section.comment("My comment")
          end
        end

        comment = document['a section'].lines.to_a.first
        comment.should be_kind_of(IniParse::Lines::Comment)
        comment.opts[:comment].should == 'My comment'
      end

      it "should use the parent section's line options as a base" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment_offset => 5) do |section|
            section.comment("My comment", :comment_sep => "#")
          end
        end

        opts = document['a section'].lines.to_a.first.opts
        opts[:comment_offset].should == 5
        opts[:comment_sep].should == '#'
      end

      it "should not use the parent section's comment when setting line options" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment => "My section") do |section|
            section.comment("My comment")
          end
        end

        document['a section'].lines.to_a.first.opts[:comment].should == 'My comment'
      end
    end
  end

  # --
  # ==========================================================================
  #   BLANK LINES
  # ==========================================================================
  # ++

  describe 'adding a blank line' do
    it 'should add a blank line to the document when it is the context' do
      document = IniParse::Generator.gen do |doc|
        doc.blank
      end

      document.lines.to_a.first.should be_kind_of(IniParse::Lines::Blank)
    end

    it 'should add a blank line to the section when it is the context' do
      document = IniParse::Generator.gen do |doc|
        doc.section("a section") do |section|
          section.blank
        end
      end

      document['a section'].lines.to_a.first.should be_kind_of(IniParse::Lines::Blank)
    end
  end

end