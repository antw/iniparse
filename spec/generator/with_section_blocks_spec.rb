require 'spec_helper'

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
    expect { IniParse::Generator.gen { |doc| } }.not_to raise_error
  end

  it 'should raise LocalJumpError if no block is given' do
    expect { IniParse::Generator.gen }.to raise_error(LocalJumpError)
  end

  it "should yield an object with generator methods" do
    IniParse::Generator.gen do |doc|
      %w( section option comment blank ).each do |meth|
        expect(doc).to respond_to(meth)
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
            expect(section).to respond_to(meth)
          end
        end
      end
    end

    it 'should add a Section to the document' do
      expect(IniParse::Generator.gen do |doc|
        doc.section("a section") { |section| }
      end).to have_section("a section")
    end

    it 'should change the Generator context to the section during the section block' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") do |section|
          expect(section.context).to be_kind_of(IniParse::Lines::Section)
          expect(section.context.key).to eq("a section")
        end
      end
    end

    it 'should reset the Generator context to the document after the section block' do
      IniParse::Generator.gen do |doc|
        doc.section("a section") { |section| }
        expect(doc.context).to be_kind_of(IniParse::Document)
      end
    end

    it "should use the parent document's options as a base" do
      document = IniParse::Generator.gen(:indent => '    ') do |doc|
        doc.section("a section") { |section| }
      end

      expect(document["a section"].to_ini).to match(/\A    /)
    end

    it 'should pass extra options to the Section instance' do
      document = IniParse::Generator.gen do |doc|
        doc.section("a section", :indent => '    ') { |section| }
      end

      expect(document["a section"].to_ini).to match(/\A    /)
    end

    it 'should append a blank line to the document, after the section' do
      expect(IniParse::Generator.gen do |doc|
        doc.section("a section") { |section| }
      end.lines.to_a.last).to be_kind_of(IniParse::Lines::Blank)
    end

    it 'should raise a LineNotAllowed if you attempt to nest a section' do
      expect do
        IniParse::Generator.gen do |doc|
          doc.section("a section") do |section_one|
            section_one.section("another_section") { |section_two| }
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
      it "should add the option to an __anonymous__ section" do
        document = IniParse::Generator.gen do |doc|
          doc.option("my option", "a value")
        end

        expect(document['__anonymous__']['my option']).to eql('a value')
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
        expect(section).to have_option("my option")
        expect(section["my option"]).to eq("a value")
      end

      it 'should pass extra options to the Option instance' do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section") do |section|
            section.option("my option", "a value", :indent => "    ")
          end
        end

        expect(document["a section"].option("my option").to_ini).to match(/^    /)
      end

      it "should use the parent document's options as a base" do
        document = IniParse::Generator.gen(:indent => "    ") do |doc|
          doc.section("a section") do |section|
            section.option("my option", "a value")
          end
        end

        expect(document["a section"].option("my option").to_ini).to match(/^    /)
      end

      it "should use the parent section's options as a base" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :indent => "    ") do |section|
            section.option("my option", "a value")
          end
        end

        expect(document["a section"].option("my option").to_ini).to match(/^    /)
      end

      it "should allow customisation of the parent's options" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :indent => "    ") do |section|
            section.option("my option", "a value", {
              :comment_sep => "#", :comment => 'a comment'
            })
          end
        end

        option_ini = document["a section"].option("my option").to_ini
        expect(option_ini).to match(/^    /)
        expect(option_ini).to match(/ # a comment/)
      end

      it "should not use the parent section's comment when setting line options" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment => "My section") do |section|
            section.option("my option", "a value")
          end
        end

        expect(document["a section"].option("my option").to_ini).not_to match(/My section$/)
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

      expect(document.lines.to_a.first.to_ini).to match(/\A    /)
    end

    it 'should ignore any extra :comment option' do
      document = IniParse::Generator.gen do |doc|
        doc.comment("My comment", :comment => 'Ignored')
      end

      expect(document.lines.to_a.first.to_ini).to match(/My comment/)
      expect(document.lines.to_a.first.to_ini).not_to match(/Ignored/)
    end

    describe 'when the context is a Document' do
      it 'should add a comment to the document' do
        document = IniParse::Generator.gen do |doc|
          doc.comment("My comment")
        end

        comment = document.lines.to_a.first
        expect(comment).to be_kind_of(IniParse::Lines::Comment)
        expect(comment.to_ini).to match(/My comment/)
      end

      it 'should use the default line options as a base' do
        document = IniParse::Generator.gen do |doc|
          doc.comment("My comment")
        end

        comment_ini = document.lines.to_a.first.to_ini

        # Match separator (;) and offset (0).
        expect(comment_ini).to eq('; My comment')
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
        expect(comment).to be_kind_of(IniParse::Lines::Comment)
        expect(comment.to_ini).to match(/My comment/)
      end

      it "should use the parent document's line options as a base" do
        document = IniParse::Generator.gen(:comment_offset => 5) do |doc|
          doc.section("a section") do |section|
            section.comment("My comment")
          end
        end

        expect(document['a section'].lines.to_a.first.to_ini).to match(/^     ;/)
      end

      it "should use the parent section's line options as a base" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment_offset => 5) do |section|
            section.comment("My comment")
          end
        end

        expect(document['a section'].lines.to_a.first.to_ini).to match(/^     ;/)
      end

      it "should allow customisation of the parent's options" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment_offset => 5) do |section|
            section.comment("My comment", :comment_sep => "#")
          end
        end

        # Match separator (#) and offset (5)
        expect(document['a section'].lines.to_a.first.to_ini).to \
          eq('     # My comment')
      end

      it "should not use the parent section's comment when setting line options" do
        document = IniParse::Generator.gen do |doc|
          doc.section("a section", :comment => "My section") do |section|
            section.comment("My comment")
          end
        end

        comment_ini = document['a section'].lines.to_a.first.to_ini
        expect(comment_ini).to match(/My comment/)
        expect(comment_ini).not_to match(/My section/)
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

      expect(document.lines.to_a.first).to be_kind_of(IniParse::Lines::Blank)
    end

    it 'should add a blank line to the section when it is the context' do
      document = IniParse::Generator.gen do |doc|
        doc.section("a section") do |section|
          section.blank
        end
      end

      expect(document['a section'].lines.to_a.first).to be_kind_of(IniParse::Lines::Blank)
    end
  end

end
