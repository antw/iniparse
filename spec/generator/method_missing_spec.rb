require 'spec_helper'

# Tests use of the Generator when used like so:
#
#   IniParse::Generator.gen do |doc|
#     doc.comment 'My very own comment'
#     doc.my_section do |section|
#       section.my_option = 'my value'
#     end
#   end
#

describe 'When generating a document using Generator with section blocks using method_missing,' do

  # --
  # ==========================================================================
  #   SECTION LINES
  # ==========================================================================
  # ++

  describe 'adding a section' do
    it 'should yield an object with generator methods' do
      IniParse::Generator.gen do |doc|
        doc.a_section do |section|
          %w( option comment blank ).each do |meth|
            expect(section).to respond_to(meth)
          end
        end
      end
    end

    it 'should add a Section to the document' do
      expect(IniParse::Generator.gen do |doc|
        doc.a_section { |section| }
      end).to have_section("a_section")
    end

    it 'should change the Generator context to the section during the section block' do
      IniParse::Generator.gen do |doc|
        doc.a_section do |section|
          expect(section.context).to be_kind_of(IniParse::Lines::Section)
          expect(section.context.key).to eq("a_section")
        end
      end
    end

    it 'should reset the Generator context to the document after the section block' do
      IniParse::Generator.gen do |doc|
        doc.a_section { |section| }
        expect(doc.context).to be_kind_of(IniParse::Document)
      end
    end

    it 'should append a blank line to the document, after the section' do
      expect(IniParse::Generator.gen do |doc|
        doc.a_section { |section| }
      end.lines.to_a.last).to be_kind_of(IniParse::Lines::Blank)
    end

    it 'should raise a LineNotAllowed if you attempt to nest a section' do
      expect do
        IniParse::Generator.gen do |doc|
          doc.a_section do |section_one|
            section_one.another_section { |section_two| }
          end
        end
      end.to raise_error(IniParse::LineNotAllowed)
    end
  end

  # --
  # ==========================================================================
  #   OPTION LINES
  # ==========================================================================
  # ++

  describe 'adding a option' do
    describe 'when the context is a Document' do
      it "adds the option to an __anonymous__ section" do
        doc = IniParse::Generator.gen { |doc| doc.my_option = "a value" }
        expect(doc['__anonymous__']['my_option']).to eql('a value')
      end
    end

    describe 'when the context is a Section' do
      it 'should add the option to the section' do
        document = IniParse::Generator.gen do |doc|
          doc.a_section do |section|
            section.my_option = "a value"
          end
        end

        section = document["a_section"]
        expect(section).to have_option("my_option")
        expect(section["my_option"]).to eq("a value")
      end
    end
  end

  # Comments and blanks are added in the same way as in the
  # 'with_section_block_spec.rb' specification.

end
