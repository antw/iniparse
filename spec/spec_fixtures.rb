module IniParse
  module Test
    class Fixtures
      @@fixtures = {}

      def self.[](fix)
        @@fixtures[fix]
      end

      def self.[]=(fix, val)
        @@fixtures[fix] = val.margin
      end
    end
  end
end

IniParse::Test::Fixtures[:comment_before_section] = <<-FIX
  ; This is a comment
  [first_section]
  key = value
FIX

IniParse::Test::Fixtures[:blank_before_section] = <<-FIX

  [first_section]
  key = value
FIX

IniParse::Test::Fixtures[:option_before_section] = <<-FIX
  key = value
  [first_section]
FIX

IniParse::Test::Fixtures[:invalid_line] = <<-FIX
  this line is not valid
FIX
