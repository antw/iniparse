$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'iniparse'
require File.join(File.dirname(__FILE__), 'spec_fixtures')

module IniParse
  module Test
    module Helpers
      # Taken from Merb Core's spec helper.
      # Merb is licenced using the MIT License and is copyright
      # Engine Yard Inc.
      class BeKindOf
        def initialize(expected) # + args
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.kind_of?(@expected)
        end

        def failure_message
          "expected #{@expected} but got #{@target.class}"
        end

        def negative_failure_message
          "expected #{@expected} to not be #{@target.class}"
        end

        def description
          "be_kind_of #{@target}"
        end
      end

      # Asserts that a Tuple returned by Line#parse is a valid tuple for
      # creating a Section.
      class BeSectionTuple
        def initialize(key) # + args
          @key = key
        end

        def matches?(target)
          @target = target

          if @target.nil? || (! @target.kind_of?(Array))
            @nil_value = true
            false
          elsif @target[0] != :section
            @wrong_type = true
            false
          elsif @target[1] != @key
            @wrong_key = true
            false
          else
            true
          end
        end

        def failure_message
          if @nil_value
            "expected section tuple but got #{@target.class}"
          elsif @wrong_type
            "expected section tuple but was :#{@target[0]}"
          elsif @wrong_key
            "expected section tuple with key `#{@key}` but was `#{@target[1]}`"
          end
        end

        def negative_failure_message
          "expected #{@expected} to not be section tuple"
        end

        def description
          "be_section_tuple #{@target}"
        end
      end

      # Asserts that a Tuple returned by Line#parse is a valid tuple for
      # creating an Option.
      class BeOptionTuple
        def initialize(key, value) # + args
          @key   = key
          @value = value
        end

        def matches?(target)
          @target = target

          if @target.nil? || (! @target.kind_of?(Array))
            @nil_value = true
            false
          elsif @target[0] != :option
            @wrong_type = true
            false
          elsif @target[1] != @key
            @wrong_key = true
            false
          elsif @target[2] != @value
            @wrong_value = true
            false
          else
            true
          end
        end

        def failure_message
          if @nil_value
            "expected option tuple but got #{@target.class}"
          elsif @wrong_type
            "expected option tuple but was :#{@target[0]}"
          elsif @wrong_key
            "expected option tuple with key `#{@key}` but was `#{@target[1]}`"
          elsif @wrong_value
            "expected option tuple with value `#{@value}` but was `#{@target[2]}`"
          end
        end

        def negative_failure_message
          "expected #{@expected} to not be option tuple"
        end

        def description
          "be_option_tuple #{@target}"
        end
      end

      # Asserts that a Tuple returned by Line#parse is a valid tuple for
      # creating a Blank.
      class BeBlankTuple
        def matches?(target)
          @target = target

          if @target.nil? || (! @target.kind_of?(Array))
            @nil_value = true
            false
          elsif @target[0] != :blank
            @wrong_type = true
            false
          else
            true
          end
        end

        def failure_message
          if @nil_value
            "expected blank tuple but got #{@target.class}"
          elsif @wrong_type
            "expected blank tuple but was :#{@target[0]}"
          end
        end

        def negative_failure_message
          "expected #{@expected} to not be blank tuple"
        end

        def description
          "be_blank_tuple #{@target}"
        end
      end

      # Asserts that a Tuple returned by Line#parse is a valid tuple for
      # creating a Comment.
      class BeCommentTuple
        def matches?(target)
          @target = target

          if @target.nil? || (! @target.kind_of?(Array))
            @nil_value = true
            false
          elsif @target[0] != :comment
            @wrong_type = true
            false
          else
            true
          end
        end

        def failure_message
          if @nil_value
            "expected comment tuple but got #{@target.class}"
          elsif @wrong_type
            "expected comment tuple but was :#{@target[0]}"
          end
        end

        def negative_failure_message
          "expected #{@expected} to not be comment tuple"
        end

        def description
          "be_comment_tuple #{@target}"
        end
      end

      def be_kind_of(expected) # + args
        BeKindOf.new(expected)
      end

      def be_section_tuple(key = nil)
        BeSectionTuple.new(key)
      end

      def be_option_tuple(key = nil, value = nil)
        BeOptionTuple.new(key, value)
      end

      def be_blank_tuple
        BeBlankTuple.new
      end

      def be_comment_tuple
        BeCommentTuple.new
      end

      def fixture(fix)
        IniParse::Test::Fixtures[fix]
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.include(IniParse::Test::Helpers)
end
